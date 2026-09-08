import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';

/// Usado no modo local de desenvolvimento (sem Supabase). Guarda as
/// preferências em memória para que a tela de ajustes funcione, e trata
/// registro/baixa de device como no-op — não há backend para onde mandar o
/// token, e o [UnavailablePushMessagingService] nem produz um.
class LocalNotificationRepository implements NotificationRepository {
  NotificationPreferences _preferences = NotificationPreferences.enabled;

  @override
  Future<NotificationPreferences> fetchPreferences() async => _preferences;

  @override
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  ) async {
    _preferences = preferences;
    return _preferences;
  }

  @override
  Future<void> registerDevice({
    required String token,
    required DevicePlatform platform,
  }) async {}

  @override
  Future<void> deactivateDevice(String token) async {}
}
