import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

/// Um item da timeline: uma busca (achou partida, cancelou ou expirou).
/// O historico so guarda buscas -- nao ha mais conceito de partida/resultado
/// registrado.
class TeamActivityEntry extends Equatable {
  const TeamActivityEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.gameMode,
    required this.occurredAt,
    required this.status,
    required this.startedAt,
    required this.durationSeconds,
    this.avatarUrl,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final GameMode gameMode;
  final DateTime occurredAt;
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
