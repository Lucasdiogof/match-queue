import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

abstract interface class MatchmakingRepository {
  /// Read model de Conta + TIME: fila real por time, a mesma conta pode
  /// estar numa posicao diferente em cada time vinculado.
  Future<MyMatchmakingSnapshot> getMyStatus({
    required String fcAccountId,
    required String teamId,
  });

  /// Sinais de invalidacao de UM time. Cancelar a subscription do stream
  /// encerra o canal subjacente.
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId);

  Future<MyMatchmakingSnapshot> requestSearch({
    required String fcAccountId,
    required String teamId,
    String? fcSquadId,
    required GameMode mode,
  });

  /// Cancela a busca ATIVA da conta -- so pode haver uma, em qualquer time
  /// (lock global). Nao serve pra sair de uma fila: ver [leaveQueue].
  Future<MyMatchmakingSnapshot> cancelSearch(String fcAccountId);

  /// Sai da fila de UM time especifico. A conta pode continuar em filas de
  /// outros times.
  Future<MyMatchmakingSnapshot> leaveQueue({
    required String fcAccountId,
    required String teamId,
  });

  Future<MyMatchmakingSnapshot> reportMatchFound(String fcAccountId);

  /// So um pedido humano: nunca altera fila, busca, lock ou titular.
  Future<void> requestPriority({
    required String fcAccountId,
    required String teamId,
  });
}
