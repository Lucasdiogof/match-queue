import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/game_match_details.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/repositories/game_repository.dart';

/// Sem backend real não há partida real: o modo local nunca tem pendente.
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
  Future<void> discardMatch(String matchId) async {}

  @override
  Future<List<PendingGameMatch>> fetchPendingMatches() async =>
      const <PendingGameMatch>[];

  @override
  Future<void> dismissAllPendingMatches() async {}

  @override
  Future<GameMatchDetails> fetchMatchDetails(String matchId) async {
    throw const NotFoundFailure();
  }

  @override
  Future<void> updateMatchResult({
    required String matchId,
    GameResult? result,
    int? goalsFor,
    int? goalsAgainst,
  }) async {}

  @override
  Future<void> upsertPlayerStats({
    required String matchId,
    required List<GameMatchPlayerStatInput> stats,
  }) async {}
}
