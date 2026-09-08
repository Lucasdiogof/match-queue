// Importer SERVER-SIDE do catalogo de cartas EA FC (Etapa 11, Parte E).
//
// NUNCA rodar isto de dentro do app Flutter -- exige a service role key, que
// ignora RLS inteira. E um script standalone, chamado manualmente por quem
// tem acesso ao projeto Supabase, exatamente como um `npm run sync:...`
// rodaria num backend Node. Aqui e Dart puro (`dart run tool/sync_fc_cards.dart`)
// para nao introduzir um segundo runtime no repositorio.
//
// O QUE ELE FAZ
//   1. Le um CSV local (baixado a mao de um dataset comunitario -- ver
//      docs/card_provider_research.md; a decisao foi NUNCA fazer scraping ao
//      vivo de fut.gg/futbin/futwiz).
//   2. Resolve nacao/liga/clube por nome, criando a linha em fc_nations/
//      fc_leagues/fc_clubs se ainda nao existir (upsert por nome).
//   3. Faz upsert idempotente em fc_player_cards por (provider,
//      provider_card_id) -- rodar duas vezes com o mesmo CSV nunca duplica.
//   4. NUNCA apaga uma carta que sumiu do CSV: so marca is_active=false pra
//      tudo daquele provider que nao apareceu nesta rodada (feito ao final,
//      depois que todo upsert da rodada terminou).
//
// USO
//   dart run tool/sync_fc_cards.dart --csv=/caminho/para/dataset.csv \
//       --provider=COMMUNITY_CSV --game-version=FC27
//
// Variaveis de ambiente obrigatorias (nunca hardcoded, nunca no app):
//   SUPABASE_URL                 ex.: https://<project-ref>.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY    Project Settings -> API keys -> service_role
//
// MAPEAMENTO DE COLUNAS
// Datasets comunitarios variam o nome das colunas entre si. Em vez de
// acoplar a um dataset especifico, o script le um mapeamento de
// "nosso campo -> nome da coluna no CSV" de um arquivo JSON (--map=...),
// com um default razoavel (colunas em snake_case parecidas com as do
// FC26-DataHub/SoFIFA) que quem rodar deve conferir contra o CSV real antes
// de disparar para o banco -- por isso o --dry-run abaixo.
//
// --dry-run imprime quantas linhas seriam upsertadas/desativadas sem
// escrever nada -- rodar sempre antes do primeiro sync de verdade.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final options = _Args.parse(args);

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (supabaseUrl == null || serviceRoleKey == null) {
    stderr.writeln(
      'SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY precisam estar no ambiente. '
      'Nunca hardcode a service role key neste arquivo.',
    );
    exitCode = 1;
    return;
  }

  final csvFile = File(options.csvPath);
  if (!csvFile.existsSync()) {
    stderr.writeln('CSV nao encontrado: ${options.csvPath}');
    exitCode = 1;
    return;
  }

  final mapping = await _ColumnMapping.load(options.mapPath);
  final rows = _parseCsv(await csvFile.readAsString());
  if (rows.isEmpty) {
    stderr.writeln('CSV vazio.');
    return;
  }

  final header = rows.first;
  final headerIndex = <String, int>{
    for (var i = 0; i < header.length; i++) header[i].trim(): i,
  };

  final client = _SupabaseAdmin(
    baseUrl: supabaseUrl,
    serviceRoleKey: serviceRoleKey,
  );

  final seenProviderCardIds = <String>{};
  var cardsUpserted = 0;
  var cardsSkippedNoRating = 0;

  for (final row in rows.skip(1)) {
    String? col(String field) {
      final columnName = mapping.get(field);
      final index = headerIndex[columnName];
      if (index == null || index >= row.length) {
        return null;
      }
      final value = row[index].trim();
      return value.isEmpty ? null : value;
    }

    int? colInt(String field) => int.tryParse(col(field) ?? '');

    final providerCardId = col('provider_card_id') ?? col('player_name');
    final playerName = col('player_name');
    final rating = colInt('rating');

    // player_positions em datasets estilo sofifa vem como uma lista unica,
    // ex. "ST, LW, CF" -- a primeira e a posicao primaria, o resto sao as
    // alternativas. Ler primary_position e alternative_positions do mesmo
    // valor cru (como o mapeamento default faz) exige separar aqui; nunca
    // jogar a string toda em primary_position.
    final positionsRaw = col('primary_position');
    final positionsList = positionsRaw
        ?.split(RegExp(r'[|,/]'))
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    final primaryPosition = (positionsList == null || positionsList.isEmpty)
        ? null
        : positionsList.first;

    if (providerCardId == null ||
        playerName == null ||
        rating == null ||
        primaryPosition == null) {
      cardsSkippedNoRating++;
      continue;
    }

    final isGoalkeeper = primaryPosition.toUpperCase() == 'GK';

    final clubName = col('club_name');
    final leagueName = col('league_name');
    final nationName = col('nation_name');

    final clubId = clubName == null
        ? null
        : await client.upsertByName(
            table: 'fc_clubs',
            provider: options.provider,
            name: clubName,
            extra: <String, dynamic>{
              if (leagueName != null)
                'league_id': await client.upsertByName(
                  table: 'fc_leagues',
                  provider: options.provider,
                  name: leagueName,
                ),
            },
          );
    final leagueId = leagueName == null
        ? null
        : await client.upsertByName(
            table: 'fc_leagues',
            provider: options.provider,
            name: leagueName,
          );
    final nationId = nationName == null
        ? null
        : await client.upsertByName(
            table: 'fc_nations',
            provider: options.provider,
            name: nationName,
          );

    // alternative_positions mapeia pra mesma coluna player_positions no
    // default (dataset nao separa primaria de alternativas em colunas
    // distintas) -- reaproveita a lista ja quebrada acima, tirando a
    // primaria para nao duplicar.
    final alternativePositions = (positionsList == null || positionsList.length <= 1)
        ? const <String>[]
        : positionsList.skip(1).toList(growable: false);

    final playstylesRaw = col('playstyles');
    final playstyles = playstylesRaw == null
        ? const <String>[]
        : playstylesRaw
              .split(RegExp(r'[|,/]'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList(growable: false);

    final playerRolesRaw = col('player_roles');
    final playerRoles = playerRolesRaw == null
        ? const <String>[]
        : playerRolesRaw
              .split(RegExp(r'[|,/]'))
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList(growable: false);

    final payload = <String, dynamic>{
      'provider': options.provider,
      'provider_card_id': providerCardId,
      'game_version': options.gameVersion,
      'player_name': playerName,
      'common_name': col('common_name'),
      'rating': rating,
      'primary_position': primaryPosition.toUpperCase(),
      'alternative_positions': alternativePositions,
      'pace': isGoalkeeper ? null : colInt('pace'),
      'shooting': isGoalkeeper ? null : colInt('shooting'),
      'passing': isGoalkeeper ? null : colInt('passing'),
      'dribbling': isGoalkeeper ? null : colInt('dribbling'),
      'defending': isGoalkeeper ? null : colInt('defending'),
      'physical': isGoalkeeper ? null : colInt('physical'),
      'gk_diving': isGoalkeeper ? colInt('gk_diving') : null,
      'gk_handling': isGoalkeeper ? colInt('gk_handling') : null,
      'gk_kicking': isGoalkeeper ? colInt('gk_kicking') : null,
      'gk_reflexes': isGoalkeeper ? colInt('gk_reflexes') : null,
      'gk_speed': isGoalkeeper ? colInt('gk_speed') : null,
      'gk_positioning': isGoalkeeper ? colInt('gk_positioning') : null,
      'skill_moves': colInt('skill_moves'),
      'weak_foot': colInt('weak_foot'),
      'playstyles': playstyles,
      'height_cm': colInt('height_cm'),
      'preferred_foot': col('preferred_foot')?.toUpperCase(),
      'player_roles': playerRoles,
      'rarity': col('rarity'),
      'player_image_url': col('player_image_url'),
      'card_image_url': col('card_image_url'),
      'club_name': clubName,
      'league_name': leagueName,
      'nation_name': nationName,
      'club_id': clubId,
      'league_id': leagueId,
      'nation_id': nationId,
      'card_type': col('card_type'),
      'is_active': true,
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      'source_url': options.sourceUrl,
    };

    seenProviderCardIds.add(providerCardId);

    if (options.dryRun) {
      cardsUpserted++;
      continue;
    }

    await client.upsert(
      table: 'fc_player_cards',
      onConflict: 'provider,provider_card_id',
      row: payload,
    );
    cardsUpserted++;
  }

  stdout.writeln(
    '${options.dryRun ? '[dry-run] ' : ''}Cartas processadas: $cardsUpserted '
    '(puladas por falta de campo obrigatorio: $cardsSkippedNoRating)',
  );

  if (!options.dryRun) {
    final deactivated = await client.deactivateMissing(
      table: 'fc_player_cards',
      provider: options.provider,
      keepProviderCardIds: seenProviderCardIds,
    );
    stdout.writeln(
      'Cartas is_active=false por nao aparecerem nesta rodada: $deactivated',
    );
  }
}

class _Args {
  _Args({
    required this.csvPath,
    required this.provider,
    required this.gameVersion,
    required this.mapPath,
    required this.dryRun,
    this.sourceUrl,
  });

  final String csvPath;
  final String provider;
  final String gameVersion;
  final String? mapPath;
  final bool dryRun;
  final String? sourceUrl;

  static _Args parse(List<String> args) {
    String? csvPath;
    var provider = 'COMMUNITY_CSV';
    var gameVersion = 'FC27';
    String? mapPath;
    var dryRun = false;
    String? sourceUrl;

    for (final arg in args) {
      if (arg.startsWith('--csv=')) {
        csvPath = arg.substring('--csv='.length);
      } else if (arg.startsWith('--provider=')) {
        provider = arg.substring('--provider='.length);
      } else if (arg.startsWith('--game-version=')) {
        gameVersion = arg.substring('--game-version='.length);
      } else if (arg.startsWith('--map=')) {
        mapPath = arg.substring('--map='.length);
      } else if (arg.startsWith('--source-url=')) {
        sourceUrl = arg.substring('--source-url='.length);
      } else if (arg == '--dry-run') {
        dryRun = true;
      }
    }

    if (csvPath == null) {
      stderr.writeln(
        'Uso: dart run tool/sync_fc_cards.dart --csv=<path> [--provider=...] [--dry-run]',
      );
      exit(1);
    }

    return _Args(
      csvPath: csvPath,
      provider: provider,
      gameVersion: gameVersion,
      mapPath: mapPath,
      dryRun: dryRun,
      sourceUrl: sourceUrl,
    );
  }
}

/// Mapeamento "campo nosso -> coluna do CSV". O default e um palpite
/// razoavel para datasets no estilo FC26-DataHub/SoFIFA -- CONFERIR contra
/// o cabecalho real do CSV antes do primeiro sync (rodar com --dry-run e
/// olhar se `cardsSkippedNoRating` bate com o esperado).
class _ColumnMapping {
  _ColumnMapping(this._overrides);

  final Map<String, String> _overrides;

  static const Map<String, String> _defaults = <String, String>{
    'provider_card_id': 'sofifa_id',
    'player_name': 'long_name',
    'common_name': 'short_name',
    'rating': 'overall',
    'primary_position': 'player_positions',
    'alternative_positions': 'player_positions',
    'pace': 'pace',
    'shooting': 'shooting',
    'passing': 'passing',
    'dribbling': 'dribbling',
    'defending': 'defending',
    'physical': 'physic',
    'gk_diving': 'goalkeeping_diving',
    'gk_handling': 'goalkeeping_handling',
    'gk_kicking': 'goalkeeping_kicking',
    'gk_reflexes': 'goalkeeping_reflexes',
    'gk_speed': 'goalkeeping_speed',
    'gk_positioning': 'goalkeeping_positioning',
    'skill_moves': 'skill_moves',
    'weak_foot': 'weak_foot',
    'playstyles': 'player_traits',
    'height_cm': 'height_cm',
    'preferred_foot': 'preferred_foot',
    'player_roles': 'player_roles',
    'rarity': 'rarity',
    'player_image_url': 'player_face_url',
    'card_image_url': 'player_face_url',
    'club_name': 'club_name',
    'league_name': 'league_name',
    'nation_name': 'nationality_name',
    'card_type': 'card_type',
  };

  static Future<_ColumnMapping> load(String? path) async {
    if (path == null) {
      return _ColumnMapping(_defaults);
    }
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln(
        '--map aponta para arquivo inexistente: $path -- usando default.',
      );
      return _ColumnMapping(_defaults);
    }
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _ColumnMapping(<String, String>{
      ..._defaults,
      for (final entry in decoded.entries) entry.key: '${entry.value}',
    });
  }

  String get(String field) => _overrides[field] ?? _defaults[field] ?? field;
}

