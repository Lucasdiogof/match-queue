// Etapa 17B-2 -- mede, contra um double local do PostgREST (nenhuma rede
// externa, nenhuma credencial real), quantas requests HTTP tool/sync_fc_cards
// emite por tamanho de lote (--batch-size). Usado para escolher o default
// de --batch-size com medicao real em vez de arbitrario -- ver
// docs/handoff_etapa17b2.md pelos numeros e pela decisao.
//
// Uso: dart run tool/perf/measure_batch_size.dart

import 'dart:convert';
import 'dart:io';

class FakePostgrest {
  final List<String> requestLog = <String>[];
  final Map<String, List<Map<String, dynamic>>> tables = {
    'fc_leagues': <Map<String, dynamic>>[],
    'fc_clubs': <Map<String, dynamic>>[],
    'fc_nations': <Map<String, dynamic>>[],
    'fc_players': <Map<String, dynamic>>[],
    'fc_player_cards': <Map<String, dynamic>>[],
  };
  var nextId = 1;

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_handle);
    return server;
  }

  void _handle(HttpRequest request) async {
    requestLog.add('${request.method} ${request.uri.path}');
    final table = request.uri.pathSegments.last;
    final body = await utf8.decoder.bind(request).join();

    if (request.method == 'GET' && table == 'fc_player_cards') {
      request.response
        ..statusCode = 200
        ..write(jsonEncode(const []));
      await request.response.close();
      return;
    }
    if (request.method == 'GET') {
      final nameParam = request.uri.queryParameters['name'];
      final name = nameParam?.replaceFirst('eq.', '') ?? '';
      final rows = tables[table] ?? [];
      final match = rows.where((r) => r['name'] == name).toList();
      request.response
        ..statusCode = 200
        ..write(jsonEncode(match.take(1).toList()));
      await request.response.close();
      return;
    }
    if (request.method == 'POST') {
      final decoded = jsonDecode(body);
      final rowsIn = decoded is List
          ? decoded.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[decoded as Map<String, dynamic>];
      final created = <Map<String, dynamic>>[];
      for (final row in rowsIn) {
        final withId = <String, dynamic>{'id': 'id-${nextId++}', ...row};
        (tables[table] ??= []).add(withId);
        created.add(withId);
      }
      final prefer = request.headers.value('prefer') ?? '';
      request.response.statusCode = 201;
      if (prefer.contains('return=representation')) {
        request.response.write(jsonEncode(created));
      }
      await request.response.close();
      return;
    }
    request.response.statusCode = 404;
    await request.response.close();
  }
}

List<Map<String, dynamic>> rows(int count) => [
  for (var i = 0; i < count; i++)
    {
      'provider_player_id': '${9000 + i}',
      'provider_card_id': '${9000 + i}:BASE',
      'player_name': 'Batch Player $i',
      'rating': '${60 + (i % 30)}',
      'primary_position': i % 12 == 0 ? 'GK' : 'CM',
      'club_name': 'Club ${i % 5}',
      'league_name': 'League ${i % 3}',
      'nation_name': 'Nation ${i % 4}',
    },
];

Future<void> main() async {
  final tempDir = Directory.systemTemp.createTempSync('measure_batch_');
  for (final n in [500, 2000, 5000]) {
    for (final batchSize in [1, 100, 500]) {
      final fake = FakePostgrest();
      final server = await fake.start();
      final file = File('${tempDir.path}/rows_${n}_$batchSize.json');
      file.writeAsStringSync(jsonEncode(rows(n)));
      final sw = Stopwatch()..start();
      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/sync_fc_cards.dart',
          '--file=${file.path}',
          '--format=json',
          '--provider=TEST_FIXTURE',
          '--game-version=FC27',
          '--batch-size=$batchSize',
        ],
        runInShell: true,
        environment: {
          'SUPABASE_URL': 'http://127.0.0.1:${server.port}',
          'SUPABASE_SECRET_KEY': 'test-secret-key',
        },
      );
      sw.stop();
      if (result.exitCode != 0) {
        stdout.writeln('FAILED n=$n batch=$batchSize: ${result.stderr}');
      } else {
        stdout.writeln(
          'n=$n batch=$batchSize -> requests=${fake.requestLog.length} '
          'elapsed_ms=${sw.elapsedMilliseconds}',
        );
      }
      await server.close();
    }
  }
  tempDir.deleteSync(recursive: true);
}
