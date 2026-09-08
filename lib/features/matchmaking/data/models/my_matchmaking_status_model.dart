import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

class MyMatchmakingSnapshotModel {
  const MyMatchmakingSnapshotModel._();

  static MyMatchmakingSnapshot fromJson(Map<String, dynamic> json) {
    final searchingJson = json['searching'] as Map<String, dynamic>?;
    final blockingJson = json['blocking_search'] as Map<String, dynamic>?;
    final linkedTeamIds =
        (json['linked_team_ids'] as List<dynamic>? ?? const <dynamic>[])
            .map((dynamic id) => '$id')
            .toList(growable: false);

    return MyMatchmakingSnapshot(
      fcAccountId: '${json['fc_account_id']}',
      linkedTeamIds: linkedTeamIds,
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
            ),
      serverNow: DateTime.parse('${json['server_now']}'),
    );
  }
}
