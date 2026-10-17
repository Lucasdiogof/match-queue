// Baixa as versoes ESPECIAIS (TOTW, promos, Icons...) do catalogo publico do
// FCData para um ARQUIVO LOCAL no formato canonico de tool/sync_fc_cards.dart.
//
// Fica separado do importador de proposito, no mesmo molde de
// tool/fetch_ea_ratings.dart: este script so fala com o FCData e so escreve
// arquivos. Nao conhece Supabase, nao tem credencial, nao toca em tabela.
//
// FONTE E LIMITES
//   Paginas HTML publicas (/players/?page=N e /fc27/players/<slug>/<versao>/).
//   robots.txt do FCData libera as paginas e bloqueia so /api/, que este
//   script NUNCA chama. Sem login, cookie, token, CAPTCHA ou Cloudflare
//   bypass. Um 403 ou 429 persistente encerra a execucao (nunca insiste).
//   Os dados de cartas e as imagens sao da EA / do FCData: confirmar a
//   permissao de uso ANTES de gravar no banco de producao.
//
// QUAL CARTA E "ESPECIAL"
//   A listagem so expoe links. Carta-base tem URL /fc27/players/<slug>/ e
//   itemId == productId (ja existe no catalogo atual como "{playerId}:BASE").
//   Especial tem um segmento de versao: /fc27/players/<slug>/<versao>/.
//   Os dados da carta vem embutidos na propria pagina (payload do Next.js),
//   sem chamar nenhuma rota interna.
//
// IDENTIDADE
//   provider_card_id   = itemId   (a CARTA especifica)
//   provider_player_id = productId (o jogador/base)
//   Nunca nome+rating.
//
// IMAGENS
//   O FCData nao entrega a carta renderizada. Entrega componentes: o
//   actionShot (PNG recortado, especifico do itemId), o fundo da raridade, e
//   bandeira/clube/liga. Por isso:
//     player_image_url = actionShot
//     card_image_url   = NUNCA preenchido aqui
//     fundo/bandeira/clube/liga = raw_metadata.images (para o widget compor)
//   shieldUrl do FCData e a carta-BASE do productId; nao serve para especial
//   e e descartado de proposito.
//
// CHECKPOINT / RETOMADA
//   - Cada carta processada vira um arquivo em --cache-dir (escrita atomica,
//     chaveado pela URL da versao, que identifica o itemId). Rodar de novo
//     pula o que ja esta la; matar no meio e seguro.
//   - <out-dir>/checkpoint.json guarda a proxima pagina de listagem. Ao
//     reiniciar sem --start-page, retoma dela. --fresh ignora o checkpoint
//     (o cache continua valendo, entao nada e baixado de novo).
//   - Os arquivos FINAIS (fc27_specials_*.json/csv) so sao escritos quando o
//     crawl termina por completo: todas as paginas, sem 403/429, sem falha
//     de carta e sem limite (--max-*) ou --stop-when-known. Qualquer outro
//     fim escreve fc27_specials_*.partial.* e NUNCA os nomes finais.
//   - No arquivo, o mesmo itemId aparece uma vez so.
//
// USO
//   dart run tool/fetch_fcdata_specials.dart --out-dir=tmp/fcdata
//       [--list=all|latest] [--start-page=1] [--max-pages=0] [--max-cards=0]
//       [--delay-ms=2000] [--stop-when-known] [--cache-dir=tmp/fcdata/cache]
//
//   --list=latest --stop-when-known e o modo incremental: percorre as
//   paginas "mais recentes" e para na primeira pagina sem nenhuma especial
//   nova (todas ja em cache).
//   --delay-ms tem piso de 1000 (nunca polling agressivo).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const String _origin = 'https://fcdata.io';
const String _userAgent =
    'MatchQueueCatalogSync/1.0 (+contact: lucasdiogo1234@gmail.com)';
