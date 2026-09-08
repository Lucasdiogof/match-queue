import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/game/data/datasources/game_remote_data_source.dart';
import 'package:fifa_queue/features/game/data/models/pending_game_match_model.dart';
import 'package:fifa_queue/features/game/data/models/weekend_league_event_model.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
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
  Future<WeekendLeagueEvent?> fetchCurrentWeekendLeagueEvent() =>
      _guard(() async {
        final json = await _dataSource.getCurrentWeekendLeagueEvent();
        return WeekendLeagueEventModel.fromResponse(json);
      });

  @override
  Future<WeekendLeagueRecord?> fetchWeekendLeagueRecord(String eventId) =>
      _guard(() async {
        final json = await _dataSource.getWeekendLeagueRecord(eventId);
        final computed = json['computed'];
        if (computed is! Map) {
          return null;
        }
        return WeekendLeagueRecord(
          wins: computed['wins'] is int ? computed['wins'] as int : 0,
          losses: computed['losses'] is int ? computed['losses'] as int : 0,
        );
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
