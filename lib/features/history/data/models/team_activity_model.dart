import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/data/models/parse.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';

class TeamActivityModel {
  const TeamActivityModel._();

  static ActivityHistoryPage pageFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <TeamActivityEntry>[
      if (rawItems is List)
        for (final item in rawItems)
          if (item is Map) _entryFromJson(Map<String, dynamic>.from(item)),
    ];
    return ActivityHistoryPage(
      items: items,
      hasMore: json['has_more'] == true,
      nextCursor: _cursorFromJson(json['next_cursor']),
      serverNow: parseDate(json['server_now']),
    );
  }

  static TeamActivityEntry _entryFromJson(Map<String, dynamic> json) {
    if (json['type'] == 'GAME') {
      final startedAt = parseDate(json['started_at']);
      return GameHistoryEntry(
        id: '${json['id']}',
        userId: '${json['user_id']}',
        displayName: parseString(json['display_name']) ?? '',
        avatarUrl: parseString(json['avatar_url']),
        gameMode: GameMode.fromKey(json['game_mode']),
        occurredAt: parseDate(json['ended_at'], fallback: startedAt),
        status: parseString(json['status']) ?? 'FINISHED',
        result: switch (json['result']) {
          'WIN' => GameResult.win,
          'LOSS' => GameResult.loss,
          _ => null,
        },
        goalsFor: parseNullableInt(json['goals_for']),
        goalsAgainst: parseNullableInt(json['goals_against']),
        startedAt: startedAt,
        weekendLeagueNumber: parseNullableInt(json['weekend_league_number']),
      );
    }

    final startedAt = parseDate(json['started_at']);
    return SearchHistoryEntry(
      id: '${json['id']}',
      userId: '${json['user_id']}',
      displayName: parseString(json['display_name']) ?? '',
      avatarUrl: parseString(json['avatar_url']),
      gameMode: GameMode.fromKey(json['game_mode']),
      occurredAt: parseDate(json['finished_at'], fallback: startedAt),
      status:
          MatchSearchStatus.fromKey(json['status']) ??
          MatchSearchStatus.cancelled,
      startedAt: startedAt,
      durationSeconds: parseInt(json['duration_seconds']),
    );
  }

  static ActivityHistoryCursor? _cursorFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final occurredAt = parseString(value['occurred_at']);
    final id = parseString(value['id']);
    if (occurredAt == null || id == null) {
      return null;
    }
    return ActivityHistoryCursor(occurredAt: occurredAt, id: id);
  }
}
