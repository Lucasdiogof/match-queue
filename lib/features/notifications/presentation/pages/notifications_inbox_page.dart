import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_inbox_cubit.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_inbox_state.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_unread_cubit.dart';
import 'package:fifa_queue/features/notifications/presentation/notification_destination_resolver.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationInboxCubit>(
    create: (_) => NotificationInboxCubit(
      getIt<NotificationInboxRepository>(),
      context.read<NotificationUnreadCubit>(),
    )..load(),
    child: const _NotificationsInboxBody(),
  );
}

class _NotificationsInboxBody extends StatefulWidget {
  const _NotificationsInboxBody();

  @override
  State<_NotificationsInboxBody> createState() =>
      _NotificationsInboxBodyState();
}

class _NotificationsInboxBodyState extends State<_NotificationsInboxBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<NotificationInboxCubit>().loadMore();
    }
  }

  Future<void> _open(AppNotification notification) async {
    unawaited(context.read<NotificationInboxCubit>().markRead(notification.id));
    await NotificationDestinationResolver.open(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.notificationsInboxTitle,
        actions: <Widget>[
          BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
            builder: (context, state) => state.items.any((n) => n.isUnread)
                ? TextButton(
                    onPressed: () =>
                        context.read<NotificationInboxCubit>().markAllRead(),
                    child: Text(l10n.notificationsInboxMarkAllRead),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<NotificationInboxCubit, NotificationInboxState>(
        builder: (context, state) => switch (state.status) {
          NotificationInboxStatus.initial ||
          NotificationInboxStatus.loading => const AppLoading(),
          NotificationInboxStatus.failure when state.items.isEmpty =>
            AppErrorState(
              title: l10n.notificationsInboxErrorMessage,
              message: state.failure?.localizedMessage(l10n) ?? '',
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<NotificationInboxCubit>().refresh(),
            ),
          _ when state.isEmpty => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              const SizedBox(height: AppSpacing.huge),
              AppEmptyState(
                icon: Icons.notifications_none_outlined,
                title: l10n.notificationsInboxEmptyTitle,
                message: l10n.notificationsInboxEmptyMessage,
              ),
            ],
          ),
          _ => _GroupedList(
            state: state,
            scrollController: _scrollController,
            onTap: _open,
          ),
        },
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.state,
    required this.scrollController,
    required this.onTap,
  });

  final NotificationInboxState state;
  final ScrollController scrollController;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = _group(state.items);
    final entries = groups.entries.toList(growable: false);

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationInboxCubit>().refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount:
            entries.fold<int>(0, (sum, e) => sum + 1 + e.value.length) +
            (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          var remaining = index;
          for (final entry in entries) {
            if (remaining == 0) {
              return Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  _groupLabel(l10n, entry.key),
                  style: context.textStyles.labelSmall,
                ),
              );
            }
            remaining--;
            if (remaining < entry.value.length) {
              final notification = entry.value[remaining];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NotificationTile(
                  notification: notification,
                  onTap: () => onTap(notification),
                ),
              );
            }
            remaining -= entry.value.length;
          }
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: AppLoading.inline(),
          );
        },
      ),
    );
  }

  Map<_Group, List<AppNotification>> _group(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final grouped = <_Group, List<AppNotification>>{};

    for (final item in items) {
      final local = item.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final group = day == today
          ? _Group.today
          : day == yesterday
          ? _Group.yesterday
          : _Group.earlier;
      grouped.putIfAbsent(group, () => <AppNotification>[]).add(item);
    }
    return grouped;
  }

  String _groupLabel(AppLocalizations l10n, _Group group) => switch (group) {
    _Group.today => l10n.notificationsGroupToday,
    _Group.yesterday => l10n.notificationsGroupYesterday,
    _Group.earlier => l10n.notificationsGroupEarlier,
  };
}

enum _Group { today, yesterday, earlier }
