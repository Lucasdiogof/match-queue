import 'package:equatable/equatable.dart';

enum MyMatchmakingStatus { searching, queued, none }

class SearchingPlayer extends Equatable {
  const SearchingPlayer({
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.startedAt,
    required this.expiresAt,
    this.avatarUrl,
  });

  final String sessionId;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime startedAt;
  final DateTime expiresAt;

  @override
  List<Object?> get props => <Object?>[
    sessionId,
    userId,
    displayName,
    avatarUrl,
    startedAt,
    expiresAt,
  ];
}

class MatchmakingQueueEntry extends Equatable {
  const MatchmakingQueueEntry({
    required this.userId,
    required this.displayName,
    required this.position,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int position;
  final DateTime joinedAt;

  @override
  List<Object?> get props => <Object?>[
    userId,
    displayName,
    avatarUrl,
    position,
    joinedAt,
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

  bool get isIdle =>
      myStatus == MyMatchmakingStatus.none && searching == null;

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
