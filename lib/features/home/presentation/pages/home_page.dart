import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_onboarding_card.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_selector_row.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_match_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_card.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/matchmaking_section.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_avatar.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_empty_state.dart';
import 'package:fifa_queue/features/teams/presentation/widgets/team_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;

        return AppScaffold(
          appBar: AppAppBar(title: l10n.homeTitle, subtitle: l10n.homeSubtitle),
          body: _HomeBody(state: state, selected: selected),
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.selected});

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

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        _TeamContextCard(
          userTeam: selected!,
          showSwitch: state.hasMultipleTeams,
          selectedTeamId: state.selectedTeamId,
          teams: state.teams,
        ),
        const SizedBox(height: AppSpacing.xl),
        BlocBuilder<FcAccountsCubit, FcAccountsState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.accounts != current.accounts,
          builder: (context, fcState) {
            if (fcState.isLoading && fcState.accounts.isEmpty) {
              return const SizedBox.shrink();
            }
            if (!fcState.hasAccounts) {
              return const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: FcAccountOnboardingCard(),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const FcAccountSelectorRow(),
                const GameModeSelector(),
                const SizedBox(height: AppSpacing.lg),
                const WeekendLeagueCard(),
                const PendingMatchCard(),
                MatchmakingSection(
                  teamId: selected!.id,
                  onMatchFound: () =>
                      context.read<PendingMatchCubit>().refreshSilently(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TeamContextCard extends StatelessWidget {
  const _TeamContextCard({
    required this.userTeam,
    required this.showSwitch,
    required this.selectedTeamId,
    required this.teams,
  });

  final UserTeam userTeam;
  final bool showSwitch;
  final String? selectedTeamId;
  final List<UserTeam> teams;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = userTeam.team;

    return AppCard(
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
                  style: context.textStyles.titleLarge,
                ),
                if (team.tag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    team.tag!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showSwitch)
            AppIconButton(
              icon: Icons.swap_horiz,
              tooltip: l10n.teamSwitchAction,
              variant: AppIconButtonVariant.surface,
              onPressed: () => showTeamSelectorSheet(
                context: context,
                teams: teams,
                selectedTeamId: selectedTeamId,
              ),
            ),
        ],
      ),
    );
  }
}
