import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

enum MyMatchmakingStatus { searching, queued, none }

class SearchingPlayer extends Equatable {
  const SearchingPlayer({
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.startedAt,
    required this.expiresAt,
    this.avatarUrl,
    this.gameMode,
    this.fcAccountName,
  });

  final String sessionId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime startedAt;
  final DateTime expiresAt;
  final GameMode? gameMode;
  final String? fcAccountName;

  @override
  List<Object?> get props => <Object?>[
    sessionId,
    userId,
    displayName,
    avatarUrl,
    startedAt,
    expiresAt,
    gameMode,
    fcAccountName,
  ];
}

class MatchmakingQueueEntry extends Equatable {
  const MatchmakingQueueEntry({
    required this.userId,
    required this.displayName,
    required this.position,
    required this.joinedAt,
    this.avatarUrl,
    this.fcAccountName,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int position;
  final DateTime joinedAt;
  final String? fcAccountName;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    position,
    joinedAt,
    fcAccountName,
  ];
}

class MatchmakingSnapshot extends Equatable {
  const MatchmakingSnapshot({
    required this.teamId,
    required this.searchDurationSeconds,
    required this.queue,
    required this.myStatus,
    required this.serverNow,
    this.searching,
    this.myPosition,
  });

  final String teamId;
  final int searchDurationSeconds;
  final SearchingPlayer? searching;
  final List<MatchmakingQueueEntry> queue;
  final MyMatchmakingStatus myStatus;
  final int? myPosition;
  final DateTime serverNow;

  bool get isSearchingByMe => myStatus == MyMatchmakingStatus.searching;

  bool get isQueuedByMe => myStatus == MyMatchmakingStatus.queued;

  bool get isIdle => myStatus == MyMatchmakingStatus.none && searching == null;

  @override
  List<Object?> get props => <Object?>[
    teamId,
    searchDurationSeconds,
    searching,
    queue,
    myStatus,
    myPosition,
    serverNow,
  ];
}
