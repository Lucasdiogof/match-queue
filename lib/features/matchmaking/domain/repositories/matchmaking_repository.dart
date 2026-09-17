import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

abstract interface class MatchmakingRepository {
  /// Read model do usuario logado + TIME + MODO: fila independente por
  /// (time, modo) -- o mesmo usuario pode estar numa posicao diferente em
  /// Champions e em Rivals do MESMO time ao mesmo tempo.
  Future<MyMatchmakingSnapshot> getMyStatus({
    required String teamId,
    required GameMode mode,
  });

  /// Sinais de invalidacao de UM time. Cancelar a subscription do stream
  /// encerra o canal subjacente.
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId);

  Future<MyMatchmakingSnapshot> requestSearch({
    required String teamId,
    String? fcSquadId,
    required GameMode mode,
  });

  /// Cancela a busca ATIVA do usuario -- so pode haver uma, em qualquer time
  /// (lock global). Nao serve pra sair de uma fila: ver [leaveQueue].
  Future<MyMatchmakingSnapshot> cancelSearch();

  /// Sai da fila de UM (time, modo) especifico. O usuario pode continuar em
  /// filas de outros times/modos.
  Future<MyMatchmakingSnapshot> leaveQueue({
    required String teamId,
    required GameMode mode,
  });

  Future<MyMatchmakingSnapshot> reportMatchFound();

  /// So um pedido humano: nunca altera fila, busca, lock ou titular.
  Future<void> requestPriority({
    required String teamId,
    required GameMode mode,
  });
}
