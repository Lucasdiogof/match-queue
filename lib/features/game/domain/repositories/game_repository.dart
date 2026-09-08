import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';

/// A campanha de Weekend League e o record de vitórias/derrotas saíram
/// daqui na Etapa 9 -- agora vivem em FcAccountRepository/FcAccountsCubit,
/// ligados ao Elenco selecionado, não mais ao usuário sozinho.
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
