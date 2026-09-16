import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';

/// Agregado de partidas de uma conta (todos os modos, ou um modo/evento
/// especifico -- quem decide o filtro e o RPC que devolve isto).
class ProfileStats extends Equatable {
  const ProfileStats({
    required this.matchesCount,
    required this.wins,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
  });

  final int matchesCount;
  final int wins;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;

  static const ProfileStats empty = ProfileStats(
    matchesCount: 0,
    wins: 0,
    losses: 0,
    goalsFor: 0,
    goalsAgainst: 0,
    goalDiff: 0,
  );

  static ProfileStats fromJson(Object? json) {
    if (json is! Map) {
      return empty;
    }
    final map = Map<String, dynamic>.from(json);
    return ProfileStats(
      matchesCount: map['matches_count'] as int? ?? 0,
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      goalsFor: map['goals_for'] as int? ?? 0,
      goalsAgainst: map['goals_against'] as int? ?? 0,
      goalDiff: map['goal_diff'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    matchesCount,
    wins,
    losses,
    goalsFor,
    goalsAgainst,
    goalDiff,
  ];
}

/// Record manual (override) de uma campanha de WL -- nunca somado ao
/// computado, so mostrado lado a lado.
class ManualRecord extends Equatable {
  const ManualRecord({required this.wins, required this.losses});

  final int wins;
  final int losses;

  static ManualRecord? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(json);
    return ManualRecord(
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[wins, losses];
}

/// Weekend League de uma conta num evento: computado (partidas reais) e
/// manual (override) SEMPRE separados -- a UI decide como mostrar os dois,
/// nunca inventa uma diferenca entre eles.
class WeekendLeagueProfileStats extends Equatable {
  const WeekendLeagueProfileStats({
    required this.computed,
    required this.topScorers,
    required this.topAssists,
    this.manual,
  });

  final ProfileStats computed;
  final ManualRecord? manual;
  final List<PlayerLeaderboardEntry> topScorers;
  final List<PlayerLeaderboardEntry> topAssists;

  bool get hasManualOverride => manual != null;

  /// Se o manual existe e diverge do que as partidas detalhadas mostram, a
  /// UI precisa deixar isso claro em vez de esconder a discrepancia.
  bool get manualDivergesFromComputed =>
      manual != null &&
      (manual!.wins != computed.wins || manual!.losses != computed.losses);

  static WeekendLeagueProfileStats fromJson(Map<String, dynamic> json) =>
      WeekendLeagueProfileStats(
        computed: ProfileStats.fromJson(json['computed']),
        manual: ManualRecord.fromJson(json['manual']),
        topScorers: PlayerLeaderboardEntry.listFromJson(json['top_scorers']),
        topAssists: PlayerLeaderboardEntry.listFromJson(json['top_assists']),
      );

  @override
  List<Object?> get props => <Object?>[
    computed,
    manual,
    topScorers,
    topAssists,
  ];
}

/// Division Rivals de uma conta -- all-time nesta etapa (sem season/semana
/// modelada ainda, simplificacao consciente).
class RivalsProfileStats extends Equatable {
  const RivalsProfileStats({
    required this.aggregate,
    required this.manual,
    required this.topScorers,
    required this.topAssists,
  });

  final ProfileStats aggregate;

  /// Contador manual (+1 vitoria / +1 derrota) -- fonte unica do record
  /// mostrado na UI hoje, `aggregate` fica so pra artilharia/assistencias.
  final ManualRecord manual;
  final List<PlayerLeaderboardEntry> topScorers;
  final List<PlayerLeaderboardEntry> topAssists;

  static RivalsProfileStats fromJson(Map<String, dynamic> json) =>
      RivalsProfileStats(
        aggregate: ProfileStats.fromJson(json['aggregate']),
        manual:
            ManualRecord.fromJson(json['manual']) ??
            const ManualRecord(wins: 0, losses: 0),
        topScorers: PlayerLeaderboardEntry.listFromJson(json['top_scorers']),
        topAssists: PlayerLeaderboardEntry.listFromJson(json['top_assists']),
      );

  @override
  List<Object?> get props => <Object?>[
    aggregate,
    manual,
    topScorers,
    topAssists,
  ];
}
