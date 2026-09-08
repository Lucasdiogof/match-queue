import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/presentation/notification_copy_resolver.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final unread = notification.isUnread;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      variant: unread ? AppCardVariant.elevated : AppCardVariant.surface,
      // Destaque discreto (item 37): borda sutil, nunca vermelho.
      borderColor: unread ? colors.info.withValues(alpha: 0.4) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: AppSizing.iconLg / 2,
            backgroundColor: colors.surfaceElevated,
            child: Icon(
              NotificationCopyResolver.iconFor(notification.category),
              color: colors.textSecondary,
              size: AppSizing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  NotificationCopyResolver.textFor(l10n, notification),
                  style: unread
                      ? context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : context.textStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.historyEntryTime(notification.createdAt.toLocal()),
                  style: context.textStyles.labelSmall,
                ),
              ],
            ),
          ),
          if (unread) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: colors.info,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
