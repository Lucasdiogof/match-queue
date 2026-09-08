import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';

class AppNotificationModel {
  const AppNotificationModel._();

  static NotificationInboxPage pageFromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <AppNotification>[
      if (rawItems is List)
        for (final item in rawItems)
          if (item is Map) _fromJson(Map<String, dynamic>.from(item)),
    ];
    return NotificationInboxPage(
      items: items,
      hasMore: json['has_more'] == true,
      nextCursor: _cursorFromJson(json['next_cursor']),
    );
  }

  static AppNotification _fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: '${json['id']}',
        category: NotificationCategory.tryFromKey(json['category']),
        type: '${json['type']}',
        titleKey: '${json['title_key']}',
        params: _map(json['params']),
        deepLinkType: _string(json['deep_link_type']),
        deepLinkParams: _map(json['deep_link_params']),
        createdAt: _date(json['created_at']) ?? DateTime.now().toUtc(),
        readAt: _date(json['read_at']),
      );

  static NotificationInboxCursor? _cursorFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final createdAt = _string(value['created_at']);
    final id = _string(value['id']);
    if (createdAt == null || id == null) {
      return null;
    }
    return NotificationInboxCursor(createdAt: createdAt, id: id);
  }

  static Map<String, dynamic> _map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static DateTime? _date(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }
}
