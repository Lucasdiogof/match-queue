import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/observability/analytics_service.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_link_picker_sheet.dart';
import 'package:fifa_queue/features/invitations/domain/repositories/invite_repository.dart';
import 'package:fifa_queue/features/invitations/domain/usecases/resolve_team_invite.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_resolution_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/invite_resolution_state.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/invite_preview_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class JoinTeamPage extends StatelessWidget {
  const JoinTeamPage({required this.inviteCode, super.key});

  final String inviteCode;

  @override
  Widget build(BuildContext context) => BlocProvider<InviteResolutionCubit>(
    create: (_) => InviteResolutionCubit(
      getIt<ResolveTeamInvite>(),
      getIt<InviteRepository>(),
    ),
    child: _JoinTeamView(inviteCode: inviteCode),
  );
}

class _JoinTeamView extends StatefulWidget {
  const _JoinTeamView({required this.inviteCode});

  final String inviteCode;

  @override
  State<_JoinTeamView> createState() => _JoinTeamViewState();
}

class _JoinTeamViewState extends State<_JoinTeamView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) {
      return;
    }
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
    if (!isAuthenticated) {
      await context.read<PendingInviteCubit>().capture(widget.inviteCode);
    }
    if (!mounted) {
      return;
    }
    await context.read<InviteResolutionCubit>().resolve(widget.inviteCode);
    if (!mounted) {
      return;
    }
    await getIt<AnalyticsService>().logEvent('invite_opened');
    await _showSheet();
  }

  Future<void> _showSheet() async {
    final cubit = context.read<InviteResolutionCubit>();
    final outcome = await showInvitePreviewSheet(
      context: context,
      cubit: cubit,
    );
    if (!mounted) {
      return;
    }
    await _handleOutcome(outcome, cubit.state);
  }

  Future<void> _handleOutcome(
    InviteSheetOutcome? outcome,
    InviteResolutionState state,
  ) async {
    switch (outcome) {
      case InviteSheetOutcome.joinedOrOpened:
        await _openTeam(state);
      case InviteSheetOutcome.dismissed:
        await context.read<PendingInviteCubit>().consume();
        if (mounted) {
          _leaveInvitePage();
        }
      case InviteSheetOutcome.navigatedToAuth:
      case null:
        break;
    }
  }

  Future<void> _openTeam(InviteResolutionState state) async {
    final joinResult = state.joinResult;
    final teamId = joinResult?.teamId ?? state.preview?.teamId;
    if (teamId == null) {
      return;
    }
    final userId = context.read<AuthCubit>().state.user?.id;
    if (userId != null) {
      final teamsCubit = context.read<TeamsCubit>();
      await teamsCubit.load(userId: userId);
      await teamsCubit.selectTeam(teamId);
    }
    final isNewJoin = joinResult != null && !joinResult.alreadyMember;
    if (isNewJoin) {
      await getIt<AnalyticsService>().logEvent('invite_accepted');
      if (mounted) {
        await _linkFcAccounts(teamId);
      }
    }
    if (!mounted) {
      return;
    }
    await context.read<PendingInviteCubit>().consume();
    if (mounted) {
      context.go(AppRoutes.home.path);
    }
  }

  /// Entrada nova de verdade (não reabertura de quem já era membro) exige
  /// pelo menos uma Conta FC vinculada (gameplay flows refresh, item 16).
  /// Sem nenhuma, leva pra criação e volta pro mesmo fluxo -- nunca
  /// conclui o vínculo sem Conta FC, mas também nunca desfaz a entrada no
  /// time (já é sócio; só falta dizer com qual Conta FC).
  Future<void> _linkFcAccounts(String teamId) async {
    final fcAccountsCubit = context.read<FcAccountsCubit>();
    if (!fcAccountsCubit.state.hasAccounts) {
      await context.push(AppRoutes.fcAccounts.path);
      if (!mounted) {
        return;
      }
    }
    final accounts = fcAccountsCubit.state.accounts;
    if (accounts.isEmpty) {
      return;
    }
    final selected = await showFcAccountLinkPickerSheet(
      context: context,
      accounts: accounts,
    );
    if (!mounted || selected == null) {
      return;
    }
    for (final accountId in selected) {
      await fcAccountsCubit.linkToTeam(accountId: accountId, teamId: teamId);
    }
  }

  void _leaveInvitePage() {
    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
    context.go(isAuthenticated ? AppRoutes.home.path : AppRoutes.login.path);
  }

  @override
  Widget build(BuildContext context) => const AppScaffold(
    body: Center(child: BrandMark(size: BrandMarkSize.large)),
  );
}
