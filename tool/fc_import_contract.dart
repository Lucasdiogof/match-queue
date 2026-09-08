// Contrato de normalizacao provider-agnostic do importer de catalogo FC.
//
// Nada aqui sabe se o dado veio de um dataset comunitario, de um export
// manual ou de qualquer outra fonte local -- e exatamente o ponto: o
// importer (tool/sync_fc_cards.dart) le um arquivo local (CSV/JSON),
// normaliza linha a linha para [ExternalFcPlayer]/[ExternalFcCard], e so
// essas duas classes conhecem os nomes de campo que viram coluna no banco.
// Nenhuma logica de provider especifico vaza pro banco ou pro Flutter --
// fica isolada aqui.
//
// [ExternalFcPlayer] representa o atleta base (fc_players); [ExternalFcCard]
// representa a carta/versao especifica (fc_player_cards), com
// [ExternalFcCard.providerPlayerId] linkando de volta ao jogador quando o
// item de entrada declarou essa identidade.

class ExternalFcPlayer {
  ExternalFcPlayer({
    required this.provider,
    required this.gameVersion,
    required this.providerPlayerId,
    required this.name,
    this.commonName,
    this.nationName,
    this.clubName,
    this.leagueName,
    this.primaryPosition,
    this.alternativePositions = const <String>[],
    this.imageUrl,
    this.heightCm,
    this.preferredFoot,
    this.weakFoot,
    this.skillMoves,
    this.rawMetadata,
  });

  final String provider;
  final String gameVersion;
  final String providerPlayerId;
  final String name;
  final String? commonName;
  final String? nationName;
  final String? clubName;
  final String? leagueName;
  final String? primaryPosition;
  final List<String> alternativePositions;
  final String? imageUrl;
  final int? heightCm;
  final String? preferredFoot;
  final int? weakFoot;
  final int? skillMoves;
  final Map<String, dynamic>? rawMetadata;

  /// Linha pronta para upsert em `fc_players`. [nationId]/[clubId]/
  /// [leagueId] ja vem resolvidos (upsert por nome feito antes, mesmo
  /// caminho que a carta usa) -- esta classe nunca fala com o banco.
  Map<String, dynamic> toFcPlayersRow({
    String? nationId,
    String? clubId,
    String? leagueId,
    required DateTime syncedAt,
  }) => <String, dynamic>{
    'provider': provider,
    'provider_player_id': providerPlayerId,
    'game_version': gameVersion,
    'name': name,
    'common_name': commonName,
    'nation_id': nationId,
    'club_id': clubId,
    'league_id': leagueId,
    'primary_position': primaryPosition,
    'alternative_positions': alternativePositions,
    'image_url': imageUrl,
    'height_cm': heightCm,
    'preferred_foot': preferredFoot,
    'weak_foot': weakFoot,
    'skill_moves': skillMoves,
    'raw_metadata': rawMetadata,
    'is_active': true,
    'last_synced_at': syncedAt.toIso8601String(),
  };
}

class ExternalFcCard {
  ExternalFcCard({
    required this.provider,
    required this.gameVersion,
    required this.providerCardId,
    required this.playerName,
    required this.rating,
    required this.primaryPosition,
    this.providerPlayerId,
    this.commonName,
    this.alternativePositions = const <String>[],
    this.pace,
    this.shooting,
    this.passing,
    this.dribbling,
    this.defending,
    this.physical,
    this.gkDiving,
    this.gkHandling,
    this.gkKicking,
    this.gkReflexes,
    this.gkSpeed,
    this.gkPositioning,
    this.skillMoves,
    this.weakFoot,
    this.playstyles = const <String>[],
    this.heightCm,
    this.preferredFoot,
    this.playerRoles = const <String>[],
    this.rarity,
    this.playerImageUrl,
    this.cardImageUrl,
    this.clubName,
    this.leagueName,
    this.nationName,
    this.cardType,
    this.sourceUrl,
  });

  final String provider;
  final String gameVersion;
  final String providerCardId;
  final String? providerPlayerId;
  final String playerName;
  final String? commonName;
  final int rating;
  final String primaryPosition;
  final List<String> alternativePositions;
  final int? pace;
  final int? shooting;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? physical;
  final int? gkDiving;
  final int? gkHandling;
  final int? gkKicking;
  final int? gkReflexes;
  final int? gkSpeed;
  final int? gkPositioning;
  final int? skillMoves;
  final int? weakFoot;
  final List<String> playstyles;
  final int? heightCm;
  final String? preferredFoot;
  final List<String> playerRoles;
  final String? rarity;
  final String? playerImageUrl;
  final String? cardImageUrl;
  final String? clubName;
  final String? leagueName;
  final String? nationName;
  final String? cardType;
  final String? sourceUrl;

  /// Verdadeiro quando o item de entrada NAO declarou nenhum sinal de carta
  /// real (nem `provider_card_id` proprio, nem `card_type`, nem `rarity`) --
  /// so dado de jogador base. `sync_fc_cards.dart` ainda cria a linha em
  /// `fc_player_cards` (compatibilidade com o picker, que e card-centric),
  /// mas marca `card_type='BASE_DATASET'` em vez de fingir uma carta que o
  /// input nunca declarou.
  bool isBaseDatasetOnly({required bool hadExplicitCardId}) =>
      !hadExplicitCardId && cardType == null && rarity == null;

  Map<String, dynamic> toFcPlayerCardsRow({
    String? clubId,
    String? leagueId,
    String? nationId,
    String? fcPlayerId,
    required DateTime syncedAt,
  }) => <String, dynamic>{
    'provider': provider,
    'provider_card_id': providerCardId,
    'game_version': gameVersion,
    'fc_player_id': fcPlayerId,
    'player_name': playerName,
    'common_name': commonName,
    'rating': rating,
    'primary_position': primaryPosition,
    'alternative_positions': alternativePositions,
    'pace': pace,
    'shooting': shooting,
    'passing': passing,
    'dribbling': dribbling,
    'defending': defending,
    'physical': physical,
    'gk_diving': gkDiving,
    'gk_handling': gkHandling,
    'gk_kicking': gkKicking,
    'gk_reflexes': gkReflexes,
    'gk_speed': gkSpeed,
    'gk_positioning': gkPositioning,
    'skill_moves': skillMoves,
    'weak_foot': weakFoot,
    'playstyles': playstyles,
    'height_cm': heightCm,
    'preferred_foot': preferredFoot,
    'player_roles': playerRoles,
    'rarity': rarity,
    'player_image_url': playerImageUrl,
    'card_image_url': cardImageUrl,
    'club_name': clubName,
    'league_name': leagueName,
    'nation_name': nationName,
    'club_id': clubId,
    'league_id': leagueId,
    'nation_id': nationId,
    'card_type': cardType ?? 'BASE_DATASET',
    'is_active': true,
    'last_synced_at': syncedAt.toIso8601String(),
    'source_url': sourceUrl,
  };
}
