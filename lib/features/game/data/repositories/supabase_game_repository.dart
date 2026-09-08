import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/game/data/datasources/game_remote_data_source.dart';
import 'package:fifa_queue/features/game/data/models/game_match_details_model.dart';
import 'package:fifa_queue/features/game/data/models/pending_game_match_model.dart';
import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';

class SupabaseGameRepository implements GameRepository {
  const SupabaseGameRepository(this._dataSource, this._errorMapper);

  final GameRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<PendingGameMatch?> fetchPending() => _guard(() async {
    final json = await _dataSource.getPending();
    return PendingGameMatchModel.fromResponse(json);
  });

  @override
  Future<void> finishMatch({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) => _guard(
    () => _dataSource.finishMatch(
      matchId: matchId,
      result: result?.key,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    ),
  );

  @override
  Future<GameMatchDetails> fetchMatchDetails(String matchId) =>
      _guard(() async {
        final json = await _dataSource.getMatchDetails(matchId);
        return GameMatchDetailsModel.fromResponse(json);
      });

  @override
  Future<void> updateMatchResult({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) => _guard(
    () => _dataSource.updateMatchResult(
      matchId: matchId,
      result: result?.key,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
    ),
  );

  @override
  Future<void> upsertPlayerStats({
    required String matchId,
    required List<GameMatchPlayerStatInput> stats,
  }) => _guard(
    () => _dataSource.upsertPlayerStats(
      matchId: matchId,
      stats: stats.map((s) => s.toJson()).toList(growable: false),
    ),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
