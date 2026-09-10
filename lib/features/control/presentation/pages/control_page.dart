import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_onboarding_card.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/fc_account_selector_row.dart';
import 'package:fifa_queue/features/fc_squads/presentation/widgets/squad_selector_row.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_match_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/rivals_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_card.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/matchmaking_section.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Jogar e o hub operacional: conta ativa, squad, modo e fila. Nada de
/// vitrine de catalogo aqui -- explorar cartas e ver clubes nao sao o que
/// alguem vem fazer nesta tela.
class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;
        return AppScaffold(
          appBar: const AppAppBar(actions: <Widget>[NotificationBellButton()]),
          body: AppBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FeatureHeader(
                  eyebrow: l10n.controlEyebrow,
                  title: l10n.controlTitle,
                  subtitle: l10n.controlSubtitle,
                ),
                Expanded(
                  child: _ControlBody(state: state, selected: selected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlBody extends StatelessWidget {
  const _ControlBody({required this.state, required this.selected});

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

    // Sem time o bloqueio real depende de onde o usuario esta na ordem
    // Conta FC -> Time. Uma mensagem so para os dois casos mandava criar
    // conta quem ja tinha, e pedia para "escolher um modo" quem nem time
    // tem -- instrucao que nao resolve nada.
    if (selected == null) {
      return RefreshIndicator(
        onRefresh: () => Future.wait(<Future<void>>[
          context.read<TeamsCubit>().refresh(),
          context.read<FcAccountsCubit>().refresh(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: <Widget>[
            BlocBuilder<FcAccountsCubit, FcAccountsState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.hasAccounts != current.hasAccounts,
              builder: (context, fcState) {
                if (fcState.isLoading && fcState.accounts.isEmpty) {
                  return const SizedBox.shrink();
                }
                if (!fcState.hasAccounts) {
                  return const FcAccountOnboardingCard();
                }
                return AppEmptyState(
                  icon: Icons.groups_outlined,
                  title: l10n.controlNoTeamTitle,
                  message: l10n.controlNoTeamMessage,
                  actionLabel: l10n.controlNoTeamAction,
                  onAction: () => context.go(AppRoutes.team.path),
                );
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.wait(<Future<void>>[
        context.read<TeamsCubit>().refresh(),
        context.read<FcAccountsCubit>().refresh(),
      ]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          BlocBuilder<FcAccountsCubit, FcAccountsState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.accounts != current.accounts ||
                previous.selectedAccountId != current.selectedAccountId,
            builder: (context, fcState) {
              if (fcState.isLoading && fcState.accounts.isEmpty) {
                return const SizedBox.shrink();
              }
              if (!fcState.hasAccounts) {
                return const FcAccountOnboardingCard();
              }
              final account = fcState.selectedAccount;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Ordem: onde estou (Rivals/Weekend League/pendencia) ->
                // quem sou (conta) -> com que time jogo (squad) -> o que
                // vou jogar (modo) -> a fila. Os 3 cards de status vieram
                // da extinta Home -- sem ela, o unico lugar que ja tinha
                // contexto de Conta FC pra mostra-los e aqui.
                children: <Widget>[
                  const WeekendLeagueCard(),
                  const RivalsCard(),
                  const PendingMatchCard(),
                  const FcAccountSelectorRow(),
                  const SizedBox(height: AppSpacing.sm),
                  const SquadSelectorRow(),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.gameModeSectionTitle,
                          style: context.textStyles.labelSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const GameModeSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (account != null)
                    MatchmakingSection(
                      fcAccountId: account.id,
                      onMatchFound: () =>
                          context.read<PendingMatchCubit>().refreshSilently(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
