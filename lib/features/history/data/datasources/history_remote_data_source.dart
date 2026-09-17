import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class HistoryRemoteDataSource {
  Future<Map<String, dynamic>> fetchActivityHistory({
    required String teamId,
    required int limit,
    String? cursorOccurredAt,
    String? cursorId,
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
  Future<Map<String, dynamic>> fetchActivityHistory({
    required String teamId,
    required int limit,
    String? cursorOccurredAt,
    String? cursorId,
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
        'p_search_status': ?searchStatus,
        'p_user_id': ?userId,
        'p_from': ?from,
        'p_to': ?to,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
