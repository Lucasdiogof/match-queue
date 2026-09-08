import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';

abstract interface class NotificationRepository {
  Future<NotificationPreferences> fetchPreferences();

  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  );

  Future<void> registerDevice({
    required String token,
    required DevicePlatform platform,
  });

  Future<void> deactivateDevice(String token);
}
