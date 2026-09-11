// Probe SERVER-SIDE de disponibilidade de arte oficial de carta.
//
// NUNCA rodar de dentro do app Flutter -- exige a secret key, que ignora RLS
// inteira. E um script standalone, chamado a mao por quem tem acesso ao
// projeto Supabase, no mesmo molde de tool/sync_fc_cards.dart.
//
// DELIBERADAMENTE SEPARADO DO IMPORTER
//
// sync_fc_cards.dart normaliza a linha inteira e faria upsert de rating,
// posicao, stats, PlayStyles, clube, liga e nacao junto. Este script existe
// para mexer SO na camada de artwork, sem encostar em nenhum desses campos.
// A garantia nao depende de disciplina de codigo daqui: a escrita passa pelo
// RPC apply_card_artwork_probe, que so alcanca card_image_url e
// card_image_checked_at. Qualquer outra coluna esta fora do alcance dele.
//
// O QUE ELE FAZ
//   1. Le a fila: cartas ativas com card_image_checked_at NULL, cada uma com
//      o provider_player_id do jogador (a chave da EA, confirmada batendo em
//      17.873 de 17.873 contra o playerId embutido em source_url).
//   2. Monta a URL da carta e testa CADA id individualmente com HEAD.
//      Nunca infere ausencia por faixa de id: as ausencias medidas estao
//      espalhadas nos dois generos e nos tres tiers, e as faixas de id que
//      passam e que falham se sobrepoem por inteiro.
//   3. Grava em lotes pequenos: URL quando 200, NULL quando ausente, e
//      checked_at nos dois casos.
//
// HEAD e nao GET: a verificacao nao precisa do corpo, entao nada de imagem e
// copiado para ca. No piloto de 108 cartas, HEAD e GET deram exatamente o
// mesmo status nos 108 casos.
//
// 403 e o "nao existe" deste CDN, nao bloqueio -- confirmado por quatro vias:
// repescagem apos pausa nao recupera nenhum, ids vizinhos respondem 200 na
// mesma corrida, as outras variantes de locale/extensao tambem dao 403, e um
// id comprovadamente inexistente tambem da 403.
//
// RETOMAVEL: so um resultado DEFINITIVO (200 ou 403) grava checked_at. Erro
// transitorio -- rede, timeout, 5xx, 429 -- deixa a carta na fila para a
// proxima execucao. Matar no meio e rodar de novo continua de onde parou, e
// rodar de novo depois de terminado nao faz nada.
//
// USO
//   dart run tool/probe_card_artwork.dart --limit=100 --dry-run
//   dart run tool/probe_card_artwork.dart --limit=100
//   dart run tool/probe_card_artwork.dart
//
// AMBIENTE
//   SUPABASE_URL
//   SUPABASE_SECRET_KEY   (fallback legado: SUPABASE_SERVICE_ROLE_KEY)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Padrao publico da arte de carta. Fica aqui, no operador, e nao no schema
/// -- o RPC recebe URLs prontas justamente para nao gravar fornecedor nenhum
/// dentro do banco.
const String _artworkUrlTemplate =
    'https://ratings-images-prod.pulse.ea.com/FC27/components/items/'
    '{id}_pt-BR.webp';

const String _userAgent = 'fifa-queue-artwork-probe/1.0';

/// Lote de escrita. Pequeno de proposito: um lote perdido custa pouco, e o
/// progresso fica visivel enquanto roda.
const int _defaultBatchSize = 200;

