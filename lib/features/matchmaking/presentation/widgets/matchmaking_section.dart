import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:fifa_queue/features/matchmaking/domain/entities/my_matchmaking_status.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/game_mode_cubit.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_cubit.dart';
import 'package:fifa_queue/features/matchmaking/presentation/cubit/matchmaking_state.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/matchmaking_timer_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Com o Realtime no ar, isto deixou de ser o mecanismo de atualizacao e
/// virou so uma rede de seguranca: cobre o intervalo em que o canal caiu
/// mas o app ainda nao percebeu. Espacado de proposito -- quem atualiza a
/// tela e o evento, nao o relogio.
const Duration _safetyRefreshInterval = Duration(seconds: 90);

/// Bloco "Buscar partida" da tela Jogar -- fila real por TIME (Conta +
/// Time selecionados). O card de Conta/Modo/Escalacao ficam acima dele, em
/// blocos separados: este widget so cuida do estado de busca/fila/CTA
/// daquele time especifico.
class MatchmakingSection extends StatelessWidget {
  const MatchmakingSection({
    required this.fcAccountId,
    required this.teamId,
    required this.teamName,
    this.onMatchFound,
    super.key,
  });

  final String fcAccountId;
  final String teamId;

  /// So pra compor a mensagem do bottom sheet do item 1 ("... pelo Time
  /// X") -- nunca usado pra decidir nada, o servidor ja sabe o time pelo id.
  final String teamName;

  /// Chamado depois de um "Encontrei" bem-sucedido.
  final VoidCallback? onMatchFound;

  @override
  Widget build(BuildContext context) => BlocProvider<MatchmakingCubit>(
    key: ValueKey('$fcAccountId:$teamId'),
    create: (_) => MatchmakingCubit(
      getIt<MatchmakingRepository>(),
      getIt<AppLogger>(),
      fcAccountId: fcAccountId,
      teamId: teamId,
    )..start(),
    child: _MatchmakingSectionBody(
      teamName: teamName,
      onMatchFound: onMatchFound,
    ),
  );
}

class _MatchmakingSectionBody extends StatefulWidget {
  const _MatchmakingSectionBody({required this.teamName, this.onMatchFound});

  final String teamName;
  final VoidCallback? onMatchFound;

  @override
  State<_MatchmakingSectionBody> createState() =>
      _MatchmakingSectionBodyState();
}

class _MatchmakingSectionBodyState extends State<_MatchmakingSectionBody>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      _safetyRefreshInterval,
      (_) => context.read<MatchmakingCubit>().refreshSilently(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MatchmakingCubit>().refreshSilently();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _announceYourTurn(BuildContext context) {
    unawaited(HapticFeedback.mediumImpact());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.matchmakingYourTurnTitle)),
      );
  }

  void _announceActionFailure(BuildContext context, AppFailure failure) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(failure.localizedMessage(context.l10n))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocListener(
      listeners: <BlocListener<MatchmakingCubit, MatchmakingState>>[
        BlocListener<MatchmakingCubit, MatchmakingState>(
          listenWhen: (previous, current) =>
              previous.promotionNonce != current.promotionNonce,
          listener: (context, state) => _announceYourTurn(context),
        ),
        // Falha de acao (buscar, cancelar, reportar) so ficava guardada no
        // estado: a UI de erro depende de status == failure, que uma acao
        // nunca produz. Resultado pratico -- o cooldown de 30s (FQ020)
        // fazia o botao parecer morto, sem nenhuma explicacao na tela.
        BlocListener<MatchmakingCubit, MatchmakingState>(
          listenWhen: (previous, current) =>
              current.failure != null && previous.failure != current.failure,
          listener: (context, state) =>
              _announceActionFailure(context, state.failure!),
        ),
      ],
      child: BlocBuilder<MatchmakingCubit, MatchmakingState>(
        builder: (context, state) => switch (state.status) {
          MatchmakingStatus.loading => const AppCard(
            child: SizedBox(height: 220, child: AppLoading.inline()),
          ),
          MatchmakingStatus.failure => AppCard(
            child: AppBanner(
              tone: AppBannerTone.danger,
              message:
                  state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
            ),
          ),
          MatchmakingStatus.ready => _MatchmakingReadyBody(
            state: state,
            teamName: widget.teamName,
            onMatchFound: widget.onMatchFound,
          ),
        },
      ),
    );
  }
}

