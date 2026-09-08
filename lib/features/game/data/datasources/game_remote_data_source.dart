import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class GameRemoteDataSource {
  Future<Map<String, dynamic>> getPending();

  Future<void> finishMatch({
    required String matchId,
    String? result,
    int? goalsFor,
    int? goalsAgainst,
  });

  Future<Map<String, dynamic>?> getCurrentWeekendLeagueEvent();

  Future<Map<String, dynamic>> getWeekendLeagueRecord(String eventId);
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
  Future<Map<String, dynamic>?> getCurrentWeekendLeagueEvent() async {
    final response = await _client.rpc<dynamic>(
      'get_current_weekend_league_event',
    );
    if (response is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getWeekendLeagueRecord(String eventId) async {
    final response = await _client.rpc<dynamic>(
      'get_weekend_league_record',
      params: <String, dynamic>{'p_event_id': eventId},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
