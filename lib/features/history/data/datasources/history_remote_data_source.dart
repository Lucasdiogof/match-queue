import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class HistoryRemoteDataSource {
  Future<Map<String, dynamic>> fetchHistory({
    required String teamId,
    required int limit,
    String? cursorFinishedAt,
    String? cursorId,
    String? status,
    String? userId,
    String? from,
    String? to,
  });

  Future<Map<String, dynamic>> fetchStats({
    required String teamId,
    String? from,
    String? to,
  });

  Future<Map<String, dynamic>> fetchActivityHistory({
    required String teamId,
    required int limit,
    String? cursorOccurredAt,
    String? cursorId,
    String? scope,
    String? gameResult,
    String? searchStatus,
    String? userId,
    String? from,
    String? to,
  });
}

class SupabaseHistoryRemoteDataSource implements HistoryRemoteDataSource {
  const SupabaseHistoryRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchHistory({
    required String teamId,
    required int limit,
    String? cursorFinishedAt,
    String? cursorId,
    String? status,
    String? userId,
    String? from,
    String? to,
  }) async {
    final response = await _client.rpc<dynamic>(
      'get_team_match_search_history',
      params: <String, dynamic>{
        'p_team_id': teamId,
        'p_limit': limit,
        'p_cursor_finished_at': ?cursorFinishedAt,
        'p_cursor_id': ?cursorId,
        'p_status': ?status,
        'p_user_id': ?userId,
        'p_from': ?from,
        'p_to': ?to,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> fetchStats({
    required String teamId,
    String? from,
    String? to,
  }) async {
    final response = await _client.rpc<dynamic>(
      'get_team_matchmaking_stats',
      params: <String, dynamic>{
        'p_team_id': teamId,
        'p_from': ?from,
        'p_to': ?to,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> fetchActivityHistory({
    required String teamId,
    required int limit,
    String? cursorOccurredAt,
    String? cursorId,
    String? scope,
    String? gameResult,
    String? searchStatus,
    String? userId,
    String? from,
    String? to,
  }) async {
    final response = await _client.rpc<dynamic>(
      'get_team_activity_history',
      params: <String, dynamic>{
        'p_team_id': teamId,
        'p_limit': limit,
        'p_cursor_occurred_at': ?cursorOccurredAt,
        'p_cursor_id': ?cursorId,
        'p_scope': ?scope,
        'p_game_result': ?gameResult,
        'p_search_status': ?searchStatus,
        'p_user_id': ?userId,
        'p_from': ?from,
        'p_to': ?to,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
