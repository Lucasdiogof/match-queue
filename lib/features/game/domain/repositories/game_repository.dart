import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';

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
}