class _MatchmakingReadyBody extends StatelessWidget {
  const _MatchmakingReadyBody({
    required this.state,
    required this.teamName,
    this.onMatchFound,
  });

  final MatchmakingState state;
  final String teamName;
  final VoidCallback? onMatchFound;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final card = switch (snapshot) {
      _ when !snapshot.accountLinkedToTeam => _NotLinkedCard(
        snapshot: snapshot,
      ),
      _ when snapshot.isSearchingByMe => _SearchingSelfCard(
        state: state,
        snapshot: snapshot,
        onMatchFound: onMatchFound,
      ),
      _ when snapshot.isQueuedByMe => _QueuedCard(
        state: state,
        snapshot: snapshot,
      ),
      _ => _IdleCard(state: state, snapshot: snapshot, teamName: teamName),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (snapshot.isBusyElsewhere)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SearchingElsewhereBanner(
              elsewhere: snapshot.searchingElsewhere!,
            ),
          ),
        if (state.connection == MatchmakingConnection.disconnected) ...<Widget>[
          const _ReconnectingIndicator(),
          const SizedBox(height: AppSpacing.sm),
        ],
        card,
      ],
    );
  }
}

class _ReconnectingIndicator extends StatelessWidget {
  const _ReconnectingIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.matchmakingReconnecting,
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SearchingElsewhereBanner extends StatelessWidget {
  const _SearchingElsewhereBanner({required this.elsewhere});

  final SearchingElsewhere elsewhere;

  @override
  Widget build(BuildContext context) => AppBanner(
    tone: AppBannerTone.neutral,
    message: context.l10n.matchmakingSearchingElsewhereMessage(
      elsewhere.teamName,
    ),
  );
}

class _NotLinkedCard extends StatelessWidget {
  const _NotLinkedCard({required this.snapshot});

