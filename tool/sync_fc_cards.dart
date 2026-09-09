// Importer SERVER-SIDE do catalogo de cartas EA FC (Etapa 11, Parte E;
// atualizado na etapa de separacao jogador/carta).
//
// NUNCA rodar isto de dentro do app Flutter -- exige a service role key, que
// ignora RLS inteira. E um script standalone, chamado manualmente por quem
// tem acesso ao projeto Supabase, exatamente como um `npm run sync:...`
// rodaria num backend Node. Aqui e Dart puro (`dart run tool/sync_fc_cards.dart`)
// para nao introduzir um segundo runtime no repositorio.
//
// NUNCA acessa rede externa nenhuma (fut.gg/futbin/futwiz/wefut ou qualquer
// outro site) -- so le um arquivo LOCAL (CSV ou JSON) que quem roda baixou
// a mao de onde quiser. Decisao ja tomada e comunicada: WeFUT foi recusado
// como fonte porque seu robots.txt desautoriza crawlers automatizados. Este
// script e deliberadamente cego a qual foi a origem do arquivo -- so importa
// --provider=<nome> que o operador escolhe.
//
// O QUE ELE FAZ
//   1. Le um arquivo local: CSV (formato historico) ou JSON (array de
//      objetos). Formato inferido pela extensao, ou forcado com --format=.
//   2. Normaliza cada linha/item para o contrato de tool/fc_import_contract.dart
//      (ExternalFcPlayer/ExternalFcCard) -- nenhuma logica de provider
//      especifico vaza dali pra frente.
//   3. Se o item declarar provider_player_id: upsert em fc_players primeiro
//      (idempotente por (provider, game_version, provider_player_id)),
//      pega o id interno.
//   4. Upsert idempotente em fc_player_cards por (provider, provider_card_id),
//      com fc_player_id apontando pro player resolvido no passo 3 (nulo se o
//      item nao declarou provider_player_id). Roda duas vezes com o mesmo
//      arquivo nunca duplica.
//   5. NUNCA apaga uma carta que sumiu do arquivo. So marca is_active=false
//      pra tudo daquele provider que nao apareceu nesta rodada -- e so
//      quando --full-catalog e passado (feito ao final, depois que todo
//      upsert da rodada terminou). Sem essa flag, uma rodada com arquivo
//      PARCIAL nunca desativa nada -- e o default, de proposito.
//
// USO
//   dart run tool/sync_fc_cards.dart --file=tool/data/algo.json \
//       --provider=MEU_PROVIDER --game-version=FC27 [--dry-run]
//   dart run tool/sync_fc_cards.dart --csv=/caminho/dataset.csv \
//       --provider=COMMUNITY_CSV --game-version=FC27   (forma antiga, ainda
//                                                        suportada)
//
// Variaveis de ambiente obrigatorias (nunca hardcoded, nunca no app, nunca
// impressas por este script):
//   SUPABASE_URL           ex.: https://<project-ref>.supabase.co
//   SUPABASE_SECRET_KEY    Project Settings -> API keys -> secret key (nome
//                          atual da chave que ignora RLS no painel do
//                          Supabase). SUPABASE_SERVICE_ROLE_KEY continua
//                          aceita como fallback legado (nome antigo da mesma
//                          chave), igual o app Flutter aceita
//                          SUPABASE_ANON_KEY como fallback de
//                          SUPABASE_PUBLISHABLE_KEY (docs/supabase_setup.md).
//
// MAPEAMENTO DE CAMPOS
// Fontes variam o nome do campo entre si. Em vez de acoplar a uma fonte
// especifica, o script le um mapeamento de "nosso campo -> nome do campo no
// arquivo" de um JSON (--map=...). Default para CSV: nomes no estilo
// FC26-DataHub/SoFIFA (o unico dataset ja pesquisado -- ver
// docs/card_provider_research.md). Default para JSON: identidade (o arquivo
// ja usa os nomes canonicos abaixo) -- e o formato pensado para "qualquer
// fonte futura", entao nao assume convencao de coluna nenhuma.
//
// Campos canonicos aceitos (mesma lista serve pra jogador e carta; um item
// pode ter so um subconjunto):
//   provider_player_id, provider_card_id, player_name, common_name, rating,
//   primary_position, alternative_positions, pace, shooting, passing,
//   dribbling, defending, physical, gk_diving, gk_handling, gk_kicking,
//   gk_reflexes, gk_speed, gk_positioning, skill_moves, weak_foot,
//   playstyles, playstyles_plus, detailed_stats, accelerate_rate,
//   raw_metadata, height_cm, preferred_foot, player_roles, rarity,
//   player_image_url, card_image_url, club_name, league_name, nation_name,
//   card_type, source_url
//
// source_url por linha (Etapa 17B, dataset Wrexist): quando o arquivo ja
// declara uma URL de origem por jogador/carta, ela tem prioridade sobre
// --source-url (que continua servindo de fallback global para fontes que
// nao trazem isso por linha).
//
// alternative_positions e uma coluna PROPRIA quando a fonte ja separa
// primaria de alternativas (WEFUT, EA) -- so cai no split combinado de um
// unico campo ("ST, LW, CF") quando o mapeamento de primary_position e
// alternative_positions aponta pra MESMA coluna de origem (estilo sofifa).
//
// detailed_stats/raw_metadata esperam uma celula com JSON serializado
// (objeto) quando a fonte trouxer -- decodificados linha a linha; falha de
// parse vira warning no resumo, nunca aborta a linha.
//
// --dry-run imprime quantas linhas seriam upsertadas/desativadas sem
// escrever nada -- rodar sempre antes do primeiro sync de verdade. E
// parse-only de verdade: nao exige nenhuma credencial do Supabase.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'fc_import_contract.dart';

