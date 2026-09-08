import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/data/datasources/matchmaking_remote_data_source.dart';
import 'package:fifa_queue/features/matchmaking/data/models/my_matchmaking_status_model.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';

class SupabaseMatchmakingRepository implements MatchmakingRepository {
  const SupabaseMatchmakingRepository(this._dataSource, this._errorMapper);

  final MatchmakingRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) =>
      _dataSource.watchTeam(teamId);

  @override
  Future<MyMatchmakingSnapshot> getMyStatus(String fcAccountId) =>
      _guard(() async {
        final json = await _dataSource.getMyStatus(fcAccountId);
        return MyMatchmakingSnapshotModel.fromJson(json);
      });

  @override
  Future<MyMatchmakingSnapshot> requestSearch({
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  }) => _guard(() async {
    final json = await _dataSource.requestSearch(
      fcAccountId,
      fcSquadId,
      mode.key,
    );
    return MyMatchmakingSnapshotModel.fromJson(json);
  });

  @override
  Future<MyMatchmakingSnapshot> cancelSearch(String fcAccountId) =>
      _guard(() async {
        final json = await _dataSource.cancelSearch(fcAccountId);
        return MyMatchmakingSnapshotModel.fromJson(json);
      });

  @override
  Future<MyMatchmakingSnapshot> reportMatchFound(String fcAccountId) =>
      _guard(() async {
        final json = await _dataSource.reportMatchFound(fcAccountId);
        return MyMatchmakingSnapshotModel.fromJson(json);
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
