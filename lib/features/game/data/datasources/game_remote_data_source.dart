import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class GameRemoteDataSource {
  Future<Map<String, dynamic>> getPending();

  Future<void> finishMatch({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  });

  Future<void> discardMatch(String matchId);

  Future<List<Map<String, dynamic>>> listPendingMatches();

  Future<void> dismissAllPendingMatches();

  Future<Map<String, dynamic>> getMatchDetails(String matchId);

  Future<void> updateMatchResult({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  });

  Future<void> upsertPlayerStats({
    required String matchId,
    required List<Map<String, dynamic>> stats,
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

  @override
  Future<void> discardMatch(String matchId) => _client.rpc<dynamic>(
    'discard_game_match',
    params: <String, dynamic>{'p_match_id': matchId},
  );

  @override
  Future<List<Map<String, dynamic>>> listPendingMatches() async {
    final response = await _client.rpc<dynamic>('list_pending_game_matches');
    final items = (response as Map)['items'];
    return <Map<String, dynamic>>[
      if (items is List)
        for (final item in items)
          if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  @override
  Future<void> dismissAllPendingMatches() =>
      _client.rpc<dynamic>('dismiss_all_pending_game_matches');

  @override
  Future<Map<String, dynamic>> getMatchDetails(String matchId) async {
    final response = await _client.rpc<dynamic>(
      'get_game_match_details',
      params: <String, dynamic>{'p_game_match_id': matchId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> updateMatchResult({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  }) => _client.rpc<dynamic>(
    'update_game_match_result',
    params: <String, dynamic>{
      'p_game_match_id': matchId,
      'p_result': ?result,
      'p_goals_for': ?goalsFor,
      'p_goals_against': ?goalsAgainst,
    },
  );

  @override
  Future<void> upsertPlayerStats({
    required String matchId,
    required List<Map<String, dynamic>> stats,
  }) => _client.rpc<dynamic>(
    'upsert_game_match_player_stats',
    params: <String, dynamic>{'p_game_match_id': matchId, 'p_stats': stats},
  );
}
