import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<ProcessResult> _runDryRun(String jsonFilePath) {
  return Process.run('dart', <String>[
    'run',
    'tool/sync_fc_cards.dart',
    '--file=$jsonFilePath',
    '--format=json',
    '--provider=TEST_FIXTURE',
    '--game-version=FC27',
    '--dry-run',
  ], runInShell: true);
}

int _extractInt(String stdout, String label) {
  final line = stdout.split('\n').firstWhere((l) => l.trim().startsWith(label));
  final match = RegExp(r'(\d+)').allMatches(line).last;
  return int.parse(match.group(0)!);
}

File _writeFixture(
  Directory dir,
  String name,
  List<Map<String, dynamic>> rows,
) {
  final file = File('${dir.path}/$name');
  file.writeAsStringSync(jsonEncode(rows));
  return file;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fc_import_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
    'club com o mesmo nome em duas ligas conta como 1 clube distinto no dry-run',
    () async {
      final file = _writeFixture(tempDir, 'clubs.json', <Map<String, dynamic>>[
        <String, dynamic>{
          'provider_player_id': '1001',
          'provider_card_id': '1001:BASE',
          'player_name': 'Player Men',
          'rating': '75',
          'primary_position': 'ST',
          'club_name': 'Shared Club',
          'league_name': 'Mens League',
          'nation_name': 'Nationland',
        },
        <String, dynamic>{
          'provider_player_id': '1002',
          'provider_card_id': '1002:BASE',
          'player_name': 'Player Women',
          'rating': '75',
          'primary_position': 'ST',
          'club_name': 'Shared Club',
          'league_name': 'Womens League',
          'nation_name': 'Nationland',
        },
      ]);

      final result = await _runDryRun(file.path);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final out = result.stdout.toString();
      expect(_extractInt(out, 'lidos:'), 2);
      expect(_extractInt(out, 'validos:'), 2);
      expect(
        _extractInt(out, 'clubs distintos no arquivo:'),
        1,
        reason:
            'clubes com o mesmo nome em ligas diferentes colapsam para 1 no '
            'dry-run (resolucao por nome, sem distinguir liga) -- mesmo '
            'comportamento causaria vinculo de league_id ambiguo se escrito '
            'no banco, ver docs/handoff_etapa17b2.md',
      );
    },
  );

  test(
    'gk_speed ausente em todas as linhas nao invalida cartas de goleiro',
    () async {
      final file = _writeFixture(tempDir, 'gk.json', <Map<String, dynamic>>[
        <String, dynamic>{
          'provider_player_id': '2001',
          'provider_card_id': '2001:BASE',
          'player_name': 'Keeper One',
          'rating': '70',
          'primary_position': 'GK',
          'gk_diving': '65',
          'gk_handling': '66',
          'gk_kicking': '60',
          'gk_reflexes': '68',
          'gk_positioning': '64',
        },
      ]);

      final result = await _runDryRun(file.path);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final out = result.stdout.toString();
      expect(_extractInt(out, 'validos:'), 1);
      expect(_extractInt(out, 'invalidos:'), 0);
      expect(_extractInt(out, 'cards reais (fc_player_cards):'), 1);
    },
  );

  test(
    'linha com identidade de jogador e de carta resolve fc_player_id (players == cards)',
    () async {
      final file = _writeFixture(tempDir, 'link.json', <Map<String, dynamic>>[
        <String, dynamic>{
          'provider_player_id': '3001',
          'provider_card_id': '3001:BASE',
          'player_name': 'Linked Player',
          'rating': '80',
          'primary_position': 'CM',
        },
      ]);

      final result = await _runDryRun(file.path);
      final out = result.stdout.toString();
      expect(_extractInt(out, 'players (fc_players) distintos:'), 1);
      expect(_extractInt(out, 'cards reais (fc_player_cards):'), 1);
      expect(_extractInt(out, 'player-only (so fc_players):'), 0);
    },
  );

  test(
    'linha sem provider_card_id e sem provider_player_id e invalida (nunca inventa id)',
    () async {
      final file = _writeFixture(
        tempDir,
        'invalid.json',
        <Map<String, dynamic>>[
          <String, dynamic>{
            'player_name': 'No Identity',
            'rating': '60',
            'primary_position': 'CB',
          },
        ],
      );

      final result = await _runDryRun(file.path);
      final out = result.stdout.toString();
      expect(_extractInt(out, 'validos:'), 0);
      expect(_extractInt(out, 'invalidos:'), 1);
    },
  );

  test('male e female coexistem na mesma rodada sem se afetarem', () async {
    final file = _writeFixture(
      tempDir,
      'mixed_gender.json',
      <Map<String, dynamic>>[
        <String, dynamic>{
          'provider_player_id': '4001',
          'provider_card_id': '4001:BASE',
          'player_name': 'Male Player',
          'rating': '72',
          'primary_position': 'ST',
          'league_name': 'Premier League',
        },
        <String, dynamic>{
          'provider_player_id': '4002',
          'provider_card_id': '4002:BASE',
          'player_name': 'Female Player',
          'rating': '74',
          'primary_position': 'ST',
          'league_name': 'Barclays WSL',
        },
      ],
    );

    final result = await _runDryRun(file.path);
    final out = result.stdout.toString();
    expect(_extractInt(out, 'validos:'), 2);
    expect(_extractInt(out, 'cards reais (fc_player_cards):'), 2);
    expect(_extractInt(out, 'leagues distintas no arquivo:'), 2);
  });

  test(
    'reimport do mesmo arquivo produz o mesmo resultado de parsing (determinismo)',
    () async {
      final file = _writeFixture(tempDir, 'repeat.json', <Map<String, dynamic>>[
        <String, dynamic>{
          'provider_player_id': '5001',
          'provider_card_id': '5001:BASE',
          'player_name': 'Repeatable Player',
          'rating': '77',
          'primary_position': 'CDM',
        },
      ]);

      final first = await _runDryRun(file.path);
      final second = await _runDryRun(file.path);
      expect(first.stdout.toString(), second.stdout.toString());
    },
  );
}