/// Requisicoes simultaneas contra o CDN. Conservador de proposito.
const int _defaultConcurrency = 6;

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final baseUrl = Platform.environment['SUPABASE_URL'];
  final secretKey = Platform.environment['SUPABASE_SECRET_KEY'] ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (baseUrl == null || baseUrl.isEmpty || secretKey == null || secretKey.isEmpty) {
    stderr.writeln(
      'SUPABASE_URL e SUPABASE_SECRET_KEY (ou o fallback legado '
      'SUPABASE_SERVICE_ROLE_KEY) precisam estar no ambiente.',
    );
    exitCode = 1;
    return;
  }

  final client = http.Client();
  final db = _Database(client, baseUrl, secretKey);
  final stopwatch = Stopwatch()..start();
  final stats = _Stats();

  try {
    stdout.writeln('lendo a fila...');
    final queue = await db.pendingCards(limit: options.limit);
    if (queue.isEmpty) {
      stdout.writeln('nada pendente -- toda carta ativa ja foi verificada.');
      return;
    }
    stdout.writeln(
      '${queue.length} carta(s) a verificar'
      '${options.dryRun ? '  [DRY RUN -- nada sera gravado]' : ''}\n',
    );

    for (var start = 0; start < queue.length; start += options.batchSize) {
      final end = (start + options.batchSize).clamp(0, queue.length);
      final batch = queue.sublist(start, end);
      final results = await _probeBatch(client, batch, options.concurrency);

      final found = <_Card>[];
      final missing = <_Card>[];
      for (final result in results) {
        switch (result.outcome) {
          case _Outcome.found:
            found.add(result.card);
          case _Outcome.missing:
            missing.add(result.card);
          case _Outcome.transient:
            stats.transientDetail.update(
              result.detail ?? 'desconhecido',
              (value) => value + 1,
              ifAbsent: () => 1,
            );
        }
      }

      if (!options.dryRun && (found.isNotEmpty || missing.isNotEmpty)) {
        final applied = await db.applyProbe(
          foundIds: found.map((c) => c.cardId).toList(),
          foundUrls: found.map((c) => _urlFor(c.playerId)).toList(),
          missingIds: missing.map((c) => c.cardId).toList(),
        );
        // O RPC filtra is_active de novo: se ele gravou menos linhas do que
        // mandamos, alguma carta saiu de circulacao no meio da corrida.
        final written = (applied['found'] as int) + (applied['missing'] as int);
        if (written != found.length + missing.length) {
          stdout.writeln(
            '  aviso: enviei ${found.length + missing.length} linha(s), '
            'o banco gravou $written (carta desativada durante a corrida?)',
          );
        }
      }

      stats.found += found.length;
      stats.missing += missing.length;
      stats.transient +=
          results.length - found.length - missing.length;
      stats.processed += results.length;

      stdout.writeln(
        '  ${stats.processed}/${queue.length}  '
        'com arte ${stats.found}  sem arte ${stats.missing}'
        '${stats.transient > 0 ? '  erro ${stats.transient}' : ''}',
      );
    }

    stopwatch.stop();
    _report(stats, stopwatch, options);
  } finally {
    client.close();
  }
}

String _urlFor(String playerId) =>
    _artworkUrlTemplate.replaceFirst('{id}', playerId);

Future<List<_ProbeResult>> _probeBatch(
  http.Client client,
  List<_Card> batch,
  int concurrency,
) async {
  final results = <_ProbeResult>[];
  for (var i = 0; i < batch.length; i += concurrency) {
    final end = (i + concurrency).clamp(0, batch.length);
    results.addAll(
      await Future.wait(
        batch.sublist(i, end).map((card) => _probe(client, card)),
      ),
    );
  }
  return results;
}

Future<_ProbeResult> _probe(http.Client client, _Card card) async {
  try {
    final response = await client
        .head(
          Uri.parse(_urlFor(card.playerId)),
          headers: const <String, String>{'User-Agent': _userAgent},
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return _ProbeResult(card, _Outcome.found);
    }
    // 403/404 = o objeto nao existe. Qualquer outra coisa e transitoria e a
    // carta volta pra fila -- marcar 429 ou 5xx como "sem arte" gravaria uma
    // ausencia falsa que ninguem reavaliaria depois.
    if (response.statusCode == 403 || response.statusCode == 404) {
      return _ProbeResult(card, _Outcome.missing);
    }
    return _ProbeResult(
      card,
      _Outcome.transient,
      detail: 'HTTP ${response.statusCode}',
    );
  } on TimeoutException {
    return _ProbeResult(card, _Outcome.transient, detail: 'timeout');
  } catch (error) {
    return _ProbeResult(card, _Outcome.transient, detail: '${error.runtimeType}');
  }
}