Future<void> main(List<String> args) async {
  final options = _Args.parse(args);

  _SupabaseAdmin? client;
  if (!options.dryRun) {
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final secretKey =
        Platform.environment['SUPABASE_SECRET_KEY'] ??
        Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
    if (supabaseUrl == null || secretKey == null) {
      stderr.writeln(
        'SUPABASE_URL e SUPABASE_SECRET_KEY (ou, como fallback legado, '
        'SUPABASE_SERVICE_ROLE_KEY) precisam estar no ambiente para rodar '
        'sem --dry-run. Nunca hardcode essa chave neste arquivo.',
      );
      exitCode = 1;
      return;
    }
    client = _SupabaseAdmin(baseUrl: supabaseUrl, secretKey: secretKey);
  }

  final file = File(options.filePath);
  if (!file.existsSync()) {
    stderr.writeln('Arquivo nao encontrado: ${options.filePath}');
    exitCode = 1;
    return;
  }

  final mapping = await _FieldMapping.load(options.mapPath, options.format);
  final rawRows = options.format == _InputFormat.json
      ? _parseJson(await file.readAsString())
      : _parseCsvAsRows(await file.readAsString());
  if (rawRows.isEmpty) {
    stderr.writeln('Arquivo vazio ou sem linhas de dados.');
    return;
  }

  final existingProviderCardIds = client == null
      ? <String>{}
      : await client.fetchExistingProviderIds(
          table: 'fc_player_cards',
          idColumn: 'provider_card_id',
          provider: options.provider,
        );

  final seenProviderCardIds = <String>{};
  final dryRunClubs = <String>{};
  final dryRunLeagues = <String>{};
  final dryRunNations = <String>{};
  // Chave (provider:gameVersion:providerPlayerId) de todo jogador que o
  // arquivo referencia -- usado para contar jogadores DISTINTOS mesmo
  // quando o mesmo atleta aparece em N linhas (N cartas), tanto em
  // --dry-run quanto no sync de verdade.
  final touchedPlayerKeys = <String>{};
  var rowsRead = 0;
  var rowsValid = 0;
  var rowsInvalid = 0;
  var rowsInserted = 0;
  var rowsUpdated = 0;
  var rowsFailed = 0;
  // Linha com identidade de jogador mas SEM nenhum sinal de carta/item real
  // (nem provider_card_id proprio, nem card_type, nem rarity) -- vira
  // SOMENTE fc_players, nunca uma linha fc_player_cards inventada.
  var playerOnlyCount = 0;
  // Linha com provider_card_id proprio -- essa sim vira fc_player_cards
  // (alem de fc_players quando providerPlayerId existir).
  var realCardCount = 0;
  // Diagnostico: linha com card_type/rarity mas SEM provider_card_id --
  // nao vira carta (falta identidade), mas vale avisar que a fonte parece
  // descrever cartas sem dar um id pra elas.
  var cardMetadataWithoutIdCount = 0;
  // Celula de detailed_stats/raw_metadata que nao decodificou como JSON --
  // vira aviso, nunca aborta a linha.
  var malformedJsonFieldCount = 0;
  var rowsWithAlternativePositions = 0;

  for (final rawRow in rawRows) {
    rowsRead++;
    String? col(String field) => _stringOrNull(rawRow[mapping.get(field)]);
    int? colInt(String field) => int.tryParse(col(field) ?? '');
    List<String> colList(String field) {
      final raw = col(field);
      return raw == null
          ? const <String>[]
          : raw
                .split(RegExp(r'[|,/]'))
                .map((p) => p.trim())
                .where((p) => p.isNotEmpty)
                .toList(growable: false);
    }

    // Alguns campos (detailed_stats, raw_metadata) chegam como uma celula
    // com JSON serializado dentro (fontes tipo WEFUT/EA). Falha de parse
    // vira warning, nao aborta a linha -- o resto do card continua valido.
    Map<String, dynamic>? colJsonObject(String field) {
      final raw = col(field);
      if (raw == null) return null;
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } on FormatException {
        malformedJsonFieldCount++;
        return null;
      }
    }

    // Duas formas de fonte coexistem: datasets estilo sofifa descrevem
    // posicao como uma lista unica ("ST, LW, CF", primeira = primaria,
    // resto = alternativas) na MESMA coluna mapeada para primary_position;
    // outras fontes (WEFUT, EA) ja separam primary_position e
    // alternative_positions em colunas distintas. So cai no split combinado
    // quando o mapeamento das duas chaves resolve pra a MESMA coluna de
    // origem -- caso contrario, cada uma e lida da sua propria coluna.
    // Combinado quando as duas chaves resolvem pra mesma coluna (sofifa
    // default) OU quando a coluna resolvida para alternative_positions nem
    // existe no arquivo (--map customizado que so pensou em
    // primary_position) -- nesse segundo caso cai pro derivado em vez de
    // silenciosamente nunca achar nenhuma alternativa.
    final alternativePositionsColumn = mapping.get('alternative_positions');
    final combinedPositionSource =
        mapping.get('primary_position') == alternativePositionsColumn ||
        !rawRow.containsKey(alternativePositionsColumn);
    final List<String> primaryPositionCandidates;
    final List<String> alternativePositionCandidates;
    if (combinedPositionSource) {
      final positionsList = colList('primary_position');
      primaryPositionCandidates = positionsList.isEmpty
          ? const <String>[]
          : <String>[positionsList.first];
      alternativePositionCandidates = positionsList.length <= 1
          ? const <String>[]
          : positionsList.skip(1).toList(growable: false);
    } else {
      final primaryRaw = col('primary_position');
      primaryPositionCandidates = primaryRaw == null
          ? const <String>[]
          : <String>[primaryRaw];
      alternativePositionCandidates = colList('alternative_positions');
    }
    final primaryPosition = primaryPositionCandidates.isEmpty
        ? null
        : primaryPositionCandidates.first.toUpperCase();
    final alternativePositions = alternativePositionCandidates
        .map((p) => p.toUpperCase())
        .toList(growable: false);
    if (alternativePositions.isNotEmpty) rowsWithAlternativePositions++;

    final playerName = col('player_name');
    final rating = colInt('rating');
    final providerPlayerId = col('provider_player_id');
    // Unica evidencia aceita de "isto e uma carta/item real":
    // provider_card_id proprio, nao-vazio. card_type/rarity sao ATRIBUTOS
    // da carta, nunca identidade -- sozinhos nao bastam, porque nao existe
    // chave externa idempotente pra upsertar sem eles (nunca inventamos um
    // id sintetico a partir de player id/nome/rating/indice de linha).
    final hasCardId = col('provider_card_id') != null;
    // So para diagnostico: item que descreve uma carta (tem card_type ou
    // rarity) mas nao declara provider_card_id -- nao vira fc_player_cards,
    // mas fica registrado no resumo do dry-run como aviso, nao erro.
    final hasCardMetadataWithoutId =
        !hasCardId && (col('card_type') != null || col('rarity') != null);

    if (playerName == null || primaryPosition == null) {
      rowsInvalid++;
      continue;
    }
    if (hasCardId && rating == null) {
      // Carta real sem rating nao e um dado utilizavel.
      rowsInvalid++;
      continue;
    }
    if (!hasCardId && providerPlayerId == null) {
      // Nem identidade de carta, nem id de jogador -- nada identificavel
      // pra criar em fc_players nem em fc_player_cards.
      rowsInvalid++;
      continue;
    }
    rowsValid++;
    if (hasCardMetadataWithoutId) cardMetadataWithoutIdCount++;

    final isGoalkeeper = primaryPosition == 'GK';
    final clubName = col('club_name');
    final leagueName = col('league_name');
    final nationName = col('nation_name');

    if (clubName != null) dryRunClubs.add(clubName);
    if (leagueName != null) dryRunLeagues.add(leagueName);
    if (nationName != null) dryRunNations.add(nationName);

    String? clubId;
    String? leagueId;
    String? nationId;
    if (client != null) {
      leagueId = leagueName == null
          ? null
          : await client.upsertByName(
              table: 'fc_leagues',
              provider: options.provider,
              name: leagueName,
            );
      clubId = clubName == null
          ? null
          : await client.upsertByName(
              table: 'fc_clubs',
              provider: options.provider,
              name: clubName,
              extra: <String, dynamic>{'league_id': ?leagueId},
            );
      nationId = nationName == null
          ? null
          : await client.upsertByName(
              table: 'fc_nations',
              provider: options.provider,
              name: nationName,
            );
    }

    // fc_players e upsertado sempre que o item declarar identidade de
    // jogador -- independente de tambem ser uma carta real ou nao.
    String? fcPlayerId;
    if (providerPlayerId != null) {
      touchedPlayerKeys.add(
        '${options.provider}:${options.gameVersion}:$providerPlayerId',
      );
      final externalPlayer = ExternalFcPlayer(
        provider: options.provider,
        gameVersion: options.gameVersion,
        providerPlayerId: providerPlayerId,
        name: playerName,
        commonName: col('common_name'),
        nationName: nationName,
        clubName: clubName,
        leagueName: leagueName,
        primaryPosition: primaryPosition,
        alternativePositions: alternativePositions,
        imageUrl: col('player_image_url'),
        heightCm: colInt('height_cm'),
        preferredFoot: col('preferred_foot')?.toUpperCase(),
        weakFoot: colInt('weak_foot'),
        skillMoves: colInt('skill_moves'),
      );

      if (client != null) {
        fcPlayerId = await client.upsertFcPlayer(
          provider: externalPlayer.provider,
          gameVersion: externalPlayer.gameVersion,
          providerPlayerId: externalPlayer.providerPlayerId,
          row: externalPlayer.toFcPlayersRow(
            nationId: nationId,
            clubId: clubId,
            leagueId: leagueId,
            syncedAt: DateTime.now().toUtc(),
          ),
        );
      }
    }

    if (!hasCardId) {
      // Sem provider_card_id: fc_players ja foi upsertado acima (se
      // providerPlayerId existia). NUNCA criar uma linha em
      // fc_player_cards so para satisfazer o picker, e NUNCA so por causa
      // de card_type/rarity sozinhos -- sem identidade externa, nao ha
      // chave pra upsertar de forma idempotente.
      playerOnlyCount++;
      continue;
    }
    realCardCount++;

    final providerCardId = col('provider_card_id') ?? playerName;
    final externalCard = ExternalFcCard(
      provider: options.provider,
      gameVersion: options.gameVersion,
      providerCardId: providerCardId,
      providerPlayerId: providerPlayerId,
      playerName: playerName,
      commonName: col('common_name'),
      rating: rating!,
      primaryPosition: primaryPosition,
      alternativePositions: alternativePositions,
      pace: isGoalkeeper ? null : colInt('pace'),
      shooting: isGoalkeeper ? null : colInt('shooting'),
      passing: isGoalkeeper ? null : colInt('passing'),
      dribbling: isGoalkeeper ? null : colInt('dribbling'),
      defending: isGoalkeeper ? null : colInt('defending'),
      physical: isGoalkeeper ? null : colInt('physical'),
      gkDiving: isGoalkeeper ? colInt('gk_diving') : null,
      gkHandling: isGoalkeeper ? colInt('gk_handling') : null,
      gkKicking: isGoalkeeper ? colInt('gk_kicking') : null,
      gkReflexes: isGoalkeeper ? colInt('gk_reflexes') : null,
      gkSpeed: isGoalkeeper ? colInt('gk_speed') : null,
      gkPositioning: isGoalkeeper ? colInt('gk_positioning') : null,
      skillMoves: colInt('skill_moves'),
      weakFoot: colInt('weak_foot'),
      playstyles: colList('playstyles'),
      playstylesPlus: colList('playstyles_plus'),
      detailedStats: colJsonObject('detailed_stats'),
      accelerateRate: col('accelerate_rate'),
      rawMetadata: colJsonObject('raw_metadata'),
      heightCm: colInt('height_cm'),
      preferredFoot: col('preferred_foot')?.toUpperCase(),
      playerRoles: colList('player_roles'),
      rarity: col('rarity'),
      cardType: col('card_type'),
      playerImageUrl: col('player_image_url'),
      cardImageUrl: col('card_image_url') ?? col('player_image_url'),
      clubName: clubName,
      leagueName: leagueName,
      nationName: nationName,
      sourceUrl: col('source_url') ?? options.sourceUrl,
    );

    final payload = externalCard.toFcPlayerCardsRow(
      clubId: clubId,
      leagueId: leagueId,
      nationId: nationId,
      fcPlayerId: fcPlayerId,
      syncedAt: DateTime.now().toUtc(),
    );

    seenProviderCardIds.add(providerCardId);

    if (options.dryRun) {
      if (existingProviderCardIds.contains(providerCardId)) {
        rowsUpdated++;
      } else {
        rowsInserted++;
      }
      continue;
    }

    final wasExisting = existingProviderCardIds.contains(providerCardId);
    final ok = await client!.upsert(
      table: 'fc_player_cards',
      onConflict: 'provider,provider_card_id',
      row: payload,
    );
    if (!ok) {
      rowsFailed++;
    } else if (wasExisting) {
      rowsUpdated++;
    } else {
      rowsInserted++;
    }
  }

  stdout.writeln('${options.dryRun ? '[DRY-RUN] ' : ''}Resultado do sync:');
  stdout.writeln('  formato:        ${options.format.name}');
  stdout.writeln('  lidos:          $rowsRead');
  stdout.writeln('  validos:        $rowsValid');
  stdout.writeln('  invalidos:      $rowsInvalid (campo obrigatorio ausente)');
  stdout.writeln(
    '  players (fc_players) distintos: ${touchedPlayerKeys.length}',
  );
  stdout.writeln('  cards reais (fc_player_cards):  $realCardCount');
  stdout.writeln('  player-only (so fc_players):    $playerOnlyCount');
  stdout.writeln(
    '  linhas com posicoes alternativas: $rowsWithAlternativePositions',
  );
  if (cardMetadataWithoutIdCount > 0) {
    stdout.writeln(
      '  aviso: card metadata sem identidade (card_type/rarity sem '
      'provider_card_id): $cardMetadataWithoutIdCount -- viraram '
      'player-only, nao card',
    );
  }
  if (malformedJsonFieldCount > 0) {
    stdout.writeln(
      '  aviso: campos JSON malformados (detailed_stats/raw_metadata) '
      'ignorados: $malformedJsonFieldCount',
    );
  }
  stdout.writeln(
    '  cards -- inseridos: $rowsInserted, atualizados: $rowsUpdated, '
    'falhas: $rowsFailed',
  );
  if (options.dryRun) {
    stdout.writeln('  nations distintas no arquivo: ${dryRunNations.length}');
    stdout.writeln('  leagues distintas no arquivo: ${dryRunLeagues.length}');
    stdout.writeln('  clubs distintos no arquivo:   ${dryRunClubs.length}');
  }

  if (client != null) {
    if (options.fullCatalog) {
      final deactivated = await client.deactivateMissing(
        table: 'fc_player_cards',
        idColumn: 'provider_card_id',
        provider: options.provider,
        keepIds: seenProviderCardIds,
      );
      stdout.writeln(
        'Cartas is_active=false por nao aparecerem nesta rodada: $deactivated',
      );
    } else {
      stdout.writeln(
        'Sem --full-catalog: nenhuma carta foi desativada por ausencia '
        'nesta rodada (arquivo tratado como parcial, de proposito).',
      );
    }
  }
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value is String ? value : '$value';
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

