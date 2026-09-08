import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';

abstract interface class MatchmakingRepository {
  /// Read model centrado em CONTA (Etapa 11): a tela Jogar nunca mais
  /// escolhe um time, so uma conta.
  Future<MyMatchmakingSnapshot> getMyStatus(String fcAccountId);

  /// Sinais de invalidacao de UM time -- ainda usado pelo TeamStatusCubit
  /// (tela de Time) para saber quando reler get_team_player_statuses.
  /// Cancelar a subscription do stream encerra o canal subjacente.
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId);

  Future<MyMatchmakingSnapshot> requestSearch({
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  });

  Future<MyMatchmakingSnapshot> cancelSearch(String fcAccountId);

  Future<MyMatchmakingSnapshot> reportMatchFound(String fcAccountId);
}