/// Cliente HTTP fino contra o PostgREST do Supabase, autenticado com a
/// service role key -- nunca importado pelo app Flutter (vive so em tool/).
class _SupabaseAdmin {
  _SupabaseAdmin({required this.baseUrl, required this.serviceRoleKey});

  final String baseUrl;
  final String serviceRoleKey;

  Map<String, String> get _headers => <String, String>{
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Content-Type': 'application/json',
  };

  /// Upsert por nome (nacao/liga/clube). O "provider" so serve pra rastrear
  /// origem; o conflito real e por nome, pra nao duplicar "Brasil" a cada
  /// linha de carta que cita o mesmo pais.
  Future<String?> upsertByName({
    required String table,
    required String provider,
    required String name,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    final existing = await http.get(
      Uri.parse(
        '$baseUrl/rest/v1/$table?name=eq.${Uri.encodeComponent(name)}&select=id&limit=1',
      ),
      headers: _headers,
    );
    final rows = jsonDecode(existing.body) as List<dynamic>;
    if (rows.isNotEmpty) {
      return (rows.first as Map<String, dynamic>)['id'] as String?;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/rest/v1/$table'),
      headers: <String, String>{..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(<String, dynamic>{
        'provider': provider,
        'name': name,
        ...extra,
      }),
    );
    final created = jsonDecode(response.body);
    if (created is List && created.isNotEmpty) {
      return (created.first as Map<String, dynamic>)['id'] as String?;
    }
    return null;
  }

  Future<void> upsert({
    required String table,
    required String onConflict,
    required Map<String, dynamic> row,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rest/v1/$table?on_conflict=$onConflict'),
      headers: <String, String>{
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode(row),
    );
    if (response.statusCode >= 300) {
      stderr.writeln(
        'Falha ao upsertar $table: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Marca is_active=false para toda carta DAQUELE provider que nao
  /// apareceu nesta rodada de sync -- nunca deleta.
  Future<int> deactivateMissing({
    required String table,
    required String provider,
    required Set<String> keepProviderCardIds,
  }) async {
    if (keepProviderCardIds.isEmpty) {
      return 0;
    }
    final idsList = keepProviderCardIds.map((id) => '"$id"').join(',');
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/rest/v1/$table?provider=eq.$provider'
        '&provider_card_id=not.in.($idsList)&is_active=eq.true',
      ),
      headers: <String, String>{..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(<String, dynamic>{'is_active': false}),
    );
    final updated = jsonDecode(response.body);
    return updated is List ? updated.length : 0;
  }
}

/// Parser CSV simples (RFC 4180: campos entre aspas podem conter virgula e
/// quebra de linha). Sem dependencia de package:csv de proposito -- um
/// script de sync nao precisa de mais uma dependencia no pubspec principal.
List<List<String>> _parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var insideQuotes = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  while (i < content.length) {
    final char = content[i];
    if (insideQuotes) {
      if (char == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        insideQuotes = false;
        i++;
        continue;
      }
      field.write(char);
      i++;
      continue;
    }

    switch (char) {
      case '"':
        insideQuotes = true;
        i++;
      case ',':
        endField();
        i++;
      case '\r':
        i++;
      case '\n':
        endRow();
        i++;
      default:
        field.write(char);
        i++;
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}
