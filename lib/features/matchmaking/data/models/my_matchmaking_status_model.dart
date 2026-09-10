import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

class MyMatchmakingSnapshotModel {
  const MyMatchmakingSnapshotModel._();

  static MyMatchmakingSnapshot fromJson(Map<String, dynamic> json) {
    final searchingJson = json['searching'] as Map<String, dynamic>?;
    final blockingJson = json['blocking_search'] as Map<String, dynamic>?;
    final elsewhereJson = json['searching_elsewhere'] as Map<String, dynamic>?;
    final queueJson = json['queue'] as List<dynamic>? ?? const <dynamic>[];

    return MyMatchmakingSnapshot(
      fcAccountId: '${json['fc_account_id']}',
      teamId: '${json['team_id']}',
      accountLinkedToTeam: json['account_linked_to_team'] as bool? ?? true,
      searchDurationSeconds: json['search_duration_seconds'] as int?,
      searching: searchingJson == null
          ? null
          : MySearching(
              sessionId: '${searchingJson['session_id']}',
              startedAt: DateTime.parse('${searchingJson['started_at']}'),
              expiresAt: DateTime.parse('${searchingJson['expires_at']}'),
              gameMode: GameMode.tryFromKey(searchingJson['game_mode']),
              fcSquadId: searchingJson['fc_squad_id'] as String?,
              fcSquadName: searchingJson['fc_squad_name'] as String?,
            ),
      myStatus: switch (json['my_state']) {
        'SEARCHING' => MyMatchmakingStatus.searching,
        'QUEUED' => MyMatchmakingStatus.queued,
        _ => MyMatchmakingStatus.none,
      },
      myPosition: json['my_position'] as int?,
      blockingSearch: blockingJson == null
          ? null
          : BlockingSearch(
              userId: '${blockingJson['user_id']}',
              displayName: '${blockingJson['display_name']}',
              avatarUrl: blockingJson['avatar_url'] as String?,
              expiresAt: DateTime.parse('${blockingJson['expires_at']}'),
              fcAccountName: blockingJson['fc_account_name'] as String?,
              gameMode: GameMode.tryFromKey(blockingJson['game_mode']),
            ),
      searchingElsewhere: elsewhereJson == null
          ? null
          : SearchingElsewhere(
              teamId: '${elsewhereJson['team_id']}',
              teamName: '${elsewhereJson['team_name']}',
              expiresAt: DateTime.parse('${elsewhereJson['expires_at']}'),
            ),
      queue: <QueueEntry>[
        for (final entry in queueJson)
          if (entry is Map)
            QueueEntry(
              position: entry['position'] as int? ?? 0,
              userId: '${entry['user_id']}',
              fcAccountId: entry['fc_account_id'] as String?,
              displayName: '${entry['display_name']}',
              avatarUrl: entry['avatar_url'] as String?,
              fcAccountName: entry['fc_account_name'] as String?,
              gameMode: GameMode.tryFromKey(entry['game_mode']),
              isMe: entry['is_me'] as bool? ?? false,
            ),
      ],
      serverNow: DateTime.parse('${json['server_now']}'),
    );
  }
}
