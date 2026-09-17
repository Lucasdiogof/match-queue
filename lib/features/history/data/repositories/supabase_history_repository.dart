import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/history/data/datasources/history_remote_data_source.dart';
import 'package:fifa_queue/features/history/data/models/team_activity_model.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';

class SupabaseHistoryRepository implements HistoryRepository {
  const SupabaseHistoryRepository(this._dataSource, this._errorMapper);

  final HistoryRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<ActivityHistoryPage> fetchActivityHistory({
    required String teamId,
    int limit = 20,
    ActivityHistoryCursor? cursor,
    MatchSearchStatus? searchStatus,
    String? userId,
    DateTime? from,
    DateTime? to,
  }) => _guard(() async {
    final json = await _dataSource.fetchActivityHistory(
      teamId: teamId,
      limit: limit,
      cursorOccurredAt: cursor?.occurredAt,
      cursorId: cursor?.id,
      searchStatus: searchStatus?.key,
      userId: userId,
      from: from?.toUtc().toIso8601String(),
      to: to?.toUtc().toIso8601String(),
    );
    return TeamActivityModel.pageFromJson(json);
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
