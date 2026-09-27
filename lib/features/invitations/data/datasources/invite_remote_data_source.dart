import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class InviteRemoteDataSource {
  Future<Map<String, dynamic>> resolveInvite(String code);

  Future<Map<String, dynamic>> joinTeam(String code);

  Future<Map<String, dynamic>> getOrCreateActiveInvite(String teamId);

  Future<Map<String, dynamic>> rotateInvite(String teamId);

  Future<void> revokeInvite(String teamId);
}

class SupabaseInviteRemoteDataSource implements InviteRemoteDataSource {
  const SupabaseInviteRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> resolveInvite(String code) async {
    final response = await _client
        .rpc<dynamic>(
          'resolve_team_invite',
          params: <String, dynamic>{'p_code': code},
        )
        .single();
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> joinTeam(String code) async {
    final response = await _client
        .rpc<dynamic>(
          'join_team_by_invite',
          params: <String, dynamic>{'p_code': code},
        )
        .single();
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> getOrCreateActiveInvite(String teamId) async {
    final response = await _client.rpc<dynamic>(
      'get_or_create_team_invite',
      params: <String, dynamic>{'p_team_id': teamId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> rotateInvite(String teamId) async {
    final response = await _client.rpc<dynamic>(
      'rotate_team_invite',
      params: <String, dynamic>{'p_team_id': teamId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> revokeInvite(String teamId) async {
    await _client.rpc<dynamic>(
      'revoke_team_invite',
      params: <String, dynamic>{'p_team_id': teamId},
    );
  }
}
