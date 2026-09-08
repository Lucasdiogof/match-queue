import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/notifications/data/datasources/notification_inbox_remote_data_source.dart';
import 'package:fifa_queue/features/notifications/data/models/app_notification_model.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';

class SupabaseNotificationInboxRepository
    implements NotificationInboxRepository {
  const SupabaseNotificationInboxRepository(
    this._dataSource,
    this._errorMapper,
  );

  final NotificationInboxRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<NotificationInboxPage> fetchNotifications({
    required int limit,
    NotificationInboxCursor? cursor,
  }) => _guard(() async {
    final json = await _dataSource.fetchNotifications(
      limit: limit,
      cursorCreatedAt: cursor?.createdAt,
      cursorId: cursor?.id,
    );
    return AppNotificationModel.pageFromJson(json);
  });

  @override
  Future<int> fetchUnreadCount() => _guard(_dataSource.fetchUnreadCount);

  @override
  Future<void> markRead(String id) => _guard(() => _dataSource.markRead(id));

  @override
  Future<void> markAllRead() => _guard(_dataSource.markAllRead);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
