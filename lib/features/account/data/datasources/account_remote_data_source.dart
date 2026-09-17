import 'package:fifa_queue/features/account/data/models/account_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AccountRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchById(String userId);

  Future<Map<String, dynamic>> insert({
    required String userId,
    required String displayName,
  });

  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  });

  Future<void> updateLocale({
    required String userId,
    required String localeTag,
  });

  Future<void> touchActivity(String userId);

  /// Bundle de `get_my_account`: times, record manual de WL/Rivals, evento
  /// vigente -- tudo que nao vive direto na linha de `users`.
  Future<Map<String, dynamic>> fetchAccountExtras();

  Future<List<String>> updatePlatforms(List<String> platforms);

  Future<void> updateRivalsDivision(String? division);

  Future<Map<String, dynamic>> incrementRivalsRecord({
    int winDelta = 0,
    int lossDelta = 0,
  });

  Future<Map<String, dynamic>> incrementWeekendLeagueRecord({
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  });

  Future<Map<String, dynamic>> setWeekendLeagueManualRecord({
    required String eventId,
    required int wins,
    required int losses,
  });

  Future<void> clearWeekendLeagueManualRecord(String eventId);

  Future<List<Map<String, dynamic>>> fetchWeekendLeagueEvents();

  Future<Map<String, dynamic>> fetchWeekendLeagueStats(String eventId);

  Future<Map<String, dynamic>> fetchRivalsStats();
}

class SupabaseAccountRemoteDataSource implements AccountRemoteDataSource {
  const SupabaseAccountRemoteDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from(AccountModel.table);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchById(String userId) =>
      _table.select().eq(AccountModel.columnId, userId).maybeSingle();

  @override
  Future<Map<String, dynamic>> insert({
    required String userId,
    required String displayName,
  }) => _table
      .insert(<String, dynamic>{
        AccountModel.columnId: userId,
        AccountModel.columnDisplayName: displayName,
      })
      .select()
      .single();

  @override
  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  }) => _table
      .update(<String, dynamic>{AccountModel.columnDisplayName: displayName})
      .eq(AccountModel.columnId, userId)
      .select()
      .single();

  @override
  Future<void> updateLocale({
    required String userId,
    required String localeTag,
  }) => _table
      .update(<String, dynamic>{AccountModel.columnLocale: localeTag})
      .eq(AccountModel.columnId, userId);

  @override
  Future<void> touchActivity(String userId) => _table
      .update(<String, dynamic>{
        AccountModel.columnLastActiveAt: DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
      .eq(AccountModel.columnId, userId);

  @override
  Future<Map<String, dynamic>> fetchAccountExtras() async {
    final response = await _client.rpc<dynamic>('get_my_account');
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<List<String>> updatePlatforms(List<String> platforms) async {
    final response = await _client.rpc<dynamic>(
      'update_my_platforms',
      params: <String, dynamic>{'p_platforms': platforms},
    );
    return (response as List).map((e) => '$e').toList(growable: false);
  }

  @override
  Future<void> updateRivalsDivision(String? division) => _client.rpc<dynamic>(
    'update_my_rivals_division',
    params: <String, dynamic>{'p_division': division},
  );

  @override
  Future<Map<String, dynamic>> incrementRivalsRecord({
    int winDelta = 0,
    int lossDelta = 0,
  }) async {
    final response = await _client.rpc<dynamic>(
      'increment_rivals_manual_record',
      params: <String, dynamic>{
        'p_win_delta': winDelta,
        'p_loss_delta': lossDelta,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> incrementWeekendLeagueRecord({
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) async {
    final response = await _client.rpc<dynamic>(
      'increment_weekend_league_manual_record',
      params: <String, dynamic>{
        'p_event_id': eventId,
        'p_win_delta': winDelta,
        'p_loss_delta': lossDelta,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> setWeekendLeagueManualRecord({
    required String eventId,
    required int wins,
    required int losses,
  }) async {
    final response = await _client.rpc<dynamic>(
      'set_weekend_league_manual_record',
      params: <String, dynamic>{
        'p_event_id': eventId,
        'p_wins': wins,
        'p_losses': losses,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> clearWeekendLeagueManualRecord(String eventId) =>
      _client.rpc<dynamic>(
        'clear_weekend_league_manual_record',
        params: <String, dynamic>{'p_event_id': eventId},
      );

  @override
  Future<List<Map<String, dynamic>>> fetchWeekendLeagueEvents() async {
    final response = await _client.rpc<dynamic>('list_weekend_league_events');
    final items = (response as Map)['items'];
    return <Map<String, dynamic>>[
      if (items is List)
        for (final item in items)
          if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  @override
  Future<Map<String, dynamic>> fetchWeekendLeagueStats(String eventId) async {
    final response = await _client.rpc<dynamic>(
      'get_weekend_league_account_stats',
      params: <String, dynamic>{'p_weekend_league_event_id': eventId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> fetchRivalsStats() async {
    final response = await _client.rpc<dynamic>('get_rivals_account_stats');
    return Map<String, dynamic>.from(response as Map);
  }
}
