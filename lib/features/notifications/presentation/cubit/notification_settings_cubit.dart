import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/notifications/application/push_token_coordinator.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_notification_type.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(
    this._repository,
    this._messaging,
    this._coordinator,
  ) : super(const NotificationSettingsState());

  final NotificationRepository _repository;
  final PushMessagingService _messaging;
  final PushTokenCoordinator _coordinator;

  bool get isPushSupported => _messaging.isSupported;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: NotificationSettingsStatus.loading,
        clearFailure: true,
      ),
    );
    final permission = await _messaging.currentPermission();
    try {
      final preferences = await _repository.fetchPreferences();
      if (!isClosed) {
        emit(
          NotificationSettingsState(
            status: NotificationSettingsStatus.ready,
            preferences: preferences,
            permission: permission,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: NotificationSettingsStatus.failure,
            permission: permission,
            failure: failure,
          ),
        );
      }
    }
  }

  Future<void> setEnabled(PushNotificationType type, {required bool value}) async {
    if (state.isSaving) {
      return;
    }
    final previous = state.preferences;
    final updated = previous.copyWithType(type, value);
    // Otimista: o toggle acompanha o dedo; se a escrita falhar, voltamos.
    emit(state.copyWith(preferences: updated, isSaving: true, clearFailure: true));
    try {
      final saved = await _repository.savePreferences(updated);
      if (!isClosed) {
        emit(state.copyWith(preferences: saved, isSaving: false));
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            preferences: previous,
            isSaving: false,
            failure: failure,
          ),
        );
      }
    }
  }

  /// Dispara o diálogo de permissão do sistema e, se concedida, registra o
  /// token na hora (sem esperar o próximo login).
  Future<PushPermissionStatus> requestPermission() async {
    final result = await _messaging.requestPermission();
    if (!isClosed) {
      emit(state.copyWith(permission: result));
    }
    if (result.canReceive) {
      await _coordinator.registerCurrentToken();
    }
    return result;
  }

  /// Reconsulta a permissão — útil ao voltar dos ajustes do sistema.
  Future<void> refreshPermission() async {
    final permission = await _messaging.currentPermission();
    if (!isClosed) {
      emit(state.copyWith(permission: permission));
    }
  }
}
