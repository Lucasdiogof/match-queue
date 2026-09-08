import 'package:equatable/equatable.dart';

/// Agregados de sessões CONCLUÍDAS. `successRate` e `avgDurationSeconds` são
/// nulos (não zero) quando não há sessão concluída no período — zero leria
/// como "nunca acharam partida".
class MatchmakingTotals extends Equatable {
  const MatchmakingTotals({
    required this.total,
    required this.matchFound,
    required this.cancelled,
    required this.expired,
    this.successRate,
    this.avgDurationSeconds,
  });

  final int total;
  final int matchFound;
  final int cancelled;
  final int expired;

  /// 0..1, ou nulo quando não há sessão concluída.
  final double? successRate;
  final int? avgDurationSeconds;

  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => <Object?>[
    total,
    matchFound,
    cancelled,
    expired,
    successRate,
    avgDurationSeconds,
  ];
}

class PlayerStats extends Equatable {
  const PlayerStats({
    required this.userId,
    required this.displayName,
    required this.total,
    required this.matchFound,
    required this.cancelled,
    required this.expired,
    this.avatarUrl,
    this.successRate,
    this.avgDurationSeconds,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int total;
  final int matchFound;
  final int cancelled;
  final int expired;
  final double? successRate;
  final int? avgDurationSeconds;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    total,
    matchFound,
    cancelled,
    expired,
    successRate,
    avgDurationSeconds,
  ];
}

class MatchmakingStats extends Equatable {
  const MatchmakingStats({
    required this.totals,
    required this.players,
    required this.serverNow,
  });

  final MatchmakingTotals totals;
  final List<PlayerStats> players;
  final DateTime serverNow;

  @override
  List<Object?> get props => <Object?>[totals, players, serverNow];
}
