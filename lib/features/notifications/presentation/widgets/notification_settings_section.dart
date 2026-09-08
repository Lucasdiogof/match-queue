import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/notifications/application/push_token_coordinator.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_notification_type.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_settings_state.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/enable_notifications_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<NotificationSettingsCubit>(
    create: (_) => NotificationSettingsCubit(
      getIt<NotificationRepository>(),
      getIt<PushMessagingService>(),
      getIt<PushTokenCoordinator>(),
    )..load(),
    child: const _NotificationSettingsBody(),
  );
}

class _NotificationSettingsBody extends StatelessWidget {
  const _NotificationSettingsBody();

  Future<void> _enable(BuildContext context) async {
    final cubit = context.read<NotificationSettingsCubit>();
    final confirmed = await showEnableNotificationsSheet(context);
    if (confirmed) {
      await cubit.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) => AppCard(
        variant: AppCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.notificationsSectionTitle.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.status == NotificationSettingsStatus.loading)
              const SizedBox(height: 96, child: AppLoading.inline())
            else ...<Widget>[
              if (state.failure != null) ...<Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  message: state.failure!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _PermissionArea(state: state, onEnable: () => _enable(context)),
              _ToggleRow(
                label: l10n.notificationsToggleYourTurn,
                hint: l10n.notificationsToggleYourTurnHint,
                value: state.preferences.queueTurnEnabled,
                onChanged: (value) => context
                    .read<NotificationSettingsCubit>()
                    .setEnabled(PushNotificationType.yourTurn, value: value),
              ),
              _ToggleRow(
                label: l10n.notificationsToggleExpiring,
                hint: l10n.notificationsToggleExpiringHint,
                value: state.preferences.searchExpiringEnabled,
                onChanged: (value) =>
                    context.read<NotificationSettingsCubit>().setEnabled(
                      PushNotificationType.searchExpiring,
                      value: value,
                    ),
              ),
              _ToggleRow(
                label: l10n.notificationsToggleExpired,
                hint: l10n.notificationsToggleExpiredHint,
                value: state.preferences.searchExpiredEnabled,
                onChanged: (value) =>
                    context.read<NotificationSettingsCubit>().setEnabled(
                      PushNotificationType.searchExpired,
                      value: value,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionArea extends StatelessWidget {
  const _PermissionArea({required this.state, required this.onEnable});

  final NotificationSettingsState state;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final permission = state.permission;

    Widget? content;
    if (permission.canReceive) {
      content = null;
    } else if (permission == PushPermissionStatus.notDetermined) {
      content = AppButton.secondary(
        label: l10n.notificationsEnableCta,
        icon: Icons.notifications_active_outlined,
        onPressed: onEnable,
      );
    } else if (permission == PushPermissionStatus.denied) {
      content = _Hint(text: l10n.notificationsPermissionDeniedHint);
    } else {
      content = _Hint(text: l10n.notificationsUnsupportedHint);
    }

    if (content == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: content,
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(
        Icons.info_outline,
        size: AppSizing.iconMd,
        color: context.colors.textTertiary,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          text,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: context.textStyles.bodyLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                hint,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}
