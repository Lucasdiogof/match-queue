import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/account/presentation/widgets/platform_onboarding_card.dart';
import 'package:fifa_queue/features/account/presentation/widgets/account_squad_card.dart';
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
          appBar: AppAppBar(
            title: l10n.navControl,
            accentTitle: true,
            actions: const <Widget>[NotificationBellButton()],
          ),
          body: AppBackground(
            // Unica tela com halo tingido: o verde nasce atras da area
            // de busca, que e o assunto da tela. Nas outras o halo segue
            // neutro -- se todas tivessem cor, nenhuma teria.
            glow: context.colors.accent,
            glowAlignment: const Alignment(0.15, 0.35),
            child: _ControlBody(state: state, selected: selected),
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

    // Sem time o bloqueio real depende de onde o usuario esta: quem ainda
    // nao tem time entra num fluxo, quem ja tem mas so nao selecionou
    // um modo cairia numa instrucao diferente que nao resolve nada.
    if (selected == null) {
      return RefreshIndicator(
        onRefresh: () => Future.wait(<Future<void>>[
          context.read<TeamsCubit>().refresh(),
          context.read<AccountCubit>().refresh(),
        ]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: <Widget>[
            // Plataformas e Elenco nao dependem de time nenhum, entao o
            // card continua aqui mesmo sem time: e daqui que quem ainda nao
            // entrou em nenhum time configura o que ja da pra configurar.
            // So o card de busca/modo (que depende de time) fica de fora.
            const AccountSquadCard(),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<AccountCubit, AccountState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.account != current.account,
              builder: (context, fcState) {
                if (fcState.isLoading && fcState.account == null) {
                  return const SizedBox.shrink();
                }
                if (fcState.needsOnboarding) {
                  return const PlatformOnboardingCard();
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
        context.read<AccountCubit>().refresh(),
      ]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          BlocBuilder<AccountCubit, AccountState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.account != current.account ||
                previous.status != current.status,
            builder: (context, fcState) {
              if (fcState.isLoading && fcState.account == null) {
                return const SizedBox.shrink();
              }
              if (fcState.needsOnboarding) {
                return const PlatformOnboardingCard();
              }
              final account = fcState.account;
              if (account == null) {
                return const SizedBox.shrink();
              }
              final team = selected!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Matchmaking primeiro. A ordem antiga abria com progresso
                // competitivo, entao a primeira dobra falava do fim de
                // semana passado em vez de "voce pode buscar agora". Agora a
                // dobra responde: que plataforma, que elenco, que modo,
                // quem esta na fila, e o botao. Champions e Rivals sao
                // consequencia -- vem depois.
                children: <Widget>[
                  const AccountSquadCard(),
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
                  const SizedBox(height: AppSpacing.lg),
                  MatchmakingSection(userId: account.id, teamId: team.id),
                  const SizedBox(height: AppSpacing.xl),
                  const WeekendLeagueCard(),
                  const RivalsCard(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
