import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/invitations/domain/entities/pending_invite.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class JoinTeamPage extends StatefulWidget {
  const JoinTeamPage({required this.inviteCode, super.key});

  final String inviteCode;

  @override
  State<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends State<JoinTeamPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInvite());
  }

  Future<void> _handleInvite() async {
    if (!mounted) {
      return;
    }
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
    if (!isAuthenticated) {
      await context.read<PendingInviteCubit>().capture(widget.inviteCode);
      return;
    }
    await _showInviteSheet();
  }

  Future<void> _showInviteSheet() async {
    final l10n = context.l10n;
    await showAppBottomSheet<void>(
      context: context,
      builder: (sheetContext) => AppBottomSheet(
        title: l10n.inviteTitle,
        subtitle: l10n.inviteCodeLabel(InviteCode.normalize(widget.inviteCode)),
        actions: <Widget>[
          AppButton(
            label: l10n.inviteJoinTeam,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionNotNow,
            expanded: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
        child: Text(
          l10n.inviteResolutionComingSoon,
          style: sheetContext.textStyles.bodyMedium,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    await context.read<PendingInviteCubit>().consume();
    if (mounted) {
      context.go(AppRoutes.home.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = InviteCode.normalize(widget.inviteCode);

    return AppScaffold(
      maxContentWidth: AppBreakpoints.maxFormWidth,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (!state.isResolved) {
            return const AppLoading();
          }
          if (state.isAuthenticated) {
            return AppLoading(message: l10n.inviteTitle);
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            children: <Widget>[
              const BrandMark(size: BrandMarkSize.large),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.inviteSignInRequiredTitle,
                style: context.textStyles.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.inviteSignInRequiredMessage,
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: AppBadge(
                  label: code,
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l10n.authSignIn,
                onPressed: () => context.go(AppRoutes.login.path),
              ),
            ],
          );
        },
      ),
    );
  }
}
