import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class NotificationInboxRemoteDataSource {
  Future<Map<String, dynamic>> fetchNotifications({
    required int limit,
    String? cursorCreatedAt,
    String? cursorId,
  });

  Future<int> fetchUnreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class SupabaseNotificationInboxRemoteDataSource
    implements NotificationInboxRemoteDataSource {
  const SupabaseNotificationInboxRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchNotifications({
    required int limit,
    String? cursorCreatedAt,
    String? cursorId,
  }) async {
    final response = await _client.rpc<dynamic>(
      'list_my_notifications',
      params: <String, dynamic>{
        'p_limit': limit,
        'p_cursor_created_at': ?cursorCreatedAt,
        'p_cursor_id': ?cursorId,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _client.rpc<dynamic>(
      'get_my_unread_notification_count',
    );
    return response is num ? response.toInt() : 0;
  }

  @override
  Future<void> markRead(String id) => _client.rpc<dynamic>(
    'mark_notification_read',
    params: <String, dynamic>{'p_id': id},
  );

  @override
  Future<void> markAllRead() =>
      _client.rpc<dynamic>('mark_all_notifications_read');
}