enum _InputFormat { csv, json }

class _Args {
  _Args({
    required this.filePath,
    required this.format,
    required this.provider,
    required this.gameVersion,
    required this.mapPath,
    required this.dryRun,
    required this.fullCatalog,
    this.sourceUrl,
  });

  final String filePath;
  final _InputFormat format;
  final String provider;
  final String gameVersion;
  final String? mapPath;
  final bool dryRun;
  final bool fullCatalog;
  final String? sourceUrl;

  static _Args parse(List<String> args) {
    String? filePath;
    _InputFormat? forcedFormat;
    var isLegacyCsvFlag = false;
    var provider = 'COMMUNITY_CSV';
    var gameVersion = 'FC27';
    String? mapPath;
    var dryRun = false;
    var fullCatalog = false;
    String? sourceUrl;

    for (final arg in args) {
      if (arg.startsWith('--file=')) {
        filePath = arg.substring('--file='.length);
      } else if (arg.startsWith('--csv=')) {
        filePath = arg.substring('--csv='.length);
        isLegacyCsvFlag = true;
      } else if (arg.startsWith('--format=')) {
        final value = arg.substring('--format='.length).toLowerCase();
        forcedFormat = value == 'json' ? _InputFormat.json : _InputFormat.csv;
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
      } else if (arg == '--full-catalog') {
        fullCatalog = true;
      }
    }

    if (filePath == null) {
      stderr.writeln(
        'Uso: dart run tool/sync_fc_cards.dart --file=<path> '
        '[--provider=...] [--game-version=...] [--format=csv|json] '
        '[--map=...] [--dry-run] [--full-catalog]\n'
        '(--csv=<path> continua aceito como forma antiga, equivalente a '
        '--file=<path> --format=csv)\n'
        '--full-catalog autoriza desativar (is_active=false) cartas do '
        'provider ausentes desta rodada -- default e NAO desativar nada, '
        'pra um arquivo parcial nunca apagar o resto do catalogo por engano.',
      );
      exit(1);
    }

    final format =
        forcedFormat ??
        (isLegacyCsvFlag
            ? _InputFormat.csv
            : (filePath.toLowerCase().endsWith('.json')
                  ? _InputFormat.json
                  : _InputFormat.csv));

    return _Args(
      filePath: filePath,
      format: format,
      provider: provider,
      gameVersion: gameVersion,
      mapPath: mapPath,
      dryRun: dryRun,
      fullCatalog: fullCatalog,
      sourceUrl: sourceUrl,
    );
  }
}

