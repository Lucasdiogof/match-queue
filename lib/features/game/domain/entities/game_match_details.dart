import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

/// Um jogador DENTRO do squad_snapshot congelado de uma partida especifica.
/// Nunca o squad atual -- so o que estava la naquele momento, titular ou
/// banco, ambos elegiveis pra detalhar gols/assistencias.
class SquadSnapshotPlayer extends Equatable {
  const SquadSnapshotPlayer({
    required this.slotType,
    required this.slotCode,
    required this.cardId,
    required this.playerName,
    this.rating,
    this.position,
  });

  final String slotType;
  final String slotCode;
  final String cardId;
  final String playerName;
  final int? rating;
  final String? position;

  bool get isStarting => slotType == 'STARTING';

  static SquadSnapshotPlayer fromJson(Map<String, dynamic> json) =>
      SquadSnapshotPlayer(
        slotType: '${json['slot_type']}',
        slotCode: '${json['slot']}',
        cardId: '${json['card_id']}',
        playerName: '${json['player_name']}',
        rating: json['rating'] as int?,
        position: json['position'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[
    slotType,
    slotCode,
    cardId,
    playerName,
    rating,
    position,
  ];
}

class SquadSnapshot extends Equatable {
  const SquadSnapshot({
    required this.name,
    required this.formationCode,
    required this.players,
  });

  final String name;
  final String formationCode;
  final List<SquadSnapshotPlayer> players;

  List<SquadSnapshotPlayer> get startingPlayers =>
      players.where((p) => p.isStarting).toList(growable: false);

  List<SquadSnapshotPlayer> get benchPlayers =>
      players.where((p) => !p.isStarting).toList(growable: false);

  static SquadSnapshot? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    final playersJson = map['players'];
    return SquadSnapshot(
      name: '${map['name']}',
      formationCode: '${map['formation']}',
      players: playersJson is List
          ? playersJson
                .whereType<Map<String, dynamic>>()
                .map(SquadSnapshotPlayer.fromJson)
                .toList(growable: false)
          : const <SquadSnapshotPlayer>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[name, formationCode, players];
}

/// Gols/assistencias de UM jogador nUMA partida -- agregado, sem minuto do
/// gol. Deriva de public.game_match_player_stats.
class GameMatchPlayerStat extends Equatable {
  const GameMatchPlayerStat({
    required this.snapshotPlayerKey,
    required this.playerName,
    required this.goals,
    required this.assists,
    this.playerCardId,
    this.position,
    this.rating,
  });

  final String snapshotPlayerKey;
  final String? playerCardId;
  final String playerName;
  final String? position;
  final int? rating;
  final int goals;
  final int assists;

  static GameMatchPlayerStat fromJson(Map<String, dynamic> json) =>
      GameMatchPlayerStat(
        snapshotPlayerKey: '${json['snapshot_player_key']}',
        playerCardId: json['player_card_id'] as String?,
        playerName: '${json['player_name']}',
        position: json['position'] as String?,
        rating: json['rating'] as int?,
        goals: json['goals'] as int? ?? 0,
        assists: json['assists'] as int? ?? 0,
      );

  @override
  List<Object?> get props => <Object?>[
    snapshotPlayerKey,
    playerCardId,
    playerName,
    position,
    rating,
    goals,
    assists,
  ];
}

/// O que o Flutter manda de volta pro upsert -- so a chave e os numeros,
/// nunca nome/posicao (isso o backend deriva do snapshot).
class GameMatchPlayerStatInput extends Equatable {
  const GameMatchPlayerStatInput({
    required this.snapshotPlayerKey,
    required this.goals,
    required this.assists,
  });

  final String snapshotPlayerKey;
  final int goals;
  final int assists;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'snapshot_player_key': snapshotPlayerKey,
    'goals': goals,
    'assists': assists,
  };

  @override
  List<Object?> get props => <Object?>[snapshotPlayerKey, goals, assists];
}

/// Partida + conta + squad_snapshot + player stats numa unica leitura,
/// base da tela de detalhe do Historico. [isOwner] vem do backend --
/// so o dono ve CTA de editar.
class GameMatchDetails extends Equatable {
  const GameMatchDetails({
    required this.id,
    required this.teamId,
    required this.gameMode,
    required this.status,
    required this.startedAt,
    required this.isOwner,
    required this.playerStats,
    this.result,
    this.goalsFor,
    this.goalsAgainst,
    this.endedAt,
    this.weekendLeagueEventId,
    this.fcAccountId,
    this.fcAccountName,
    this.fcSquadId,
    this.squadSnapshot,
  });

  final String id;
  final String teamId;
  final GameMode gameMode;
  final String status;
  final GameResult? result;
  final int? goalsFor;
  final int? goalsAgainst;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? weekendLeagueEventId;
  final String? fcAccountId;
  final String? fcAccountName;
  final String? fcSquadId;
  final SquadSnapshot? squadSnapshot;
  final List<GameMatchPlayerStat> playerStats;
  final bool isOwner;

  bool get hasScore => goalsFor != null && goalsAgainst != null;

  bool get isFinished => status == 'FINISHED';

  /// Partida antiga (pre-Etapa 10) ou sem squad no momento da busca: nunca
  /// oferecer detalhamento por jogador nesse caso.
  bool get canDetailPlayers => squadSnapshot != null;

  @override
  List<Object?> get props => <Object?>[
    id,
    teamId,
    gameMode,
    status,
    result,
    goalsFor,
    goalsAgainst,
    startedAt,
    endedAt,
    weekendLeagueEventId,
    fcAccountId,
    fcAccountName,
    fcSquadId,
    squadSnapshot,
    playerStats,
    isOwner,
  ];
}
