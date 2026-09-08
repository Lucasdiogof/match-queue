import 'package:fifa_queue/features/history/domain/entities/match_history_page.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';

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
}
