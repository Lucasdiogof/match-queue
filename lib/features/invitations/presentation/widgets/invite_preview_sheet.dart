import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/invitations/domain/entities/invite_preview.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_resolution_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_resolution_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum InviteSheetOutcome { joinedOrOpened, dismissed, navigatedToAuth }

Future<InviteSheetOutcome?> showInvitePreviewSheet({
  required BuildContext context,
  required InviteResolutionCubit cubit,
}) => showAppBottomSheet<InviteSheetOutcome>(
  context: context,
  builder: (sheetContext) => BlocProvider<InviteResolutionCubit>.value(
    value: cubit,
    child: const _InvitePreviewSheetBody(),
  ),
);

class _InvitePreviewSheetBody extends StatelessWidget {
  const _InvitePreviewSheetBody();

  void _pop(BuildContext context, InviteSheetOutcome outcome) =>
      Navigator.of(context).pop(outcome);

  void _goToAuth(BuildContext context, String path) {
    _pop(context, InviteSheetOutcome.navigatedToAuth);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<InviteResolutionCubit, InviteResolutionState>(
        listenWhen: (previous, current) =>
            current.status == InviteResolutionStatus.joined,
        listener: (context, state) =>
            _pop(context, InviteSheetOutcome.joinedOrOpened),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) =>
              BlocBuilder<InviteResolutionCubit, InviteResolutionState>(
                builder: (context, state) => AppBottomSheet(
                  child: _Content(
                    state: state,
                    isAuthenticated: authState.isAuthenticated,
                    onJoin: () => context.read<InviteResolutionCubit>().join(),
                    onOpenTeam: () =>
                        _pop(context, InviteSheetOutcome.joinedOrOpened),
                    onNotNow: () => _pop(context, InviteSheetOutcome.dismissed),
                    onSignIn: () => _goToAuth(context, AppRoutes.login.path),
                    onCreateAccount: () =>
                        _goToAuth(context, AppRoutes.signUp.path),
                  ),
                ),
              ),
        ),
      );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.isAuthenticated,
    required this.onJoin,
    required this.onOpenTeam,
    required this.onNotNow,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final InviteResolutionState state;
  final bool isAuthenticated;
  final VoidCallback onJoin;
  final VoidCallback onOpenTeam;
  final VoidCallback onNotNow;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.status == InviteResolutionStatus.loading) {
      return const SizedBox(height: 220, child: AppLoading());
    }

    if (state.status == InviteResolutionStatus.failure) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: l10n.errorUnexpected,
        message: state.failure?.localizedMessage(l10n),
        actionLabel: l10n.actionClose,
        onAction: onNotNow,
      );
    }

    final preview = state.preview;
    if (preview == null) {
      return AppEmptyState(
        icon: Icons.link_off,
        title: l10n.inviteInvalidTitle,
        actionLabel: l10n.actionClose,
        onAction: onNotNow,
      );
    }

    return switch (preview.status) {
      InviteStatus.valid || InviteStatus.alreadyMember => _TeamPreview(
        preview: preview,
        isAuthenticated: isAuthenticated,
        isJoining: state.status == InviteResolutionStatus.joining,
        onJoin: onJoin,
        onOpenTeam: onOpenTeam,
        onNotNow: onNotNow,
        onSignIn: onSignIn,
        onCreateAccount: onCreateAccount,
      ),
      InviteStatus.invalid => _InviteProblem(
        icon: Icons.link_off,
        title: l10n.inviteInvalidTitle,
        onClose: onNotNow,
      ),
      InviteStatus.revoked => _InviteProblem(
        icon: Icons.block,
        title: l10n.inviteRevokedTitle,
        onClose: onNotNow,
      ),
      InviteStatus.expired => _InviteProblem(
        icon: Icons.hourglass_disabled,
        title: l10n.inviteExpiredTitle,
        onClose: onNotNow,
      ),
      InviteStatus.exhausted => _InviteProblem(
        icon: Icons.groups_outlined,
        title: l10n.inviteExhaustedTitle,
        onClose: onNotNow,
      ),
    };
  }
}

class _TeamPreview extends StatelessWidget {
  const _TeamPreview({
    required this.preview,
    required this.isAuthenticated,
    required this.isJoining,
    required this.onJoin,
    required this.onOpenTeam,
    required this.onNotNow,
    required this.onSignIn,
    required this.onCreateAccount,
  });

  final InvitePreview preview;
  final bool isAuthenticated;
  final bool isJoining;
  final VoidCallback onJoin;
  final VoidCallback onOpenTeam;
  final VoidCallback onNotNow;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAlreadyMember = preview.status == InviteStatus.alreadyMember;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _PreviewAvatar(name: preview.teamName ?? '', tag: preview.teamTag),
        const SizedBox(height: AppSpacing.lg),
        Text(
          preview.teamName ?? '',
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall,
        ),
        if (preview.teamTag != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          AppBadge(label: preview.teamTag!),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          isAlreadyMember
              ? l10n.inviteAlreadyMemberMessage
              : l10n.inviteJoinMessage,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        if (preview.memberCount != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.teamMembersCount(preview.memberCount!),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        if (isAlreadyMember)
          AppButton(label: l10n.inviteOpenTeam, onPressed: onOpenTeam)
        else if (isAuthenticated) ...<Widget>[
          AppButton(
            label: l10n.inviteJoinTeam,
            isLoading: isJoining,
            onPressed: isJoining ? null : onJoin,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionNotNow,
            expanded: true,
            onPressed: isJoining ? null : onNotNow,
          ),
        ] else ...<Widget>[
          AppButton(label: l10n.inviteSignInToAccept, onPressed: onSignIn),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.inviteCreateAccount,
            expanded: true,
            onPressed: onCreateAccount,
          ),
        ],
      ],
    );
  }
}

class _InviteProblem extends StatelessWidget {
  const _InviteProblem({
    required this.icon,
    required this.title,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: icon,
    title: title,
    actionLabel: context.l10n.actionClose,
    onAction: onClose,
  );
}

class _PreviewAvatar extends StatelessWidget {
  const _PreviewAvatar({required this.name, this.tag});

  final String name;
  final String? tag;

  String get _initials {
    final explicitTag = tag;
    if (explicitTag != null && explicitTag.isNotEmpty) {
      return explicitTag.substring(0, explicitTag.length.clamp(0, 3));
    }
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: AppSizing.avatarXl,
      height: AppSizing.avatarXl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceHighest,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Text(
        _initials,
        style: context.textStyles.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
