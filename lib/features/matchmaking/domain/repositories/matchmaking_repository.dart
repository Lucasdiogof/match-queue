import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';

abstract interface class MatchmakingRepository {
  Future<MatchmakingSnapshot> getState(String teamId);

  /// Sinais de invalidacao do time. Cancelar a subscription do stream
  /// encerra o canal subjacente.
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId);

  Future<MatchmakingSnapshot> requestSearch(
    String teamId, {
    required String fcAccountId,
    String? fcSquadId,
    required GameMode mode,
  });

  Future<MatchmakingSnapshot> cancelSearch(String teamId);

  Future<MatchmakingSnapshot> reportMatchFound(String teamId);
}
