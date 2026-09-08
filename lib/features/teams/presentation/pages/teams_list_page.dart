import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/domain/repositories/team_repository.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Item de menu "Times" (Etapa 11, item 5): so a LISTA dos times do usuario,
/// com contagem. Nenhuma lista de jogadores aqui -- isso mora no Detalhe do
/// Time, aberto ao tocar uma linha.
class TeamsListPage extends StatelessWidget {
  const TeamsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) => AppScaffold(
        appBar: AppAppBar(
          title: l10n.navTeam,
          subtitle: l10n.teamsListSubtitle,
        ),
        body: _TeamsListBody(state: state),
      ),
    );
  }
}

class _TeamsListBody extends StatelessWidget {
  const _TeamsListBody({required this.state});

  final TeamsState state;

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

    if (!state.hasTeams) {
      return const TeamEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      children: <Widget>[
        for (final userTeam in state.teams) ...<Widget>[
          _TeamListRow(userTeam: userTeam),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
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
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
