import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';

class MatchmakingSnapshotModel {
  const MatchmakingSnapshotModel._();

  static MatchmakingSnapshot fromJson(Map<String, dynamic> json) {
    final searchingJson = json['searching'] as Map<String, dynamic>?;
    final queueJson = json['queue'] as List<dynamic>? ?? const <dynamic>[];

    return MatchmakingSnapshot(
      teamId: '${json['team_id']}',
      searchDurationSeconds: json['search_duration_seconds'] as int? ?? 180,
      searching: searchingJson == null
          ? null
          : SearchingPlayer(
              sessionId: '${searchingJson['session_id']}',
              userId: '${searchingJson['user_id']}',
              displayName: '${searchingJson['display_name']}',
              avatarUrl: searchingJson['avatar_url'] as String?,
              startedAt: DateTime.parse('${searchingJson['started_at']}'),
              expiresAt: DateTime.parse('${searchingJson['expires_at']}'),
              gameMode: GameMode.tryFromKey(searchingJson['game_mode']),
              fcAccountName: searchingJson['fc_account_name'] as String?,
            ),
      queue: queueJson
          .whereType<Map<String, dynamic>>()
          .map(_queueEntryFromJson)
          .toList(growable: false),
      myStatus: switch (json['my_state']) {
        'SEARCHING' => MyMatchmakingStatus.searching,
        'QUEUED' => MyMatchmakingStatus.queued,
        _ => MyMatchmakingStatus.none,
      },
      myPosition: json['my_position'] as int?,
      serverNow: DateTime.parse('${json['server_now']}'),
    );
  }

  static MatchmakingQueueEntry _queueEntryFromJson(Map<String, dynamic> json) =>
      MatchmakingQueueEntry(
        userId: '${json['user_id']}',
        displayName: '${json['display_name']}',
        avatarUrl: json['avatar_url'] as String?,
        position: json['position'] as int,
        joinedAt: DateTime.parse('${json['joined_at']}'),
        fcAccountName: json['fc_account_name'] as String?,
      );
}
