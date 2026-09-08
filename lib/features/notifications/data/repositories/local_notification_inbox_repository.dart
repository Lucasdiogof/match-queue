import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';

/// Modo local de desenvolvimento (sem Supabase): central sempre vazia.
class LocalNotificationInboxRepository implements NotificationInboxRepository {
  @override
  Future<NotificationInboxPage> fetchNotifications({
    required int limit,
    NotificationInboxCursor? cursor,
  }) async =>
      const NotificationInboxPage(items: <AppNotification>[], hasMore: false);

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}
}
