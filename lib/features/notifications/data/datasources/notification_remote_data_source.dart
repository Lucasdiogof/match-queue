import 'package:fifa_queue/features/notifications/data/models/notification_preferences_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class NotificationRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>?> fetchPreferences(String userId);

  Future<Map<String, dynamic>> upsertPreferences(Map<String, dynamic> values);

  Future<void> registerDevice({
    required String token,
    required String platform,
  });

  Future<void> deactivateDevice(String token);
}

class SupabaseNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  const SupabaseNotificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _preferences =>
      _client.from(NotificationPreferencesModel.table);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> fetchPreferences(String userId) => _preferences
      .select()
      .eq(NotificationPreferencesModel.columnUserId, userId)
      .maybeSingle();

  @override
  Future<Map<String, dynamic>> upsertPreferences(
    Map<String, dynamic> values,
  ) async {
    final row = await _preferences
        .upsert(values, onConflict: NotificationPreferencesModel.columnUserId)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  /// Registro e baixa passam por RPC porque o upsert pode precisar tomar o
  /// token de outro usuario (mesmo aparelho, conta nova), coisa que a RLS do
  /// chamador nunca permitiria num insert direto.
  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) => _client.rpc<dynamic>(
    'register_device',
    params: <String, dynamic>{'p_fcm_token': token, 'p_platform': platform},
  );

  @override
  Future<void> deactivateDevice(String token) => _client.rpc<dynamic>(
    'deactivate_device',
    params: <String, dynamic>{'p_fcm_token': token},
  );
}
