import 'package:fifa_queue/features/history/data/models/parse.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';

class MatchmakingStatsModel {
  const MatchmakingStatsModel._();

  static MatchmakingStats fromJson(Map<String, dynamic> json) {
    final totalsJson = json['totals'];
    final playersJson = json['players'];
    return MatchmakingStats(
      totals: _totalsFromJson(
        totalsJson is Map
            ? Map<String, dynamic>.from(totalsJson)
            : const <String, dynamic>{},
      ),
      players: <PlayerStats>[
        if (playersJson is List)
          for (final player in playersJson)
            if (player is Map)
              _playerFromJson(Map<String, dynamic>.from(player)),
      ],
      serverNow: parseDate(json['server_now']),
    );
  }

  static MatchmakingTotals _totalsFromJson(Map<String, dynamic> json) =>
      MatchmakingTotals(
        total: parseInt(json['total']),
        matchFound: parseInt(json['match_found']),
        cancelled: parseInt(json['cancelled']),
        expired: parseInt(json['expired']),
        successRate: parseNullableDouble(json['success_rate']),
        avgDurationSeconds: parseNullableInt(json['avg_duration_seconds']),
      );

  static PlayerStats _playerFromJson(Map<String, dynamic> json) => PlayerStats(
    userId: '${json['user_id']}',
    displayName: parseString(json['display_name']) ?? '',
    avatarUrl: parseString(json['avatar_url']),
    total: parseInt(json['total']),
    matchFound: parseInt(json['match_found']),
    cancelled: parseInt(json['cancelled']),
    expired: parseInt(json['expired']),
    successRate: parseNullableDouble(json['success_rate']),
    avgDurationSeconds: parseNullableInt(json['avg_duration_seconds']),
  );
}
