import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PublicProfileRemoteDataSource {
  Future<Map<String, dynamic>> getMySettings();

  Future<Map<String, dynamic>> updateMySettings({
    required bool isEnabled,
    String? slug,
    String? fcAccountId,
    required bool showSquad,
    required bool showWeekendLeague,
    required bool showRivals,
    required bool showStats,
  });

  Future<bool> isSlugAvailable(String slug);

  Future<Map<String, dynamic>> getPublicProfile(String identifier);
}

class SupabasePublicProfileRemoteDataSource
    implements PublicProfileRemoteDataSource {
  const SupabasePublicProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> getMySettings() async {
    final response = await _client.rpc<dynamic>(
      'get_my_public_profile_settings',
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<Map<String, dynamic>> updateMySettings({
    required bool isEnabled,
    String? slug,
    String? fcAccountId,
    required bool showSquad,
    required bool showWeekendLeague,
    required bool showRivals,
    required bool showStats,
  }) async {
    final response = await _client.rpc<dynamic>(
      'update_my_public_profile_settings',
      params: <String, dynamic>{
        'p_is_enabled': isEnabled,
        'p_slug': slug,
        'p_fc_account_id': fcAccountId,
        'p_show_squad': showSquad,
        'p_show_weekend_league': showWeekendLeague,
        'p_show_rivals': showRivals,
        'p_show_stats': showStats,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<bool> isSlugAvailable(String slug) async {
    final response = await _client.rpc<dynamic>(
      'check_public_profile_slug_available',
      params: <String, dynamic>{'p_slug': slug},
    );
    return response as bool;
  }

  @override
  Future<Map<String, dynamic>> getPublicProfile(String identifier) async {
    final response = await _client.rpc<dynamic>(
      'get_public_profile',
      params: <String, dynamic>{'p_identifier': identifier},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
