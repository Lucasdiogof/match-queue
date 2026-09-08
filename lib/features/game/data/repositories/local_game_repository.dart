import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';

/// Sem backend real não há partida real: o modo local nunca tem pendente nem
/// campanha de Weekend League (que vive só no banco).
class LocalGameRepository implements GameRepository {
  const LocalGameRepository();

  @override
  Future<PendingGameMatch?> fetchPending() async => null;

  @override
  Future<void> finishMatch({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) async {}

  @override
  Future<WeekendLeagueEvent?> fetchCurrentWeekendLeagueEvent() async => null;

  @override
  Future<WeekendLeagueRecord?> fetchWeekendLeagueRecord(
    String eventId,
  ) async => null;
}
