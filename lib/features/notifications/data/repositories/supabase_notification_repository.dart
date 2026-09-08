import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:fifa_queue/features/notifications/data/models/notification_preferences_model.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_preferences.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this._dataSource, this._errorMapper);

  final NotificationRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<NotificationPreferences> fetchPreferences() => _guard(() async {
    final row = await _dataSource.fetchPreferences(_requireUserId());
    // Linha ausente = tudo habilitado, mesmo default do banco.
    return row == null
        ? NotificationPreferences.enabled
        : NotificationPreferencesModel.fromJson(row);
  });

  @override
  Future<NotificationPreferences> savePreferences(
    NotificationPreferences preferences,
  ) => _guard(() async {
    final row = await _dataSource.upsertPreferences(
      NotificationPreferencesModel.toJson(_requireUserId(), preferences),
    );
    return NotificationPreferencesModel.fromJson(row);
  });

  @override
  Future<void> registerDevice({
    required String token,
    required DevicePlatform platform,
  }) => _guard(
    () => _dataSource.registerDevice(token: token, platform: platform.key),
  );

  @override
  Future<void> deactivateDevice(String token) =>
      _guard(() => _dataSource.deactivateDevice(token));

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
