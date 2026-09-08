import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

abstract interface class GameRepository {
  Future<PendingGameMatch?> fetchPending();

  /// Finaliza a partida. Passe [result] para registro rápido (sem placar), ou
  /// [goalsFor]/[goalsAgainst] para o backend derivar o resultado do placar.
  Future<void> finishMatch({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  });

  /// A campanha de Weekend League acontecendo agora, senão a próxima, senão a
  /// última encerrada. Null se nenhuma existir ainda.
  Future<WeekendLeagueEvent?> fetchCurrentWeekendLeagueEvent();

  /// Vitórias/derrotas do chamador no evento (computado, nunca o override
  /// manual -- ver [WeekendLeagueRecord]). Null se o evento não existir.
  Future<WeekendLeagueRecord?> fetchWeekendLeagueRecord(String eventId);
}