void _report(_Stats stats, Stopwatch stopwatch, _Options options) {
  final elapsed = stopwatch.elapsed;
  final minutes = elapsed.inMinutes;
  final seconds = elapsed.inSeconds % 60;
  final total = stats.found + stats.missing;

  stdout
    ..writeln('\n${'=' * 56}')
    ..writeln('  verificadas       : ${stats.processed}')
    ..writeln('  com artwork       : ${stats.found}')
    ..writeln('  sem artwork       : ${stats.missing}')
    ..writeln('  erro transitorio  : ${stats.transient}'
        '${stats.transient > 0 ? '  (seguem na fila)' : ''}');
  if (total > 0) {
    stdout.writeln(
      '  taxa de cobertura : '
      '${(100 * stats.found / total).toStringAsFixed(1)}%',
    );
  }
  stdout.writeln('  tempo             : ${minutes}m ${seconds}s');

  if (stats.transientDetail.isNotEmpty) {
    stdout.writeln('\n  erros transitorios por tipo:');
    for (final entry in stats.transientDetail.entries) {
      stdout.writeln('    ${entry.key}: ${entry.value}');
    }
  }
  if (options.dryRun) {
    stdout.writeln('\n  DRY RUN -- nenhuma linha foi gravada.');
  }
}

enum _Outcome { found, missing, transient }

class _Card {
  const _Card(this.cardId, this.playerId);
  final String cardId;
  final String playerId;
}

class _ProbeResult {
  const _ProbeResult(this.card, this.outcome, {this.detail});
  final _Card card;
  final _Outcome outcome;
  final String? detail;
}

class _Stats {
  int processed = 0;
  int found = 0;
  int missing = 0;
  int transient = 0;
  final Map<String, int> transientDetail = <String, int>{};
}

class _Options {
  const _Options({
    required this.limit,
    required this.batchSize,
    required this.concurrency,
    required this.dryRun,
  });

  factory _Options.parse(List<String> args) {
    int? intArg(String name) {
      final match = args.where((a) => a.startsWith('--$name=')).firstOrNull;
      return match == null ? null : int.tryParse(match.split('=').last);
    }

    return _Options(
      limit: intArg('limit'),
      batchSize: intArg('batch') ?? _defaultBatchSize,
      concurrency: intArg('concurrency') ?? _defaultConcurrency,
      dryRun: args.contains('--dry-run'),
    );
  }

  /// Sem limite, processa a fila inteira.
  final int? limit;
  final int batchSize;
  final int concurrency;
  final bool dryRun;
}

class _Database {
  _Database(this._client, this._baseUrl, this._secretKey);

  final http.Client _client;
  final String _baseUrl;
  final String _secretKey;

  Map<String, String> get _headers => <String, String>{
        'apikey': _secretKey,
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      };

  /// Cartas ATIVAS ainda nao verificadas, com o playerId do jogador.
  ///
  /// is_active exclui as cartas do provider LOCAL, que nao tem playerId da EA
  /// e nunca devem ser tocadas por este script.
  Future<List<_Card>> pendingCards({int? limit}) async {
    final cards = <_Card>[];
    const pageSize = 1000;
    var offset = 0;

    while (limit == null || cards.length < limit) {
      final want = limit == null
          ? pageSize
          : (limit - cards.length).clamp(1, pageSize);
      final uri = Uri.parse(
        '$_baseUrl/rest/v1/fc_player_cards'
        '?select=id,fc_players!inner(provider_player_id)'
        '&is_active=eq.true'
        '&card_image_checked_at=is.null'
        '&order=id.asc'
        '&offset=$offset&limit=$want',
      );
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode >= 400) {
        throw StateError(
          'falha ao ler a fila: ${response.statusCode} ${response.body}',
        );
      }
      final rows = jsonDecode(response.body) as List<dynamic>;
      if (rows.isEmpty) {
        break;
      }
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final player = row['fc_players'] as Map<String, dynamic>?;
        final playerId = player?['provider_player_id'] as String?;
        if (playerId != null && playerId.isNotEmpty) {
          cards.add(_Card(row['id'] as String, playerId));
        }
      }
      offset += rows.length;
      if (rows.length < want) {
        break;
      }
    }
    return cards;
  }

  /// Unica escrita do script. Passa pelo RPC de proposito: ele so alcanca
  /// card_image_url e card_image_checked_at.
  Future<Map<String, dynamic>> applyProbe({
    required List<String> foundIds,
    required List<String> foundUrls,
    required List<String> missingIds,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/rest/v1/rpc/apply_card_artwork_probe'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'p_found_ids': foundIds,
        'p_found_urls': foundUrls,
        'p_missing_ids': missingIds,
      }),
    );
    if (response.statusCode >= 400) {
      throw StateError(
        'falha ao gravar o lote: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
