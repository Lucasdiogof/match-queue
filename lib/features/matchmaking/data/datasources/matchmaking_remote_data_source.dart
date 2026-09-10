import 'dart:async';

import 'package:fifa_queue/features/matchmaking/domain/entities/matchmaking_realtime_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MatchmakingRemoteDataSource {
  Future<Map<String, dynamic>> getMyStatus(String fcAccountId, String teamId);

  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId);

  Future<Map<String, dynamic>> requestSearch(
    String fcAccountId,
    String teamId,
    String? fcSquadId,
    String gameMode,
  );

  Future<Map<String, dynamic>> cancelSearch(String fcAccountId);

  Future<Map<String, dynamic>> leaveQueue(String fcAccountId, String teamId);

  Future<Map<String, dynamic>> reportMatchFound(String fcAccountId);

  Future<void> requestPriority(String fcAccountId, String teamId);
}

class SupabaseMatchmakingRemoteDataSource
    implements MatchmakingRemoteDataSource {
  const SupabaseMatchmakingRemoteDataSource(this._client);

  static const String realtimeChannelPrefix = 'matchmaking:';
  static const String revisionsTable = 'team_matchmaking_revisions';

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> getMyStatus(
    String fcAccountId,
    String teamId,
  ) async {
    final response = await _client.rpc<dynamic>(
      'get_my_matchmaking_status',
      params: <String, dynamic>{
        'p_fc_account_id': fcAccountId,
        'p_team_id': teamId,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> requestSearch(
    String fcAccountId,
    String teamId,
    String? fcSquadId,
    String gameMode,
  ) async {
    final response = await _client.rpc<dynamic>(
      'request_match_search',
      params: <String, dynamic>{
        'p_fc_account_id': fcAccountId,
        'p_team_id': teamId,
        'p_fc_squad_id': fcSquadId,
        'p_game_mode': gameMode,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> cancelSearch(String fcAccountId) => _call(
    'cancel_match_search',
    <String, dynamic>{'p_fc_account_id': fcAccountId},
  );

  @override
  Future<Map<String, dynamic>> leaveQueue(String fcAccountId, String teamId) =>
      _call('leave_match_search_queue', <String, dynamic>{
        'p_fc_account_id': fcAccountId,
        'p_team_id': teamId,
      });

  @override
  Future<Map<String, dynamic>> reportMatchFound(String fcAccountId) => _call(
    'report_match_found_and_start_game',
    <String, dynamic>{'p_fc_account_id': fcAccountId},
  );

  @override
  Future<void> requestPriority(String fcAccountId, String teamId) async {
    await _client.rpc<dynamic>(
      'request_match_search_priority',
      params: <String, dynamic>{
        'p_fc_account_id': fcAccountId,
        'p_team_id': teamId,
      },
    );
  }

  /// Postgres Changes em public.team_matchmaking_revisions, filtrado pelo
  /// time. A tabela nao carrega estado nenhum -- so "o time X mudou" -- e a
  /// RLS dela so deixa membros do time enxergarem a linha.
  ///
  /// O canal nasce quando alguem escuta o stream e morre quando a
  /// subscription e cancelada.
  @override
  Stream<MatchmakingRealtimeEvent> watchTeam(String teamId) {
    late final StreamController<MatchmakingRealtimeEvent> controller;
    RealtimeChannel? channel;

    void open() {
      channel = _client
          .channel('$realtimeChannelPrefix$teamId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: revisionsTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'team_id',
              value: teamId,
            ),
            callback: (payload) {
              if (controller.isClosed) {
                return;
              }
              final revision = payload.newRecord['revision'];
              controller.add(
                MatchmakingStateInvalidated(
                  revision: revision is int ? revision : null,
                ),
              );
            },
          )
          .subscribe((status, error) {
            if (controller.isClosed) {
              return;
            }
            switch (status) {
              case RealtimeSubscribeStatus.subscribed:
                controller.add(const MatchmakingSubscribed());
              case RealtimeSubscribeStatus.closed:
              case RealtimeSubscribeStatus.channelError:
              case RealtimeSubscribeStatus.timedOut:
                controller.add(const MatchmakingRealtimeLost());
            }
          });
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

    controller = StreamController<MatchmakingRealtimeEvent>(
      onListen: open,
      onCancel: close,
    );

    return controller.stream;
  }

  Future<Map<String, dynamic>> _call(
    String function,
    Map<String, dynamic> params,
  ) async {
    final response = await _client.rpc<dynamic>(function, params: params);
    return Map<String, dynamic>.from(response as Map);
  }
}
