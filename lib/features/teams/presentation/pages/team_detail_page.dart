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
import 'package:fifa_queue/features/teams/domain/entities/team_sports_dashboard.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_sports_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/team_status_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_sports_sections.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Detalhe do Time (Etapa 11, item 5): nome, tag, lista de jogadores,
/// status operacional. As configuracoes/engrenagem do time ficam AQUI, nao
/// mais na lista.
class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context) => BlocBuilder<TeamsCubit, TeamsState>(
    builder: (context, state) {
      final userTeam = _findTeam(state, teamId);

      return AppScaffold(
        appBar: AppAppBar(
          title: userTeam?.team.name ?? context.l10n.teamTitle,
          subtitle: userTeam?.team.tag,
          actions: <Widget>[
            if (userTeam != null && userTeam.canManageTeam)
              AppIconButton(
                icon: Icons.settings_outlined,
                tooltip: context.l10n.teamManageAction,
                variant: AppIconButtonVariant.surface,
                onPressed: () => context.push(AppRoutes.teamSettings.path),
              ),
          ],
        ),
        body: userTeam == null
            ? const AppLoading()
            : MultiBlocProvider(
                key: ValueKey(teamId),
                providers: <BlocProvider<dynamic>>[
                  BlocProvider<TeamStatusCubit>(
                    create: (_) => TeamStatusCubit(
                      getIt<TeamRepository>(),
                      getIt<MatchmakingRepository>(),
                      teamId: teamId,
                    )..start(),
                  ),
                  // Dashboard esportivo so carrega ao ENTRAR no Time
                  // (item 50) -- a lista de Times continua leve.
                  BlocProvider<TeamSportsCubit>(
                    create: (_) =>
                        TeamSportsCubit(getIt<TeamRepository>(), teamId: teamId)
                          ..load(),
                  ),
                ],
                child: _TeamStatusBody(team: userTeam.team),
              ),
      );
    },
  );

  UserTeam? _findTeam(TeamsState state, String teamId) {
    for (final userTeam in state.teams) {
      if (userTeam.id == teamId) {
        return userTeam;
      }
    }
    return null;
  }
}

class _TeamStatusBody extends StatelessWidget {
  const _TeamStatusBody({required this.team});

  final Team team;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TeamStatusCubit, TeamStatusState>(
    builder: (context, state) => BlocBuilder<TeamSportsCubit, TeamSportsState>(
      builder: (context, sports) => RefreshIndicator(
        onRefresh: context.read<TeamSportsCubit>().refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          children: <Widget>[
            _TeamHeaderCard(
              team: team,
              state: state,
              dashboard: sports.dashboard,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Status operacional continua sendo do Realtime da Etapa
            // anterior -- stats nunca se misturam com ele (item 46).
            _MemberStatusSection(teamId: team.id, state: state),
            if (sports.dashboard != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              TeamSportsSummarySection(summary: sports.dashboard!.summary),
              if (sports.dashboard!.summary.hasMatches) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                TeamSportsRankingSection(
                  ranking: sports.dashboard!.ranking,
                  minRankedMatches: sports.dashboard!.minRankedMatches,
                  onMemberTap: (member) => context.push(
                    AppRoutes.playerProfileLocation(team.id, member.userId),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TeamPlayerLeaderboardSection(
                  entries: sports.dashboard!.topScorers,
                  byAssists: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                TeamPlayerLeaderboardSection(
                  entries: sports.dashboard!.topAssists,
                  byAssists: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                TeamWeekendLeagueSection(
                  entries: sports.dashboard!.weekendLeague,
                ),
                const SizedBox(height: AppSpacing.lg),
                TeamRivalsSection(entries: sports.dashboard!.rivals),
                const SizedBox(height: AppSpacing.lg),
                TeamSportsActivitySection(activity: sports.dashboard!.activity),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}

class _TeamHeaderCard extends StatelessWidget {
  const _TeamHeaderCard({
    required this.team,
    required this.state,
    this.dashboard,
  });

  final Team team;
  final TeamStatusState state;
  final TeamSportsDashboard? dashboard;

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
                if (dashboard != null &&
                    dashboard!.summary.hasMatches) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.teamSportsMatchesCount(dashboard!.summary.matches),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatusSection extends StatelessWidget {
  const _MemberStatusSection({required this.teamId, required this.state});

  final String teamId;
  final TeamStatusState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.teamDetailPlayersTitle.toUpperCase(),
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
              _MemberStatusRow(teamId: teamId, member: member),
        ],
      ),
    );
  }
}

class _MemberStatusRow extends StatelessWidget {
  const _MemberStatusRow({required this.teamId, required this.member});

  final String teamId;
  final TeamMemberStatus member;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () =>
        context.push(AppRoutes.playerProfileLocation(teamId, member.userId)),
    child: Padding(
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
    ),
  );
}
