import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FcAccountRemoteDataSource {
  Future<Map<String, dynamic>> listMyAccounts();

  Future<void> createAccount(String name);

  Future<void> updateAccount({required String id, required String name});

  Future<void> archiveAccount(String id);

  Future<void> updateRivalsDivision({required String id, String? division});

  Future<void> linkToTeam({required String accountId, required String teamId});

  Future<void> unlinkFromTeam({
    required String accountId,
    required String teamId,
  });

  Future<void> setWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    required int wins,
    required int losses,
  });

  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  });
}

class SupabaseFcAccountRemoteDataSource implements FcAccountRemoteDataSource {
  const SupabaseFcAccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> listMyAccounts() async {
    final response = await _client.rpc<dynamic>('list_my_fc_accounts');
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> createAccount(String name) => _client.rpc<dynamic>(
    'create_fc_account',
    params: <String, dynamic>{'p_name': name},
  );

  @override
  Future<void> updateAccount({required String id, required String name}) =>
      _client.rpc<dynamic>(
        'update_fc_account',
        params: <String, dynamic>{'p_id': id, 'p_name': name},
      );

  @override
  Future<void> archiveAccount(String id) => _client.rpc<dynamic>(
    'archive_fc_account',
    params: <String, dynamic>{'p_id': id},
  );

  @override
  Future<void> updateRivalsDivision({required String id, String? division}) =>
      _client.rpc<dynamic>(
        'update_rivals_division',
        params: <String, dynamic>{'p_id': id, 'p_division': division},
      );

  @override
  Future<void> linkToTeam({
    required String accountId,
    required String teamId,
  }) => _client.rpc<dynamic>(
    'link_fc_account_to_team',
    params: <String, dynamic>{
      'p_fc_account_id': accountId,
      'p_team_id': teamId,
    },
  );

  @override
  Future<void> unlinkFromTeam({
    required String accountId,
    required String teamId,
  }) => _client.rpc<dynamic>(
    'unlink_fc_account_from_team',
    params: <String, dynamic>{
      'p_fc_account_id': accountId,
      'p_team_id': teamId,
    },
  );

  @override
  Future<void> setWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
    required int wins,
    required int losses,
  }) => _client.rpc<dynamic>(
    'set_weekend_league_manual_record',
    params: <String, dynamic>{
      'p_fc_account_id': accountId,
      'p_event_id': eventId,
      'p_wins': wins,
      'p_losses': losses,
    },
  );

  @override
  Future<void> clearWeekendLeagueManualRecord({
    required String accountId,
    required String eventId,
  }) => _client.rpc<dynamic>(
    'clear_weekend_league_manual_record',
    params: <String, dynamic>{
      'p_fc_account_id': accountId,
      'p_event_id': eventId,
    },
  );
}
