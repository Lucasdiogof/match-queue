import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/account/presentation/widgets/platform_onboarding_card.dart';
import 'package:fifa_queue/features/account/presentation/widgets/account_squad_card.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/game/presentation/widgets/rivals_card.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_card.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/game_mode.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/game_mode_cubit.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/matchmaking_section.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_membership.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
    buildWhen: (previous, current) =>
        previous.status != current.status ||
        previous.account != current.account ||
        previous.failure != current.failure ||
        previous.cachedAt != current.cachedAt,
    builder: (context, accountState) => _ResumeRevalidator(
      enabled:
          _isStale(accountState) ||
          (accountState.account == null &&
              accountState.status == AccountStatus.failure),
      onResume: () => _revalidate(context, stale: true),
      child: _buildContent(context, accountState),
    ),
  );

  /// Os dados mostrados vieram do cache local e a ultima tentativa de
  /// atualizar falhou -- e o que separa "carregando" de "sem conexao".
  bool _isStale(AccountState accountState) =>
      (accountState.isFromCache && accountState.failure != null) ||
      (state.isFromCache && state.failure != null);

  Future<void> _revalidate(BuildContext context, {required bool stale}) {
    final accountCubit = context.read<AccountCubit>();
    final user = context.read<AuthCubit>().state.user;
    return Future.wait(<Future<void>>[
      // Cache mostrado: precisa de um load completo (que tambem revalida a
      // conta do zero); sem isso o refresh silencioso bastaria.
      if (stale && user != null)
        accountCubit.load(fallbackDisplayName: user.shortName, userId: user.id)
      else
        accountCubit.refresh(),
      context.read<TeamsCubit>().refresh(),
    ]);
  }

  Widget _buildContent(BuildContext context, AccountState accountState) {
    final l10n = context.l10n;
    final stale = _isStale(accountState);

    // Sem conta nao ha o que mostrar: nunca deixar a tela vazia. Ou esta
    // carregando, ou falhou -- e falha de rede ganha texto proprio.
    if (accountState.account == null) {
      if (accountState.status != AccountStatus.failure) {
        return const AppLoading();
      }
      final failure = accountState.failure;
      final offline = failure is NetworkFailure || failure is TimeoutFailure;
      final user = context.read<AuthCubit>().state.user;
      return AppErrorState(
        title: offline ? l10n.playOfflineEmptyTitle : l10n.teamLoadErrorTitle,
        message: offline
            ? l10n.playOfflineEmptyMessage
            : (failure?.localizedMessage(l10n) ?? l10n.errorUnexpected),
        retryLabel: l10n.actionRetry,
        onRetry: user == null
            ? null
            : () => context.read<AccountCubit>().load(
                fallbackDisplayName: user.shortName,
                userId: user.id,
              ),
      );
    }

    final staleBanner = stale
        ? _StaleDataBanner(
            accountState: accountState,
            teamsState: state,
            onRetry: () => _revalidate(context, stale: true),
          )
        : null;

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
        onRefresh: () => _revalidate(context, stale: stale),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: <Widget>[
            ?staleBanner,
            if (staleBanner != null) const SizedBox(height: AppSpacing.lg),
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
      onRefresh: () => _revalidate(context, stale: stale),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: <Widget>[
          ?staleBanner,
          if (staleBanner != null) const SizedBox(height: AppSpacing.lg),
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
                  // Fila e pareamento sao do servidor: sem conexao nao ha o que
                  // simular, so um estado desabilitado que explica o motivo.
                  if (stale)
                    _OnlineOnlyCard(
                      onRetry: () => _revalidate(context, stale: true),
                    )
                  else
                    MatchmakingSection(userId: account.id, teamId: team.id),
                  const SizedBox(height: AppSpacing.xl),
                  // So o card do modo ESCOLHIDO. Mostrar os dois fazia a
                  // dobra falar de uma competicao que o usuario nao vai
                  // jogar agora -- e o seletor logo acima ja disse qual e.
                  // Campanha e placar nao vao pro cache, entao ficam fora
                  // enquanto a conta mostrada e a salva.
                  if (!accountState.isFromCache)
                    BlocBuilder<GameModeCubit, GameMode>(
                      builder: (context, mode) => switch (mode) {
                        GameMode.weekendLeague => const WeekendLeagueCard(),
                        GameMode.divisionRivals => const RivalsCard(),
                      },
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

class _StaleDataBanner extends StatelessWidget {
  const _StaleDataBanner({
    required this.accountState,
    required this.teamsState,
    required this.onRetry,
  });

  final AccountState accountState;
  final TeamsState teamsState;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = accountState.failure ?? teamsState.failure;
    final offline = failure is NetworkFailure || failure is TimeoutFailure;
    final savedAt = accountState.cachedAt ?? teamsState.cachedAt;
    final time = savedAt == null
        ? '-'
        : DateFormat.yMd(l10n.localeName).add_Hm().format(savedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBanner(
            tone: AppBannerTone.warning,
            icon: offline ? Icons.wifi_off : null,
            message: offline
                ? l10n.playOfflineBanner(time)
                : l10n.playStaleBanner(time),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.actionRetry,
            icon: Icons.refresh,
            expanded: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _OnlineOnlyCard extends StatelessWidget {
  const _OnlineOnlyCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.playOnlineOnlyTitle, style: context.textStyles.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.playOnlineOnlyMessage, style: context.textStyles.bodySmall),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.actionRetry,
            icon: Icons.refresh,
            expanded: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Sem pacote de conectividade (nao adicionamos dependencia), a volta ao app
/// e o melhor sinal barato de que a rede pode ter voltado: enquanto os dados
/// mostrados forem os salvos, revalida ao retomar.
class _ResumeRevalidator extends StatefulWidget {
  const _ResumeRevalidator({
    required this.enabled,
    required this.onResume,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onResume;
  final Widget child;

  @override
  State<_ResumeRevalidator> createState() => _ResumeRevalidatorState();
}

class _ResumeRevalidatorState extends State<_ResumeRevalidator>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enabled) {
      widget.onResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
