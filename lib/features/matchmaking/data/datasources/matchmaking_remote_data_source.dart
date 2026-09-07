import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MatchmakingRemoteDataSource {
  Future<Map<String, dynamic>> getState(String teamId);

  Future<Map<String, dynamic>> requestSearch(String teamId);

  Future<Map<String, dynamic>> cancelSearch(String teamId);

  Future<Map<String, dynamic>> reportMatchFound(String teamId);
}

class SupabaseMatchmakingRemoteDataSource implements MatchmakingRemoteDataSource {
  const SupabaseMatchmakingRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> getState(String teamId) => _call(
    'get_team_matchmaking_state',
    teamId,
  );

  @override
  Future<Map<String, dynamic>> requestSearch(String teamId) => _call(
    'request_match_search',
    teamId,
  );

  @override
  Future<Map<String, dynamic>> cancelSearch(String teamId) => _call(
    'cancel_match_search',
    teamId,
  );

  @override
  Future<Map<String, dynamic>> reportMatchFound(String teamId) => _call(
    'report_match_found',
    teamId,
  );

  Future<Map<String, dynamic>> _call(String function, String teamId) async {
    final response = await _client.rpc<dynamic>(
      function,
      params: <String, dynamic>{'p_team_id': teamId},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