/// Mapeamento "campo nosso -> chave no arquivo de origem".
///
/// CSV: default no estilo FC26-DataHub/SoFIFA (o unico dataset ja
/// pesquisado -- docs/card_provider_research.md), porque cabecalhos de CSV
/// variam por fonte e precisam de um palpite razoavel. CONFERIR contra o
/// cabecalho real antes do primeiro sync (--dry-run mostra quantas linhas
/// seriam ignoradas por falta de campo obrigatorio).
///
/// JSON: default identidade -- o formato pensado para "qualquer fonte
/// futura" ja usa os nomes canonicos, entao nao ha cabecalho pra adivinhar.
class _FieldMapping {
  _FieldMapping(this._overrides);

  final Map<String, String> _overrides;

  static const Map<String, String> _csvDefaults = <String, String>{
    // sofifa_id identifica o ATLETA (persiste ano a ano no ecossistema
    // sofifa) -- e identidade de jogador, nunca de carta/versao. Este
    // dataset nao declara provider_card_id nenhum de proposito: e
    // exatamente o caso "so identidade base", sem sinal de carta real (ver
    // docs/card_provider_research.md e a correcao de semantica desta
    // etapa). Nao mapear nada para provider_card_id aqui.
    'provider_player_id': 'sofifa_id',
    'player_name': 'long_name',
    'common_name': 'short_name',
    'rating': 'overall',
    // Sofifa descreve posicao como uma lista unica na MESMA coluna --
    // primary_position e alternative_positions apontam pro mesmo campo de
    // proposito, e e exatamente essa igualdade que sync_fc_cards.dart usa
    // pra decidir entre split combinado (este caso) e colunas separadas
    // (fontes que ja vem com primary/alternative distintos, ex. WEFUT/EA).
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

  static Future<_FieldMapping> load(String? path, _InputFormat format) async {
    final defaults = format == _InputFormat.csv
        ? _csvDefaults
        : const <String, String>{};
    if (path == null) {
      return _FieldMapping(defaults);
    }
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln(
        '--map aponta para arquivo inexistente: $path -- usando default.',
      );
      return _FieldMapping(defaults);
    }
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return _FieldMapping(<String, String>{
      ...defaults,
      for (final entry in decoded.entries) entry.key: '${entry.value}',
    });
  }

