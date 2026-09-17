import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';

abstract interface class HistoryRepository {
  Future<ActivityHistoryPage> fetchActivityHistory({
    required String teamId,
    int limit,
    ActivityHistoryCursor? cursor,
    MatchSearchStatus? searchStatus,
    String? userId,
    DateTime? from,
    DateTime? to,
  });
}
