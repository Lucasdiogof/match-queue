import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/invite_section.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/edit_team_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_duration.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_empty_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_role_l10n.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    final userTeam = selected!;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        _TeamHeaderCard(userTeam: userTeam),
        const SizedBox(height: AppSpacing.lg),
        _MembersSection(state: state),
        const SizedBox(height: AppSpacing.lg),
        InviteSection(teamId: userTeam.id, canManage: userTeam.canManageTeam),
      ],
    );
  }
}

class _TeamHeaderCard extends StatelessWidget {
  const _TeamHeaderCard({required this.userTeam});

  final UserTeam userTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = userTeam.team;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                      teamDurationLabel(
                        l10n,
                        team.defaultSearchDuration.inSeconds,
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (userTeam.canManageTeam) ...<Widget>[
            const AppDivider(spacing: AppSpacing.xl),
            AppButton.secondary(
              label: l10n.teamManageAction,
              icon: Icons.tune,
              onPressed: () => showEditTeamSheet(context, team),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.state});

  final TeamsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentUserId = context.read<AuthCubit>().state.user?.id;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                l10n.teamMembersTitle.toUpperCase(),
                style: context.textStyles.labelSmall,
              ),
              Text(
                l10n.teamMembersCount(state.members.length),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.membersStatus == TeamMembersStatus.loading)
            const SizedBox(height: 72, child: AppLoading.inline())
          else if (state.membersStatus == TeamMembersStatus.failure)
            AppBanner(
              tone: AppBannerTone.danger,
              message:
                  state.membersFailure?.localizedMessage(l10n) ??
                  l10n.teamMembersErrorTitle,
            )
          else
            for (final member in state.members)
              _MemberRow(
                member: member,
                isCurrentUser: member.userId == currentUserId,
              ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isCurrentUser});

  final TeamMember member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: member.displayName,
            imageUrl: member.profile.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    member.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyLarge,
                  ),
                ),
                if (isCurrentUser) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '· ${l10n.teamYou}',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppBadge(
            label: member.role.label(l10n),
            tone: member.role.badgeTone,
          ),
        ],
      ),
    );
  }
}