  /// Para JSON sem override, cai no proprio nome do campo (identidade) --
  /// para CSV sem override e sem default conhecido, tambem cai no proprio
  /// nome (comportamento historico: aceita coluna com o nome canonico
  /// literal, ex. `provider_player_id`, mesmo fora dos defaults do dataset
  /// ja pesquisado).
  String get(String field) => _overrides[field] ?? field;
}

/// Parser CSV simples (RFC 4180: campos entre aspas podem conter virgula e
/// quebra de linha). Sem dependencia de package:csv de proposito -- um
/// script de sync nao precisa de mais uma dependencia no pubspec principal.
List<Map<String, dynamic>> _parseCsvAsRows(String content) {
  final rows = _parseCsv(content);
  if (rows.isEmpty) return const <Map<String, dynamic>>[];
  final header = rows.first;
  return <Map<String, dynamic>>[
    for (final row in rows.skip(1))
      <String, dynamic>{
        for (var i = 0; i < header.length; i++)
          header[i].trim(): i < row.length ? row[i] : null,
      },
  ];
}

List<Map<String, dynamic>> _parseJson(String content) {
  final decoded = jsonDecode(content);
  if (decoded is! List) {
    stderr.writeln('JSON invalido: esperado um array de objetos no topo.');
    return const <Map<String, dynamic>>[];
  }
  return <Map<String, dynamic>>[
    for (final item in decoded)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}

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

/// Cliente HTTP fino contra o PostgREST do Supabase, autenticado com a
/// secret key -- nunca importado pelo app Flutter (vive so em tool/).
class _SupabaseAdmin {
  _SupabaseAdmin({required this.baseUrl, required this.secretKey});

  final String baseUrl;
  final String secretKey;

  Map<String, String> get _headers => <String, String>{
    'apikey': secretKey,
    'Authorization': 'Bearer $secretKey',
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

  /// Upsert de um atleta base por (provider, game_version,
  /// provider_player_id). Mesmo padrao de `upsert`, mas precisa devolver o
  /// id gerado/existente para a carta linkar `fc_player_id`.
  Future<String?> upsertFcPlayer({
    required String provider,
    required String gameVersion,
    required String providerPlayerId,
    required Map<String, dynamic> row,
  }) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/rest/v1/fc_players'
        '?on_conflict=provider,game_version,provider_player_id',
      ),
      headers: <String, String>{
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: jsonEncode(row),
    );
    if (response.statusCode >= 300) {
      stderr.writeln(
        'Falha ao upsertar fc_players ($provider/$gameVersion/'
        '$providerPlayerId): ${response.statusCode} ${response.body}',
      );
      return null;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty) {
      return (decoded.first as Map<String, dynamic>)['id'] as String?;
    }
    return null;
  }

  /// Todos os ids externos ja existentes para este provider (carta:
  /// provider_card_id) -- buscado uma vez antes do loop principal para que
  /// o sync saiba, por linha, se vai inserir ou atualizar (o upsert do
  /// PostgREST nao diferencia isso pelo status HTTP).
  Future<Set<String>> fetchExistingProviderIds({
    required String table,
    required String idColumn,
    required String provider,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/rest/v1/$table?provider=eq.${Uri.encodeComponent(provider)}'
        '&select=$idColumn',
      ),
      headers: _headers,
    );
    if (response.statusCode >= 300) {
      stderr.writeln(
        'Falha ao listar $idColumn existentes: '
        '${response.statusCode} ${response.body}',
      );
      return <String>{};
    }
    final rows = jsonDecode(response.body) as List<dynamic>;
    return <String>{
      for (final row in rows)
        if ((row as Map<String, dynamic>)[idColumn] != null)
          row[idColumn] as String,
    };
  }

  /// Retorna false em falha (sem lancar) -- quem chama conta sucesso/falha
  /// para o relatorio final, nao interrompe o resto do sync por uma linha.
  Future<bool> upsert({
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
      return false;
    }
    return true;
  }

  /// Marca is_active=false para toda carta DAQUELE provider que nao
  /// apareceu nesta rodada de sync -- nunca deleta.
  Future<int> deactivateMissing({
    required String table,
    required String idColumn,
    required String provider,
    required Set<String> keepIds,
  }) async {
    if (keepIds.isEmpty) {
      return 0;
    }
    final idsList = keepIds.map((id) => '"$id"').join(',');
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/rest/v1/$table?provider=eq.$provider'
        '&$idColumn=not.in.($idsList)&is_active=eq.true',
      ),
      headers: <String, String>{..._headers, 'Prefer': 'return=representation'},
      body: jsonEncode(<String, dynamic>{'is_active': false}),
    );
    final updated = jsonDecode(response.body);
    return updated is List ? updated.length : 0;
  }
}
