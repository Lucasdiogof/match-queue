import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_empty_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_selector_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;

        return AppScaffold(
          appBar: AppAppBar(
            title: l10n.teamTitle,
            subtitle: l10n.teamSubtitle,
            actions: <Widget>[
              if (state.hasMultipleTeams)
                AppIconButton(
                  icon: Icons.swap_horiz,
                  tooltip: l10n.teamSwitchAction,
                  variant: AppIconButtonVariant.surface,
                  onPressed: () => showTeamSelectorSheet(
                    context: context,
                    teams: state.teams,
                    selectedTeamId: state.selectedTeamId,
                  ),
                ),
              if (selected != null)
                AppIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.teamManageAction,
                  variant: AppIconButtonVariant.surface,
                  onPressed: () => context.push(AppRoutes.teamSettings.path),
                ),
            ],
          ),
          body: _TeamBody(state: state, selected: selected),
        );
      },
    );
  }
}

class _TeamBody extends StatelessWidget {
  const _TeamBody({required this.state, required this.selected});

  final TeamsState state;
  final UserTeam? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.isLoading && !state.hasTeams) {
      return const AppLoading();
    }

    if (state.status == TeamsStatus.failure && !state.hasTeams) {
      return AppErrorState(
        title: l10n.teamLoadErrorTitle,
        message: state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
        retryLabel: l10n.actionRetry,
        onRetry: () => context.read<TeamsCubit>().refresh(),
      );
    }

    if (selected == null) {
      return const TeamEmptyState();
    }

    return BlocProvider<TeamStatusCubit>(
      key: ValueKey(selected!.id),
      create: (_) => TeamStatusCubit(
        getIt<TeamRepository>(),
        getIt<MatchmakingRepository>(),
        teamId: selected!.id,
      )..start(),
      child: _TeamStatusBody(team: selected!.team),
    );
  }
}

class _TeamStatusBody extends StatelessWidget {
  const _TeamStatusBody({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TeamStatusCubit, TeamStatusState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          children: <Widget>[
            _TeamHeaderCard(team: team, state: state),
            const SizedBox(height: AppSpacing.lg),
            _MemberStatusSection(state: state),
          ],
        ),
      );
}

class _TeamHeaderCard extends StatelessWidget {
  const _TeamHeaderCard({required this.team, required this.state});

  final Team team;
  final TeamStatusState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TeamAvatar(team: team, size: AppSizing.avatarXl),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(team.name, style: context.textStyles.headlineSmall),
                if (team.tag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  AppBadge(label: team.tag!),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.teamMembersCount(state.members.length)} · '
                  '${l10n.teamActiveCount(state.activeCount)}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatusSection extends StatelessWidget {
  const _MemberStatusSection({required this.state});

  final TeamStatusState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.teamMembersTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.status == TeamStatusLoadStatus.loading)
            const SizedBox(height: 72, child: AppLoading.inline())
          else if (state.status == TeamStatusLoadStatus.failure)
            AppBanner(
              tone: AppBannerTone.danger,
              message:
                  state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
            )
          else
            for (final member in state.members)
              _MemberStatusRow(member: member),
        ],
      ),
    );
  }
}

class _MemberStatusRow extends StatelessWidget {
  const _MemberStatusRow({required this.member});

  final TeamMemberStatus member;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: <Widget>[
        AppAvatar(
          label: member.displayName,
          imageUrl: member.avatarUrl,
          size: AppSizing.avatarMd,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            member.displayName,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyLarge,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TeamStatusBadge(member: member),
      ],
    ),
  );
}
