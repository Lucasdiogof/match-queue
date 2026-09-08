import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/data/datasources/matchmaking_remote_data_source.dart';
import 'package:fifa_queue/features/matchmaking/data/models/matchmaking_snapshot_model.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';

class SupabaseMatchmakingRepository implements MatchmakingRepository {
  const SupabaseMatchmakingRepository(this._dataSource, this._errorMapper);

  final MatchmakingRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) =>
      _dataSource.watchTeam(teamId);

  @override
  Future<MatchmakingSnapshot> getState(String teamId) => _guard(() async {
    final json = await _dataSource.getState(teamId);
    return MatchmakingSnapshotModel.fromJson(json);
  });

  @override
  Future<MatchmakingSnapshot> requestSearch(
    String teamId, {
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  }) => _guard(() async {
    final json = await _dataSource.requestSearch(
      teamId,
      fcAccountId,
      fcSquadId,
      mode.key,
    );
    return MatchmakingSnapshotModel.fromJson(json);
  });

  @override
  Future<MatchmakingSnapshot> cancelSearch(String teamId) => _guard(() async {
    final json = await _dataSource.cancelSearch(teamId);
    return MatchmakingSnapshotModel.fromJson(json);
  });

  @override
  Future<MatchmakingSnapshot> reportMatchFound(String teamId) =>
      _guard(() async {
        final json = await _dataSource.reportMatchFound(teamId);
        return MatchmakingSnapshotModel.fromJson(json);
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
