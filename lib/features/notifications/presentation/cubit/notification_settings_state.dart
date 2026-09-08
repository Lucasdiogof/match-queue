import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';

enum NotificationSettingsStatus { loading, ready, failure }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.loading,
    this.preferences = NotificationPreferences.enabled,
    this.permission = PushPermissionStatus.notDetermined,
    this.isSaving = false,
    this.failure,
  });

  final NotificationSettingsStatus status;
  final NotificationPreferences preferences;
  final PushPermissionStatus permission;
  final bool isSaving;
  final AppFailure? failure;

  bool get isReady => status == NotificationSettingsStatus.ready;

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreferences? preferences,
    PushPermissionStatus? permission,
    bool? isSaving,
    AppFailure? failure,
    bool clearFailure = false,
  }) => NotificationSettingsState(
    status: status ?? this.status,
    preferences: preferences ?? this.preferences,
    permission: permission ?? this.permission,
    isSaving: isSaving ?? this.isSaving,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    preferences,
    permission,
    isSaving,
    failure,
  ];
}
