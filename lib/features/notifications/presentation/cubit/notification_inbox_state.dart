import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';

enum NotificationInboxStatus { initial, loading, ready, failure }

class NotificationInboxState extends Equatable {
  const NotificationInboxState({
    this.status = NotificationInboxStatus.initial,
    this.items = const <AppNotification>[],
    this.hasMore = false,
    this.cursor,
    this.isLoadingMore = false,
    this.failure,
  });

  final NotificationInboxStatus status;
  final List<AppNotification> items;
  final bool hasMore;
  final NotificationInboxCursor? cursor;
  final bool isLoadingMore;
  final AppFailure? failure;

  bool get isEmpty => status == NotificationInboxStatus.ready && items.isEmpty;

  NotificationInboxState copyWith({
    NotificationInboxStatus? status,
    List<AppNotification>? items,
    bool? hasMore,
    NotificationInboxCursor? cursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    AppFailure? failure,
    bool clearFailure = false,
  }) => NotificationInboxState(
    status: status ?? this.status,
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    cursor: clearCursor ? null : (cursor ?? this.cursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    hasMore,
    cursor,
    isLoadingMore,
    failure,
  ];
}
