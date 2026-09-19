// Baixa o catalogo publico de ratings da EA para um ARQUIVO LOCAL.
//
// Fica separado de tool/sync_fc_cards.dart de proposito. Aquele script e
// deliberadamente cego a origem e nunca toca a rede -- o operador baixa o
// arquivo de onde quiser e manda importar. Este aqui e o "baixar a mao",
// automatizado: so fala com a EA e so escreve um arquivo. Nao conhece
// Supabase, nao tem credencial de banco, nao escreve em tabela nenhuma.
//
// FONTE
//   https://drop-api.ea.com/rating/ea-sports-fc -- a API publica que alimenta
//   a pagina de ratings do proprio site da EA. E a MESMA populacao do nosso
//   catalogo: totalItems bate exatamente com as 17.873 cartas ativas, e os
//   ids batem um a um com o prefixo de provider_card_id.
//
// O QUE ELA NAO RESOLVE
//   A EA mantem dois bancos diferentes: o de ratings (registro do jogador,
//   que e o que esta API serve) e o item do Ultimate Team (a arte em
//   FC27/components/items/). Eles divergem -- o Barcola aparece no PSG aqui e
//   com escudo do Liverpool na arte do item. Baixar isto NAO atualiza clube
//   nem overall pra bater com o item; serve pra preencher imagem que falta e
//   pra conferir o que temos contra a fonte.
//
// USO
//   dart run tool/fetch_ea_ratings.dart --out=tool/data/ea_ratings.json
//       [--locale=pt-br] [--limit=100] [--max=0]
//
//   --max limita quantos itens baixar (0 = todos), util pra testar sem
//   puxar o catalogo inteiro.
import 'dart:convert';
import 'dart:io';

const String _endpoint = 'https://drop-api.ea.com/rating/ea-sports-fc';

/// Pausa entre paginas. A API e publica e sem chave; nao ha limite
/// documentado, entao o script se comporta como visitante educado em vez de
/// disparar ~180 requisicoes em rajada.
const Duration _delayBetweenPages = Duration(milliseconds: 350);

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final out = options['out'] ?? 'tool/data/ea_ratings.json';
  final locale = options['locale'] ?? 'pt-br';
  final pageSize = int.parse(options['limit'] ?? '100');
  final max = int.parse(options['max'] ?? '0');

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  final items = <Map<String, dynamic>>[];
  var offset = 0;
  int? total;

  try {
    while (true) {
      final uri = Uri.parse(
        '$_endpoint?locale=$locale&limit=$pageSize&offset=$offset',
      );
      final page = await _getJson(client, uri);
      total ??= page['totalItems'] as int?;

      final pageItems = (page['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (pageItems.isEmpty) {
        break;
      }
      items.addAll(pageItems);
      stdout.write('\r  ${items.length}${total == null ? '' : '/$total'}');

      if (max > 0 && items.length >= max) {
        break;
      }
      if (total != null && items.length >= total) {
        break;
      }
      offset += pageSize;
      await Future<void>.delayed(_delayBetweenPages);
    }
  } finally {
    client.close(force: true);
  }
  stdout.writeln();

  if (total != null && items.length != total && max == 0) {
    stderr.writeln(
      'AVISO: baixei ${items.length} de $total. Arquivo incompleto -- '
      'nao use pra importacao sem conferir.',
    );
  }

  final file = File(out);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'source': _endpoint,
      'locale': locale,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
      'total_items_reported': total,
      'items': items,
    }),
  );
  stdout.writeln('escrito: $out (${items.length} itens)');
}

Future<Map<String, dynamic>> _getJson(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  request.headers.set(HttpHeaders.acceptHeader, 'application/json');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException('HTTP ${response.statusCode} em $uri');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final i = arg.indexOf('=');
    if (i < 0) {
      map[arg.substring(2)] = 'true';
    } else {
      map[arg.substring(2, i)] = arg.substring(i + 1);
    }
  }
  return map;
}
