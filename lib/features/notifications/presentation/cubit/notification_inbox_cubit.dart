import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_inbox_state.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_unread_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationInboxCubit extends Cubit<NotificationInboxState> {
  NotificationInboxCubit(this._repository, this._unreadCubit)
    : super(const NotificationInboxState());

  final NotificationInboxRepository _repository;
  final NotificationUnreadCubit _unreadCubit;

  static const int _pageSize = 20;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: NotificationInboxStatus.loading,
        clearFailure: true,
      ),
    );
    try {
      final page = await _repository.fetchNotifications(limit: _pageSize);
      if (!isClosed) {
        emit(
          NotificationInboxState(
            status: NotificationInboxStatus.ready,
            items: page.items,
            hasMore: page.hasMore,
            cursor: page.nextCursor,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: NotificationInboxStatus.failure,
            failure: failure,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.cursor == null) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchNotifications(
        limit: _pageSize,
        cursor: state.cursor,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            items: <AppNotification>[...state.items, ...page.items],
            hasMore: page.hasMore,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            isLoadingMore: false,
          ),
        );
      }
    } on AppFailure {
      if (!isClosed) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> refresh() => load();

  /// Chamada ao abrir o destino de um item (item 80/81): marca so ESSE item,
  /// nunca a lista inteira. Falha aqui nunca bloqueia a navegacao que ja
  /// aconteceu -- so nao reconciliamos o estado local.
  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((n) => n.id == id);
    if (index == -1 || state.items[index].isUnread == false) {
      return;
    }
    final updated = List<AppNotification>.of(state.items);
    updated[index] = updated[index].copyWithRead();
    emit(state.copyWith(items: updated));
    _unreadCubit.decrementBy(1);

    try {
      await _repository.markRead(id);
    } on AppFailure {
      // Best effort: o proximo refresh reconcilia se o backend nao aplicou.
    }
  }

  Future<void> markAllRead() async {
    final unreadCount = state.items.where((n) => n.isUnread).length;
    if (unreadCount == 0) {
      return;
    }
    emit(
      state.copyWith(
        items: <AppNotification>[
          for (final item in state.items) item.copyWithRead(),
        ],
      ),
    );
    _unreadCubit.decrementBy(unreadCount);

    try {
      await _repository.markAllRead();
    } on AppFailure {
      // Idem: reconciliacao fica para o proximo load/refresh.
    }
  }
}
