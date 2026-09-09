import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/invitations/presentation/widgets/join_by_code_sheet.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/public_teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/create_team_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Times: aba "Meus Times" (Etapa 11, item 5) + aba "Explorar" (so times
/// publicos, UI/UX refresh). Acoes de criar/entrar em time vivem no header
/// desta tela agora -- pararam de duplicar o empty state em 3 telas.
class TeamsListPage extends StatefulWidget {
  const TeamsListPage({super.key});

  @override
  State<TeamsListPage> createState() => _TeamsListPageState();
}

class _TeamsListPageState extends State<TeamsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PublicTeamsCubit _publicTeamsCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _publicTeamsCubit = PublicTeamsCubit(getIt<TeamRepository>())..load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _publicTeamsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        actions: <Widget>[
          AppIconButton(
            icon: Icons.qr_code_2_outlined,
            tooltip: l10n.teamHaveInviteCode,
            onPressed: () => showJoinByCodeSheet(context),
          ),
          AppIconButton(
            icon: Icons.add,
            tooltip: l10n.teamCreateCta,
            onPressed: () => showCreateTeamSheet(context),
          ),
        ],
      ),
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FeatureHeader(eyebrow: l10n.teamsEyebrow, title: l10n.navTeam),
            TabBar(
              controller: _tabController,
              tabs: <Widget>[
                Tab(text: l10n.teamsMineTab),
                Tab(text: l10n.teamsExploreTab),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  const _MyTeamsTab(),
                  BlocProvider<PublicTeamsCubit>.value(
                    value: _publicTeamsCubit,
                    child: const _ExploreTeamsTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTeamsTab extends StatelessWidget {
  const _MyTeamsTab();

  @override
  Widget build(BuildContext context) => BlocBuilder<TeamsCubit, TeamsState>(
    builder: (context, state) {
      final l10n = context.l10n;

      if (state.isLoading && !state.hasTeams) {
        return const AppLoading();
      }

      if (state.status == TeamsStatus.failure && !state.hasTeams) {
        return AppErrorState(
          title: l10n.teamLoadErrorTitle,
          message:
              state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
          retryLabel: l10n.actionRetry,
          onRetry: () => context.read<TeamsCubit>().refresh(),
        );
      }

      if (!state.hasTeams) {
        return AppEmptyState(
          icon: Icons.groups_2_outlined,
          title: l10n.teamNoTeamTitle,
          message: l10n.teamNoTeamMessage,
        );
      }

      return ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          for (final userTeam in state.teams) ...<Widget>[
            _TeamListRow(userTeam: userTeam),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    },
  );
}

class _TeamListRow extends StatelessWidget {
  const _TeamListRow({required this.userTeam});

  final UserTeam userTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final team = userTeam.team;

    return AppCard(
      onTap: () async {
        await context.read<TeamsCubit>().selectTeam(team.id);
        if (context.mounted) {
          await context.push(AppRoutes.teamDetailLocation(team.id));
        }
      },
      child: Row(
        children: <Widget>[
          TeamAvatar(team: team, size: AppSizing.avatarLg),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  team.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                ),
                if (team.tag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    team.tag!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                FutureBuilder<List<TeamMemberStatus>>(
                  future: getIt<TeamRepository>().fetchPlayerStatuses(team.id),
                  builder: (context, snapshot) {
                    final members = snapshot.data;
                    if (members == null) {
                      return Text(
                        '…',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      );
                    }
                    final active = members
                        .where(
                          (member) =>
                              member.status != PlayerOperationalStatus.offline,
                        )
                        .length;
                    return Text(
                      '${l10n.teamMembersCount(members.length)} · '
                      '${l10n.teamActiveCount(active)}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          AppBadge(
            label: team.isPublic
                ? l10n.teamVisibilityPublic
                : l10n.teamVisibilityPrivate,
            tone: team.isPublic ? AppBadgeTone.success : AppBadgeTone.neutral,
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}

class _ExploreTeamsTab extends StatelessWidget {
  const _ExploreTeamsTab();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PublicTeamsCubit, PublicTeamsState>(
        builder: (context, state) {
          final l10n = context.l10n;

          if (state.isLoading) {
            return const AppLoading();
          }

          if (state.status == PublicTeamsStatus.failure) {
            return AppErrorState(
              title: l10n.errorUnexpected,
              message:
                  state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<PublicTeamsCubit>().load(),
            );
          }

          if (state.teams.isEmpty) {
            return AppEmptyState(
              icon: Icons.travel_explore_outlined,
              title: l10n.teamsExploreEmptyTitle,
              message: l10n.teamsExploreEmptyMessage,
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            children: <Widget>[
              for (final summary in state.teams) ...<Widget>[
                _PublicTeamRow(summary: summary),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      );
}

class _PublicTeamRow extends StatelessWidget {
  const _PublicTeamRow({required this.summary});

  final PublicTeamSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: () => context.push(AppRoutes.publicTeamLocation(summary.id)),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: AppSizing.avatarMd / 2,
            backgroundColor: colors.surfaceHighest,
            backgroundImage: summary.logoUrl != null
                ? NetworkImage(summary.logoUrl!)
                : null,
            child: summary.logoUrl == null
                ? Text(
                    summary.name.substring(0, 1).toUpperCase(),
                    style: context.textStyles.titleMedium,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  summary.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                ),
                if (summary.tag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    summary.tag!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.teamMembersCount(summary.memberCount),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
