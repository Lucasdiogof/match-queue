import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_page.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';

abstract interface class HistoryRepository {
  Future<MatchHistoryPage> fetchHistory({
    required String teamId,
    int limit,
    MatchHistoryCursor? cursor,
    MatchSearchStatus? status,
    String? userId,
    DateTime? from,
    DateTime? to,
  });

  Future<MatchmakingStats> fetchStats({
    required String teamId,
    DateTime? from,
    DateTime? to,
  });

  Future<ActivityHistoryPage> fetchActivityHistory({
    required String teamId,
    int limit,
    ActivityHistoryCursor? cursor,
    ActivityScope scope,
    GameResult? gameResult,
    MatchSearchStatus? searchStatus,
    String? userId,
    DateTime? from,
    DateTime? to,
  });
}
