import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

enum ActivityScope { all, games, searches }

/// Um item da timeline combinada -- ou uma partida encerrada, ou uma busca
/// que NUNCA virou partida (MATCH_FOUND some daqui, representada pela
/// GameHistoryEntry vinculada, exceto quando o escopo é explicitamente
/// SEARCHES).
sealed class TeamActivityEntry extends Equatable {
  const TeamActivityEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.gameMode,
    required this.occurredAt,
    this.avatarUrl,
    this.fcAccountName,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GameMode gameMode;
  final DateTime occurredAt;
  final String? fcAccountName;
}

class GameHistoryEntry extends TeamActivityEntry {
  const GameHistoryEntry({
    required super.id,
    required super.userId,
    required super.displayName,
    required super.gameMode,
    required super.occurredAt,
    required this.status,
    required this.startedAt,
    super.avatarUrl,
    super.fcAccountName,
    this.fcSquadName,
    this.fcFormationCode,
    this.result,
    this.goalsFor,
    this.goalsAgainst,
    this.weekendLeagueNumber,
  });

  /// FINISHED, ABANDONED ou EXPIRED -- IN_MATCH nunca aparece aqui (essa é a
  /// partida pendente, mostrada em outro lugar).
  final String status;
  final GameResult? result;
  final int? goalsFor;
  final int? goalsAgainst;
  final DateTime startedAt;
  final int? weekendLeagueNumber;
  final String? fcSquadName;
  final String? fcFormationCode;

  bool get hasScore => goalsFor != null && goalsAgainst != null;

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    displayName,
    avatarUrl,
    gameMode,
    occurredAt,
    status,
    result,
    goalsFor,
    goalsAgainst,
    startedAt,
    weekendLeagueNumber,
    fcAccountName,
  ];
}

class SearchHistoryEntry extends TeamActivityEntry {
  const SearchHistoryEntry({
    required super.id,
    required super.userId,
    required super.displayName,
    required super.gameMode,
    required super.occurredAt,
    required this.status,
    required this.startedAt,
    required this.durationSeconds,
    super.avatarUrl,
    super.fcAccountName,
  });

  final MatchSearchStatus status;
  final DateTime startedAt;
  final int durationSeconds;

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    displayName,
    avatarUrl,
    gameMode,
    occurredAt,
    status,
    startedAt,
    durationSeconds,
    fcAccountName,
  ];
}

class ActivityHistoryCursor extends Equatable {
  const ActivityHistoryCursor({required this.occurredAt, required this.id});

  final String occurredAt;
  final String id;

  @override
  List<Object?> get props => <Object?>[occurredAt, id];
}

class ActivityHistoryPage extends Equatable {
  const ActivityHistoryPage({
    required this.items,
    required this.hasMore,
    required this.serverNow,
    this.nextCursor,
  });

  final List<TeamActivityEntry> items;
  final bool hasMore;
  final ActivityHistoryCursor? nextCursor;
  final DateTime serverNow;

  @override
  List<Object?> get props => <Object?>[items, hasMore, nextCursor, serverNow];
}
