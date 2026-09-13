import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RequestsRemoteDataSource {
  Future<Map<String, dynamic>> getRequestsInbox();

  /// Emite um evento sempre que a propria revisao (user_requests_revisions)
  /// muda -- nunca carrega dado, so avisa "algo mudou, re-busque o inbox".
  /// Stream vazia se ninguem estiver autenticado.
  Stream<void> watchMyRequests();

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

  Future<Map<String, dynamic>?> fetchMyPendingRequest(String teamId);
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
  Future<void> approveTeamJoinRequest(String requestId) => _client.rpc<dynamic>(
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

  static const String _revisionsTable = 'user_requests_revisions';
  static const String _channelPrefix = 'requests:';

  @override
  Stream<void> watchMyRequests() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream<void>.empty();
    }

    late final StreamController<void> controller;
    RealtimeChannel? channel;

    void open() {
      channel = _client
          .channel('$_channelPrefix$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _revisionsTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (!controller.isClosed) {
                controller.add(null);
              }
            },
          )
          .subscribe();
    }

    Future<void> close() async {
      final active = channel;
      channel = null;
      if (active != null) {
        await _client.removeChannel(active);
      }
      if (!controller.isClosed) {
        unawaited(controller.close());
      }
    }

    controller = StreamController<void>(onListen: open, onCancel: close);
    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>?> fetchMyPendingRequest(String teamId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    // user_id explicito mesmo com a RLS ja restringindo: a policy tambem
    // libera leitura pra quem administra o time, e aqui so importa a
    // PROPRIA solicitacao.
    final row = await _client
        .from('team_join_requests')
        .select('id')
        .eq('team_id', teamId)
        .eq('user_id', userId)
        .eq('status', 'PENDING')
        .maybeSingle();
    return row;
  }
}