const String _provider = 'FCDATA_FC27';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = _userAgent;
  final fetcher = _Fetcher(client, options.delay);
  final cacheDir = Directory(options.cacheDir)..createSync(recursive: true);

  final listBase = options.list == 'latest'
      ? '$_origin/players/latest/'
      : '$_origin/players/';

  final outDir = Directory(options.outDir)..createSync(recursive: true);
  final checkpointFile = File('${outDir.path}/checkpoint.json');
  var startPage = options.startPage;
  var resumed = false;
  var alreadyCompleted = false;
  int? knownLastPage;
  if (!options.fresh &&
      !options.startPageGiven &&
      checkpointFile.existsSync()) {
    try {
      final cp =
          jsonDecode(checkpointFile.readAsStringSync()) as Map<String, dynamic>;
      if (cp['list'] == options.list) {
        startPage = cp['next_page'] as int;
        knownLastPage = cp['last_page'] as int?;
        alreadyCompleted = cp['completed'] == true;
        resumed = true;
        stdout.writeln(
          'Checkpoint encontrado: retomando da pagina $startPage'
          '${alreadyCompleted ? ' (crawl ja estava completo)' : ''}.',
        );
      }
    } on Object {
      stdout.writeln('Checkpoint ilegivel -- ignorando e recomecando.');
    }
  }

  final stopwatch = Stopwatch()..start();
  var pagesVisited = 0;
  var page = startPage;
  var lastPage = options.maxPages > 0
      ? startPage + options.maxPages - 1
      : (knownLastPage ?? 1 << 30);
  var naturalEnd = alreadyCompleted;
  final pageRetries = <int, int>{};
  var detailRetries = 0;
  var retriesTotalPages = 0;
  var seenSpecials = 0;
  var skippedBase = 0;
  var fetched = 0;
  var fromCache = 0;
  var failed = 0;
  final failures = <String>[];
  final seenPaths = <String>{};

  stdout.writeln(
    'FCData -> especiais | lista=${options.list} pagina inicial=$page '
    'delay=${options.delay.inMilliseconds}ms',
  );

  pageLoop:
  while (!alreadyCompleted && page <= lastPage) {
    final url = page == 1 && options.list == 'all'
        ? listBase
        : '$listBase?page=$page';
    final html = await fetcher.get(url);
    if (html == null) {
      stderr.writeln(
        'Falha ao ler a listagem $url (http=${fetcher.lastStatus}'
        '${fetcher.abortReason == null ? '' : ', ${fetcher.abortReason}'}) -- encerrando.',
      );
      failed++;
      failures.add('listagem pagina $page ilegivel');
      break;
    }
    if (knownLastPage == null && options.maxPages == 0) {
      final pages = RegExp(
        r'[?&]page=(\d+)',
      ).allMatches(html).map((m) => int.parse(m.group(1)!)).fold<int>(1, max);
      lastPage = pages;
      knownLastPage = pages;
      stdout.writeln('Total de paginas detectado: $pages');
    }

    pagesVisited++;
    var paths = _cardPaths(html);
    // Pagina sem links antes da ultima pagina conhecida NAO e o fim: a
    // resposta pode ter vindo degradada (ja aconteceu na pagina 86 de 474 num
    // crawl real). Tenta de novo com espera; se continuar vazia, o crawl
    // falha em vez de fingir que terminou.
    final listingStatus = fetcher.lastStatus;
    var listingRetries = 0;
    for (
      var retry = 1;
      paths.isEmpty && page <= lastPage && retry <= 3;
      retry++
    ) {
      listingRetries = retry;
      pageRetries[page] = retry;
      retriesTotalPages++;
      stdout.writeln(
        'Pagina $page veio sem cartas (${html.length} bytes) -- tentativa '
        '$retry/3 apos espera.',
      );
      await Future<void>.delayed(Duration(seconds: 20 * retry));
      final again = await fetcher.get(url);
      if (again != null) {
        paths = _cardPaths(again);
      }
    }
    if (paths.isEmpty) {
      // Toda pagina ate a ultima conhecida precisa ter cartas; vazio
      // persistente e falha, nunca fim natural.
      stderr.writeln('Pagina $page vazia mesmo apos retry -- crawl falhou.');
      failed++;
      failures.add('listagem pagina $page vazia');
      break;
    }
    var newOnThisPage = 0;
    for (final path in paths) {
      if (!seenPaths.add(path)) {
        continue;
      }
      if (!_isSpecial(path)) {
        skippedBase++;
        continue;
      }
      seenSpecials++;
      final cacheFile = File('${cacheDir.path}/${_cacheName(path)}.json');
      if (cacheFile.existsSync()) {
        fromCache++;
        continue;
      }
      if (options.maxCards > 0 && fetched >= options.maxCards) {
        break pageLoop;
      }
      newOnThisPage++;
      final detail = await fetcher.get('$_origin$path');
      if (fetcher.lastAttempts > 1) {
        detailRetries++;
      }
      if (detail == null) {
        failed++;
        failures.add(path);
        if (fetcher.aborted) {
          break pageLoop;
        }
        continue;
      }
      try {
        final parsed = _parseDetail(detail, path);
        _writeAtomic(cacheFile, jsonEncode(parsed));
        fetched++;
      } on Object catch (error) {
        failed++;
        failures.add('$path ($error)');
      }
    }
    stdout.writeln(
      'pagina $page: http=$listingStatus links=${paths.length} '
      'tentativas_extra=$listingRetries, $newOnThisPage especiais novas '
      '(acumulado: baixadas=$fetched cache=$fromCache base_ignoradas='
      '$skippedBase falhas=$failed)',
    );
    if (options.stopWhenKnown && newOnThisPage == 0) {
      stdout.writeln('Pagina sem especial nova -- parando (incremental).');
      break;
    }
    if (fetcher.aborted) {
      break;
    }
    page++;
    // Pagina inteira processada: so agora o checkpoint avanca.
    _writeAtomic(
      checkpointFile,
      jsonEncode(<String, dynamic>{
        'list': options.list,
        'next_page': page,
        'last_page': knownLastPage,
        'completed': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }
  if (!alreadyCompleted && page > lastPage && options.maxPages == 0) {
    naturalEnd = true;
  }

  // Consolida o cache inteiro, ordenado por itemId para o resultado ser
  // deterministico e diffavel.
  final entries =
      <Map<String, dynamic>>[
        for (final file in cacheDir.listSync().whereType<File>())
          if (file.path.endsWith('.json'))
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      ]..sort(
        (a, b) => int.parse(
          '${(a['row'] as Map)['provider_card_id']}',
        ).compareTo(int.parse('${(b['row'] as Map)['provider_card_id']}')),
      );
  final ids = <String>{};
  var duplicated = 0;
  final unique = <Map<String, dynamic>>[];
  for (final e in entries) {
    if (ids.add('${(e['row'] as Map)['provider_card_id']}')) {
      unique.add(e);
    } else {
      duplicated++;
    }
  }
  final rows = <Map<String, dynamic>>[
    for (final e in unique) e['row'] as Map<String, dynamic>,
  ];
  final complete =
      naturalEnd &&
      !fetcher.aborted &&
      failed == 0 &&
      options.maxPages == 0 &&
      options.maxCards == 0 &&
      !options.stopWhenKnown &&
      (startPage == 1 || resumed);
  final suffix = complete ? '' : '.partial';
  const encoder = JsonEncoder.withIndent(' ');
  File('${outDir.path}/fc27_specials_raw$suffix.json').writeAsStringSync(
    encoder.convert(<Map<String, dynamic>>[
      for (final e in unique)
        <String, dynamic>{'url_path': e['url_path'], 'card': e['raw']},
    ]),
  );
  final importerRows = rows.map(_forImporter).toList();
  File(
    '${outDir.path}/fc27_specials_normalized$suffix.json',
  ).writeAsStringSync(encoder.convert(importerRows));
  File(
    '${outDir.path}/fc27_specials_normalized$suffix.csv',
  ).writeAsStringSync(_toCsv(importerRows));

  stdout
    ..writeln('---')
    ..writeln('especiais vistas na listagem: $seenSpecials')
    ..writeln('baixadas agora: $fetched | ja em cache: $fromCache')
    ..writeln('cartas-base ignoradas: $skippedBase')
    ..writeln('falhas: $failed')
    ..writeln('provider_card_id duplicado (removido da saida): $duplicated')
    ..writeln(
      complete
          ? 'CRAWL COMPLETO: arquivos finais escritos.'
          : 'CRAWL INCOMPLETO: escritos so arquivos .partial (nao e dataset final).',
    )
    ..writeln('pasta: ${outDir.path} (${rows.length} cartas)')
    ..writeln('listagens percorridas: $pagesVisited')
    ..writeln('tempo total: ${stopwatch.elapsed}');
  for (final failure in failures.take(20)) {
    stdout.writeln('  falhou: $failure');
  }
  final statsFile = File('${outDir.path}/crawl_stats.json');
  final previousRuns = statsFile.existsSync()
      ? (jsonDecode(statsFile.readAsStringSync()) as List<dynamic>)
      : <dynamic>[];
  _writeAtomic(
    statsFile,
    const JsonEncoder.withIndent(' ').convert(<dynamic>[
      ...previousRuns,
      <String, dynamic>{
        'finished_at': DateTime.now().toUtc().toIso8601String(),
        'start_page': startPage,
        'last_page_reached': page,
        'expected_pages': knownLastPage,
        'pages_visited_this_run': pagesVisited,
        'complete': complete,
        'aborted': fetcher.aborted,
        'abort_reason': fetcher.abortReason,
        'failed_items': failed,
        'downloaded_this_run': fetched,
        'recovered_from_cache_this_run': fromCache,
        'specials_seen_this_run': seenSpecials,
        'base_ignored_this_run': skippedBase,
        'listing_pages_with_retry': pageRetries.length,
        'listing_retry_attempts': retriesTotalPages,
        'detail_calls_with_retry': detailRetries,
        'total_http_retries': fetcher.totalRetries,
        'duplicate_item_ids_removed': duplicated,
        'elapsed_seconds': stopwatch.elapsed.inSeconds,
      },
    ]),
  );
  if (complete) {
    _writeAtomic(
      checkpointFile,
      jsonEncode(<String, dynamic>{
        'list': options.list,
        'next_page': page,
        'last_page': knownLastPage,
        'completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }
  client.close();
  if (fetcher.aborted) {
    stderr.writeln(
      'Execucao interrompida (${fetcher.abortReason}). Sem bypass e sem '
      'insistir: rode de novo mais tarde (cache e checkpoint preservam o '
      'progresso).',
    );
    exit(2);
  }
}

class _Options {
  _Options({
    required this.outDir,
    required this.cacheDir,
    required this.list,
    required this.startPage,
    required this.maxPages,
    required this.maxCards,
    required this.delay,
    required this.stopWhenKnown,
    required this.fresh,
    required this.startPageGiven,
  });

  final String outDir;
  final String cacheDir;
  final String list;
  final int startPage;
  final int maxPages;
  final int maxCards;
  final Duration delay;
  final bool stopWhenKnown;
  final bool fresh;
  final bool startPageGiven;

  static _Options parse(List<String> args) {
    String value(String name, String fallback) {
      for (final arg in args) {
        if (arg.startsWith('--$name=')) {
          return arg.substring(name.length + 3);
        }
      }
      return fallback;
    }

    final list = value('list', 'all');
    if (list != 'all' && list != 'latest') {
      stderr.writeln('--list precisa ser all ou latest.');
      exit(1);
    }
    final delayMs = max(1000, int.tryParse(value('delay-ms', '2000')) ?? 2000);
    return _Options(
      outDir: value('out-dir', 'tmp/fcdata'),
      cacheDir: value('cache-dir', 'tmp/fcdata/cache'),
      list: list,
      startPage: max(1, int.tryParse(value('start-page', '1')) ?? 1),
      maxPages: int.tryParse(value('max-pages', '0')) ?? 0,
      maxCards: int.tryParse(value('max-cards', '0')) ?? 0,
      delay: Duration(milliseconds: delayMs),
      stopWhenKnown: args.contains('--stop-when-known'),
      fresh: args.contains('--fresh'),
      startPageGiven: args.any((a) => a.startsWith('--start-page=')),
    );
  }
}

/// GET com intervalo minimo entre requisicoes, retry curto em 5xx/timeout e
/// parada em 403/429 persistente.
class _Fetcher {
  _Fetcher(this._client, this._delay);

  final HttpClient _client;
  final Duration _delay;
  final Random _random = Random();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  bool aborted = false;
  String? abortReason;

  /// Ultimo status HTTP visto e quantas tentativas a ultima chamada gastou.
  int lastStatus = 0;
  int lastAttempts = 0;

  /// Retries acumulados na execucao (tentativas alem da primeira).
  int totalRetries = 0;

  static bool _looksLikeChallenge(String body) {
    final text = body.toLowerCase();
    final marker =
        text.contains('just a moment') ||
        text.contains('cf-chl') ||
        text.contains('cf-challenge') ||
        text.contains('captcha') ||
        text.contains('attention required');
    // Pagina normal do FCData sempre traz links de carta ou payload Next.js.
    return marker &&
        !text.contains('/fc27/players/') &&
        !text.contains('__next_f');
  }

  Future<String?> get(String url) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      lastAttempts = attempt;
      if (attempt > 1) {
        totalRetries++;
      }
      final wait =
          _delay +
          Duration(milliseconds: _random.nextInt(500)) -
          DateTime.now().difference(_last);
      if (!wait.isNegative) {
        await Future<void>.delayed(wait);
      }
      _last = DateTime.now();
      try {
        // Um unico limite de tempo cobre conexao, cabecalhos E leitura do
        // corpo: uma conexao pendurada no meio do corpo ja travou um crawl
        // inteiro por horas.
        final result = await (() async {
          final request = await _client.getUrl(Uri.parse(url));
          final response = await request.close();
          final body = await response.transform(utf8.decoder).join();
          return (response, body);
        })().timeout(const Duration(seconds: 60));
        final response = result.$1;
        final body = result.$2;
        lastStatus = response.statusCode;
        if (response.statusCode == 200) {
          if (_looksLikeChallenge(body)) {
            aborted = true;
            abortReason = 'challenge/CAPTCHA em $url';
            return null;
          }
          return body;
        }
        if (response.statusCode == 404) {
          return null;
        }
        if (response.statusCode == 403 || response.statusCode == 429) {
          // Sem insistir e sem bypass: o crawl para como incompleto.
          aborted = true;
          abortReason = 'HTTP ${response.statusCode} em $url';
          return null;
        }
      } on Object {
        // timeout / rede: tenta de novo abaixo.
      }
      await Future<void>.delayed(Duration(seconds: 5 * attempt));
    }
    return null;
  }
}

/// Links de carta na ordem em que aparecem, sem repetir.
List<String> _cardPaths(String html) => <String>{
  for (final match in RegExp(
    r'href="(/fc27/players/[^"?#]+)"',
  ).allMatches(html))
    match.group(1)!,
}.toList(growable: false);

bool _isSpecial(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  // fc27 / players / <slug> [/ <versao> ...]
  return segments.length >= 4;
}

String _cacheName(String path) =>
    path.replaceAll(RegExp(r'^/|/$'), '').replaceAll('/', '__');

/// Decodifica o payload do Next.js (self.__next_f.push) em um texto so.
String _payload(String html) {
  final buffer = StringBuffer();
  for (final match in RegExp(
    r'self\.__next_f\.push\(\[1,"((?:[^"\\]|\\.)*)"\]\)',
  ).allMatches(html)) {
    buffer.write(jsonDecode('"${match.group(1)}"') as String);
  }
  return buffer.toString();
}

/// Objeto JSON que contem [position], por contagem de chaves.
Map<String, dynamic> _enclosingObject(String text, int position) {
  var depth = 0;
  var start = position;
  while (start > 0) {
    start--;
    final char = text[start];
    if (char == '}') {
      depth++;
    } else if (char == '{') {
      if (depth == 0) {
        break;
      }
      depth--;
    }
  }
  var open = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final char = text[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '"') {
        inString = false;
      }
    } else if (char == '"') {
      inString = true;
    } else if (char == '{') {
      open++;
    } else if (char == '}') {
      open--;
      if (open == 0) {
        return jsonDecode(text.substring(start, i + 1)) as Map<String, dynamic>;
      }
    }
  }
  throw const FormatException('objeto da carta nao fechou');
}

/// {raw: objeto da carta como veio na pagina, row: forma canonica}.
Map<String, dynamic> _parseDetail(String html, String path) {
  final text = _payload(html);
  final definition = RegExp(
    r'"data-card-definition":"(\d+)"',
  ).firstMatch(text)?.group(1);
  if (definition == null) {
    throw const FormatException('sem data-card-definition');
  }
  final at = text.indexOf('"itemId":$definition');
  if (at < 0) {
    throw const FormatException('sem itemId no payload');
  }
  final card = _enclosingObject(text, at);
  if ('${card['itemId']}' != definition || card['productId'] == null) {
    throw const FormatException('objeto da carta inconsistente');
  }
  return <String, dynamic>{
    'raw': card,
    'url_path': path,
    'row': _toCanonical(card, path),
  };
}

/// O importador le cada celula como texto: listas viram "A|B|C" e objetos
/// viram JSON serializado. O cache guarda a forma estruturada; a conversao e
/// so na saida. Papeis repetidos (o mesmo papel vale para varias posicoes)
/// entram uma vez so.
Map<String, dynamic> _forImporter(
  Map<String, dynamic> row,
) => <String, dynamic>{
  for (final entry in row.entries)
    entry.key: switch (entry.value) {
      final List<dynamic> list =>
        (entry.key == 'player_roles' ? list.toSet().toList() : list).join('|'),
      final Map<dynamic, dynamic> map => jsonEncode(map),
      final other => other,
    },
};

String? _str(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

/// Mapeia para os nomes canonicos de tool/sync_fc_cards.dart.
Map<String, dynamic> _toCanonical(Map<String, dynamic> c, String path) {
  final playstyles = (c['playstyles'] as List<dynamic>? ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
  final roles = (c['roles'] as List<dynamic>? ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
  final alt = (c['altPositions'] as List<dynamic>? ?? const <dynamic>[])
      .cast<Map<String, dynamic>>();
  final firstName = _str(c['firstName']);
  final lastName = _str(c['lastName']);
  final fullName = <String>[?firstName, ?lastName].join(' ');
  final commonName = _str(c['commonName']);
  final addedOn = _str(c['addedOn'])?.replaceFirst(RegExp(r'^\$D'), '');

  const detailKeys = <String>[
    'acceleration',
    'sprintSpeed',
    'positioning',
    'finishing',
    'shotPower',
    'longShots',
    'volleys',
    'penalties',
    'vision',
    'crossing',
    'fkAccuracy',
    'shortPassing',
    'longPassing',
    'curve',
    'agility',
    'balance',
    'reactions',
    'ballControl',
    'dribbling',
    'composure',
    'interceptions',
    'headingAccuracy',
    'defensiveAwareness',
    'standingTackle',
    'slidingTackle',
    'jumping',
    'stamina',
    'strength',
    'aggression',
    'gkDiving',
    'gkHandling',
    'gkKicking',
    'gkPositioning',
    'gkReflexes',
  ];

  return <String, dynamic>{
    'provider_card_id': '${c['itemId']}',
    'provider_player_id': '${c['productId']}',
    'player_name': fullName.isNotEmpty ? fullName : (commonName ?? ''),
    'common_name': commonName,
    'rating': c['overall'],
    'primary_position': _str(c['positionLabel']) ?? _str(c['positionShort']),
    'alternative_positions': <String>[
      for (final a in alt)
        if (_str(a['shortLabel']) != null) _str(a['shortLabel'])!,
    ],
    'pace': c['pac'],
    'shooting': c['sho'],
    'passing': c['pas'],
    'dribbling': c['dri'],
    'defending': c['def'],
    'physical': c['phy'],
    'gk_diving': c['gkDiving'],
    'gk_handling': c['gkHandling'],
    'gk_kicking': c['gkKicking'],
    'gk_reflexes': c['gkReflexes'],
    'gk_positioning': c['gkPositioning'],
    'skill_moves': c['skillMoves'],
    'weak_foot': c['weakFoot'],
    'preferred_foot': _str(c['preferredFoot'])?.toUpperCase(),
    'height_cm': c['heightCm'],
    'playstyles': <String>[
      for (final p in playstyles)
        if (p['isPlus'] != true && _str(p['label']) != null) _str(p['label'])!,
    ],
    'playstyles_plus': <String>[
      for (final p in playstyles)
        if (p['isPlus'] == true && _str(p['label']) != null) _str(p['label'])!,
    ],
    // familiarity 2 = "++" e 1 = "+" (suposicao a confirmar contra o jogo).
    'player_roles': <String>[
      for (final r in roles)
        if (_str(r['name']) != null)
          '${r['name']}${r['familiarity'] == 2 ? '++' : (r['familiarity'] == 1 ? '+' : '')}',
    ],
    'rarity': _str(c['raritySlug']),
    'card_type': _str(c['promoName']) ?? _str(c['rarityName']),
    'club_name': _str(c['clubName']),
    'club_external_id': c['clubId'] == null ? null : '${c['clubId']}',
    'league_name': _str(c['leagueName']),
    'nation_name': _str(c['nationName']),
    'player_image_url': _str(c['avatarUrl']),
    'source_url': '$_origin$path',
    'detailed_stats': <String, dynamic>{
      for (final key in detailKeys)
        if (c[key] != null) key: c[key],
    },
    'raw_metadata': <String, dynamic>{
      'source': _provider,
      'url_path': path,
      'url_slug': c['urlSlug'],
      'rarity_name': c['rarityName'],
      'promo_name': c['promoName'],
      'is_legend': c['isLegend'],
      'gender': c['gender'],
      'birthdate': c['birthdate'],
      'weight_kg': c['weightKg'],
      'item_score': c['itemScore'],
      'added_on': addedOn,
      'nation_id': c['nationId'],
      'league_id': c['leagueId'],
      'images': <String, dynamic>{
        'action_shot': _str(c['avatarUrl']),
        'rarity_background': _str(c['rarityBackgroundUrl']),
        'nation': _str(c['nationImageUrl']),
        'club': _str(c['clubImageUrl']),
        'league': _str(c['leagueImageUrl']),
      },
    },
  };
}

/// Escreve em arquivo temporario e renomeia: nunca deixa um arquivo pela
/// metade se o processo cair no meio da escrita.
void _writeAtomic(File file, String content) {
  final temp = File('${file.path}.tmp')..writeAsStringSync(content);
  temp.renameSync(file.path);
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  return text.contains(RegExp(r'[",\n]'))
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

String _toCsv(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) {
    return '';
  }
  final columns = rows.first.keys.toList();
  final buffer = StringBuffer()..writeln(columns.join(','));
  for (final row in rows) {
    buffer.writeln(columns.map((c) => _csvCell(row[c])).join(','));
  }
  return buffer.toString();
}
