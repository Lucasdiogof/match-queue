import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationInboxRepository {
  Future<NotificationInboxPage> fetchNotifications({
    required int limit,
    NotificationInboxCursor? cursor,
  });

  Future<int> fetchUnreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
