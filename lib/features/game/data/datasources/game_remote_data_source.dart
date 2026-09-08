import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class GameRemoteDataSource {
  Future<Map<String, dynamic>> getPending();

  Future<void> finishMatch({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  });
}

class SupabaseGameRemoteDataSource implements GameRemoteDataSource {
  const SupabaseGameRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> getPending() async {
    final response = await _client.rpc<dynamic>('get_pending_game_match');
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> finishMatch({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  }) => _client.rpc<dynamic>(
    'finish_game_match',
    params: <String, dynamic>{
      'p_match_id': matchId,
      'p_result': ?result,
      'p_goals_for': ?goalsFor,
      'p_goals_against': ?goalsAgainst,
    },
  );
}
