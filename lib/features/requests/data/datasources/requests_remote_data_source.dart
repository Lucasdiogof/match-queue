import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RequestsRemoteDataSource {
  Future<Map<String, dynamic>> getRequestsInbox();

  Future<void> requestTeamJoin({
    required String teamId,
    required String fcAccountId,
  });

  Future<void> cancelTeamJoinRequest(String requestId);

  Future<void> approveTeamJoinRequest(String requestId);

  Future<void> rejectTeamJoinRequest(String requestId);

  Future<Map<String, dynamic>> resolveInviteTarget(String slug);

  Future<void> inviteTeamMember({required String teamId, required String slug});

  Future<void> revokeTeamInvitation(String invitationId);

  Future<void> respondTeamInvitation({
    required String invitationId,
    required bool accept,
  });
}

class SupabaseRequestsRemoteDataSource implements RequestsRemoteDataSource {
  const SupabaseRequestsRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> getRequestsInbox() async {
    final response = await _client.rpc<dynamic>('get_requests_inbox');
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> requestTeamJoin({
    required String teamId,
    required String fcAccountId,
  }) => _client.rpc<dynamic>(
    'request_team_join',
    params: <String, dynamic>{
      'p_team_id': teamId,
      'p_fc_account_id': fcAccountId,
    },
  );

  @override
  Future<void> cancelTeamJoinRequest(String requestId) => _client.rpc<dynamic>(
    'cancel_team_join_request',
    params: <String, dynamic>{'p_request_id': requestId},
  );

  @override
  Future<void> approveTeamJoinRequest(String requestId) =>
      _client.rpc<dynamic>(
        'approve_team_join_request',
        params: <String, dynamic>{'p_request_id': requestId},
      );

  @override
  Future<void> rejectTeamJoinRequest(String requestId) => _client.rpc<dynamic>(
    'reject_team_join_request',
    params: <String, dynamic>{'p_request_id': requestId},
  );

  @override
  Future<Map<String, dynamic>> resolveInviteTarget(String slug) async {
    final response = await _client.rpc<dynamic>(
      'resolve_invite_target',
      params: <String, dynamic>{'p_slug': slug},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> inviteTeamMember({
    required String teamId,
    required String slug,
  }) => _client.rpc<dynamic>(
    'invite_team_member',
    params: <String, dynamic>{'p_team_id': teamId, 'p_slug': slug},
  );

  @override
  Future<void> revokeTeamInvitation(String invitationId) =>
      _client.rpc<dynamic>(
        'revoke_team_invitation',
        params: <String, dynamic>{'p_invitation_id': invitationId},
      );

  @override
  Future<void> respondTeamInvitation({
    required String invitationId,
    required bool accept,
  }) => _client.rpc<dynamic>(
    'respond_team_invitation',
    params: <String, dynamic>{
      'p_invitation_id': invitationId,
      'p_accept': accept,
    },
  );
}
