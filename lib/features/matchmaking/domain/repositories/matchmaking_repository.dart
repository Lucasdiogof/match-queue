import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_snapshot.dart';

abstract interface class MatchmakingRepository {
  Future<MatchmakingSnapshot> getState(String teamId);

  Future<MatchmakingSnapshot> requestSearch(String teamId);

  Future<MatchmakingSnapshot> cancelSearch(String teamId);

  Future<MatchmakingSnapshot> reportMatchFound(String teamId);
}
