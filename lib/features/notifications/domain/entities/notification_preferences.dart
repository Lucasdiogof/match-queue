import 'package:equatable/equatable.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_notification_type.dart';

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.queueTurnEnabled = true,
    this.searchExpiringEnabled = true,
    this.searchExpiredEnabled = true,
  });

  /// Ausencia de linha no backend significa tudo habilitado, entao o default
  /// do cliente precisa ser o mesmo para nao piscar valores diferentes.
  static const NotificationPreferences enabled = NotificationPreferences();

  final bool queueTurnEnabled;
  final bool searchExpiringEnabled;
  final bool searchExpiredEnabled;

  bool isEnabled(PushNotificationType type) => switch (type) {
    PushNotificationType.yourTurn => queueTurnEnabled,
    PushNotificationType.searchExpiring => searchExpiringEnabled,
    PushNotificationType.searchExpired => searchExpiredEnabled,
  };

  NotificationPreferences copyWithType(PushNotificationType type, bool value) =>
      switch (type) {
        PushNotificationType.yourTurn => NotificationPreferences(
          queueTurnEnabled: value,
          searchExpiringEnabled: searchExpiringEnabled,
          searchExpiredEnabled: searchExpiredEnabled,
        ),
        PushNotificationType.searchExpiring => NotificationPreferences(
          queueTurnEnabled: queueTurnEnabled,
          searchExpiringEnabled: value,
          searchExpiredEnabled: searchExpiredEnabled,
        ),
        PushNotificationType.searchExpired => NotificationPreferences(
          queueTurnEnabled: queueTurnEnabled,
          searchExpiringEnabled: searchExpiringEnabled,
          searchExpiredEnabled: value,
        ),
      };

  @override
  List<Object?> get props => <Object?>[
    queueTurnEnabled,
    searchExpiringEnabled,
    searchExpiredEnabled,
  ];
}
