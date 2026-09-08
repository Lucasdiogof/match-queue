import 'package:fifa_queue/features/history/data/models/parse.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_page.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';

class MatchHistoryModel {
  const MatchHistoryModel._();

  static MatchHistoryPage pageFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <MatchHistoryEntry>[
      if (rawItems is List)
        for (final item in rawItems)
          if (item is Map) entryFromJson(Map<String, dynamic>.from(item)),
    ];
    return MatchHistoryPage(
      items: items,
      hasMore: json['has_more'] == true,
      nextCursor: _cursorFromJson(json['next_cursor']),
      serverNow: parseDate(json['server_now']),
    );
  }

  static MatchHistoryEntry entryFromJson(Map<String, dynamic> json) {
    final startedAt = parseDate(json['started_at']);
    return MatchHistoryEntry(
      sessionId: '${json['session_id']}',
      userId: '${json['user_id']}',
      displayName: parseString(json['display_name']) ?? '',
      avatarUrl: parseString(json['avatar_url']),
      status:
          MatchSearchStatus.fromKey(json['status']) ??
          MatchSearchStatus.cancelled,
      finishReason: parseString(json['finish_reason']),
      startedAt: startedAt,
      finishedAt: parseDate(json['finished_at'], fallback: startedAt),
      durationSeconds: parseInt(json['duration_seconds']),
      configuredDurationSeconds: parseInt(json['configured_duration_seconds']),
    );
  }

  static MatchHistoryCursor? _cursorFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final finishedAt = parseString(value['finished_at']);
    final id = parseString(value['id']);
    if (finishedAt == null || id == null) {
      return null;
    }
    return MatchHistoryCursor(finishedAt: finishedAt, id: id);
  }
}