  final MyMatchmakingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBanner(
            tone: AppBannerTone.warning,
            message: l10n.matchmakingNotLinkedMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(
            label: l10n.fcAccountLinkedTeamsTitle,
            icon: Icons.link,
            onPressed: () => context.push(
              AppRoutes.fcAccountDetailLocation(snapshot.fcAccountId),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleCard extends StatelessWidget {
  const _IdleCard({
    required this.state,
    required this.snapshot,
    required this.teamName,
  });

  final MatchmakingState state;
  final MyMatchmakingSnapshot snapshot;
  final String teamName;

  Future<void> _onStartPressed(BuildContext context) async {
    final blocking = snapshot.blockingSearch;
    if (blocking == null) {
      unawaited(
        context.read<MatchmakingCubit>().startSearch(
          context.read<GameModeCubit>().state,
          fcSquadId: context.read<FcSquadsCubit>().state.selectedSquadId,
        ),
      );
      return;
    }
    await showMatchmakingQueueSheet(
      context: context,
      cubit: context.read<MatchmakingCubit>(),
      blocking: blocking,
      teamName: teamName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final blocking = snapshot.blockingSearch;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.sports_esports_outlined,
                size: AppSizing.iconLg,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  blocking == null
                      ? l10n.matchmakingIdleTitle
                      : l10n.matchmakingSearchingOtherTitle(
                          blocking.displayName,
                        ),
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const AppDivider(spacing: AppSpacing.xl),
          Text(
            blocking == null
                ? l10n.matchmakingIdleMessage
                : l10n.matchmakingQueueEmptyMessage,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: blocking == null
                ? l10n.matchmakingSearchAction
                : l10n.matchmakingJoinQueueAction,
            icon: blocking == null ? Icons.search : Icons.playlist_add,
            isLoading: state.isActionPending,
            onPressed: state.isActionPending
                ? null
                : () => _onStartPressed(context),
          ),
        ],
      ),
    );
  }
}

class _SearchingSelfCard extends StatelessWidget {
  const _SearchingSelfCard({
    required this.state,
    required this.snapshot,
    this.onMatchFound,
  });

  final MatchmakingState state;
  final MyMatchmakingSnapshot snapshot;
  final VoidCallback? onMatchFound;

  Future<void> _matchFound(BuildContext context) async {
    final ok = await context.read<MatchmakingCubit>().matchFound();
    if (ok) {
      onMatchFound?.call();
    }
  }

  /// Sem confirmacao: cancelar a busca nao destroi nada e refazer custa um
  /// toque. O erro, se a RPC falhar, aparece pelo listener de falha -- o
  /// estado real continua vindo do servidor, nunca do otimismo do client.
  Future<void> _cancel(BuildContext context) async {
    await context.read<MatchmakingCubit>().cancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final searching = snapshot.searching!;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        children: <Widget>[
          Text(
            l10n.matchmakingSearchingSelfTitle,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          MatchmakingTimerRing(
            startedAt: searching.startedAt,
            expiresAt: searching.expiresAt,
            estimatedServerNow: state.estimatedServerNow,
            onReachedZero: () =>
                context.read<MatchmakingCubit>().refreshSilently(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.matchmakingSearchingSelfMessage,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.secondary(
                  label: l10n.matchmakingCancelAction,
                  isLoading: state.isActionPending,
                  onPressed: state.isActionPending
                      ? null
                      : () => _cancel(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l10n.matchmakingMatchFoundAction,
                  icon: Icons.check_circle_outline,
                  isLoading: state.isActionPending,
                  onPressed: state.isActionPending
                      ? null
                      : () => _matchFound(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estou na fila deste time: mostra minha posicao E a fila inteira e
/// visivel (item 2/25 -- nao so "posicao 2", a lista com quem esta na
/// frente). Sair da fila usa [MatchmakingCubit.leaveQueue], nunca
/// [MatchmakingCubit.cancel] -- cancel encerra a busca ATIVA (em qualquer
/// time), sair da fila e por TIME especifico.
class _QueuedCard extends StatelessWidget {
  const _QueuedCard({required this.state, required this.snapshot});

  final MatchmakingState state;
  final MyMatchmakingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.matchmakingQueueSectionTitle,
            style: context.textStyles.titleMedium,
          ),
          if (snapshot.myPosition != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppBadge(
              label: l10n.matchmakingQueuePositionLabel(snapshot.myPosition!),
              tone: AppBadgeTone.info,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final entry in snapshot.queue)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.position}',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.isMe
                          ? '${entry.displayName} · ${l10n.matchmakingYouBadge}'
                          : entry.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: entry.isMe
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.matchmakingLeaveQueueAction,
            icon: Icons.close,
            isLoading: state.isActionPending,
            onPressed: state.isActionPending
                ? null
                : () => context.read<MatchmakingCubit>().leaveQueue(),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet do item 1: aberta ao tocar "Buscar partida" quando ja existe
/// alguem buscando por este time. Entrar na fila E solicitar prioridade sao
/// os dois caminhos -- nenhum dos dois muda quem esta buscando agora.
Future<void> showMatchmakingQueueSheet({
  required BuildContext context,
  required MatchmakingCubit cubit,
  required BlockingSearch blocking,
  required String teamName,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (sheetContext) => BlocProvider<MatchmakingCubit>.value(
    value: cubit,
    child: _MatchmakingQueueSheetBody(blocking: blocking, teamName: teamName),
  ),
);

class _MatchmakingQueueSheetBody extends StatelessWidget {
  const _MatchmakingQueueSheetBody({
    required this.blocking,
    required this.teamName,
  });

  final BlockingSearch blocking;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return BlocConsumer<MatchmakingCubit, MatchmakingState>(
      listenWhen: (previous, current) =>
          current.failure != null && previous.failure != current.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(state.failure!.localizedMessage(l10n))),
        ),
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.matchmakingBottomSheetTitle,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.matchmakingBottomSheetMessage(blocking.displayName, teamName),
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.matchmakingJoinQueueAction,
            icon: Icons.playlist_add,
            isLoading: state.isActionPending,
            onPressed: state.isActionPending
                ? null
                : () async {
                    final cubit = context.read<MatchmakingCubit>();
                    final navigator = Navigator.of(context);
                    final ok = await cubit.startSearch(
                      context.read<GameModeCubit>().state,
                      fcSquadId: context
                          .read<FcSquadsCubit>()
                          .state
                          .selectedSquadId,
                    );
                    if (ok && navigator.mounted) {
                      navigator.pop();
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.priorityRequestSent)
            AppBanner(
              tone: AppBannerTone.neutral,
              message: l10n.matchmakingPriorityRequestedConfirmation,
            )
          else
            AppButton.secondary(
              label: l10n.matchmakingRequestPriorityAction,
              icon: Icons.priority_high,
              isLoading: state.isActionPending,
              onPressed: state.isActionPending
                  ? null
                  : () => context.read<MatchmakingCubit>().requestPriority(),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.actionClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
