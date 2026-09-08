import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
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

  /// Partida + conta + squad_snapshot + player stats numa unica leitura.
  /// Base da tela de detalhe do Histórico -- dono ou membro do mesmo time.
  Future<GameMatchDetails> fetchMatchDetails(String matchId);

  /// Edita resultado/placar de uma partida já FINISHED, sem limite de
  /// tempo (Etapa 12). Continua exigindo dono.
  Future<void> updateMatchResult({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  });

  /// Substitui os gols/assistências por jogador da partida inteira -- o
  /// Flutter sempre manda a lista completa do squad_snapshot (titulares +
  /// banco), zerada onde não houve gol/assistência.
  Future<void> upsertPlayerStats({
    required String matchId,
    required List<GameMatchPlayerStatInput> stats,
  });
}
