import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/observability/analytics_service.dart';
import 'package:fifa_queue/core/platform/invite_link_builder.dart';
import 'package:fifa_queue/core/platform/share_service.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_management_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_management_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InviteSection extends StatelessWidget {
  const InviteSection({required this.teamId, required this.canManage, super.key});

  final String teamId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => BlocProvider<InviteManagementCubit>(
    key: ValueKey(teamId),
    create: (_) => InviteManagementCubit(getIt<InviteRepository>(), teamId: teamId)
      ..load(),
    child: _InviteSectionBody(canManage: canManage),
  );
}

class _InviteSectionBody extends StatelessWidget {
  const _InviteSectionBody({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l10n.inviteSectionTitle, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.inviteSectionSubtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          BlocBuilder<InviteManagementCubit, InviteManagementState>(
            builder: (context, state) => switch (state.status) {
              InviteManagementStatus.loading => const SizedBox(
                height: 72,
                child: AppLoading.inline(),
              ),
              InviteManagementStatus.failure => AppBanner(
                tone: AppBannerTone.danger,
                message:
                    state.failure?.localizedMessage(l10n) ??
                    l10n.errorUnexpected,
              ),
              InviteManagementStatus.ready => _InviteLinkBody(
                code: state.invite?.code,
                isRotating: state.isRotating,
                isRevoking: state.isRevoking,
                canManage: canManage,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _InviteLinkBody extends StatelessWidget {
  const _InviteLinkBody({
    required this.code,
    required this.isRotating,
    required this.isRevoking,
    required this.canManage,
  });

  final String? code;
  final bool isRotating;
  final bool isRevoking;
  final bool canManage;

  Future<void> _copy(BuildContext context, String code) async {
    final target = getIt<InviteLinkBuilder>().build(code);
    final text = switch (target) {
      InviteShareUrl(:final url) => url,
      InviteShareCodeOnly(:final code) => code,
    };
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.inviteLinkCopied;
    await getIt<ShareService>().copyToClipboard(text);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share(BuildContext context, String code) async {
    final l10n = context.l10n;
    final target = getIt<InviteLinkBuilder>().build(code);
    final text = switch (target) {
      InviteShareUrl(:final url) => l10n.inviteShareMessage(url),
      InviteShareCodeOnly(:final code) => l10n.inviteShareMessageCodeOnly(code),
    };
    await getIt<AnalyticsService>().logEvent('invite_shared');
    await getIt<ShareService>().share(text, subject: l10n.inviteShareSubject);
  }

  Future<void> _confirmRotate(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<InviteManagementCubit>();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: l10n.inviteRotateConfirmTitle,
        message: l10n.inviteRotateConfirmMessage,
        confirmLabel: l10n.inviteRotateAction,
        cancelLabel: l10n.actionCancel,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) {
      await cubit.rotate();
    }
  }

  Future<void> _confirmRevoke(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<InviteManagementCubit>();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: l10n.inviteRevokeConfirmTitle,
        message: l10n.inviteRevokeConfirmMessage,
        confirmLabel: l10n.inviteRevokeAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) {
      await cubit.revoke();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentCode = code;

    if (currentCode == null) {
      return canManage
          ? AppButton.secondary(
              label: l10n.inviteCreateLinkAction,
              icon: Icons.add_link,
              onPressed: () => context.read<InviteManagementCubit>().load(),
            )
          : Text(l10n.inviteUnavailableMessage, style: context.textStyles.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceHighest,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: context.colors.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.link, color: context.colors.textSecondary, size: AppSizing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  currentCode,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton.secondary(
                label: l10n.actionCopy,
                icon: Icons.copy_outlined,
                onPressed: () => _copy(context, currentCode),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: l10n.actionShare,
                icon: Icons.ios_share,
                onPressed: () => _share(context, currentCode),
              ),
            ),
          ],
        ),
        if (canManage) ...<Widget>[
          const AppDivider(spacing: AppSpacing.xl),
          Text(l10n.inviteManageTitle.toUpperCase(), style: context.textStyles.labelSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.secondary(
                  label: l10n.inviteRotateAction,
                  icon: Icons.refresh,
                  isLoading: isRotating,
                  onPressed: isRotating || isRevoking
                      ? null
                      : () => _confirmRotate(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: l10n.inviteRevokeAction,
                  icon: Icons.link_off,
                  isLoading: isRevoking,
                  onPressed: isRotating || isRevoking
                      ? null
                      : () => _confirmRevoke(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
