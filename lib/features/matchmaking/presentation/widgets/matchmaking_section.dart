import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
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

/// Bloco "Buscar partida" da tela Jogar (Etapa 11) -- centrado na CONTA
/// selecionada, nunca num time. O card de Conta/Modo/Escalacao ficam acima
/// dele, em blocos separados: este widget so cuida do estado de
/// busca/fila/CTA.
class MatchmakingSection extends StatelessWidget {
  const MatchmakingSection({
    required this.fcAccountId,
    this.onMatchFound,
    super.key,
  });

  final String fcAccountId;

  /// Chamado depois de um "Encontrei" bem-sucedido.
  final VoidCallback? onMatchFound;

  @override
  Widget build(BuildContext context) => BlocProvider<MatchmakingCubit>(
    key: ValueKey(fcAccountId),
    create: (_) => MatchmakingCubit(
      getIt<MatchmakingRepository>(),
      getIt<AppLogger>(),
      fcAccountId: fcAccountId,
    )..start(),
    child: _MatchmakingSectionBody(onMatchFound: onMatchFound),
  );
}

class _MatchmakingSectionBody extends StatefulWidget {
  const _MatchmakingSectionBody({this.onMatchFound});

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<MatchmakingCubit, MatchmakingState>(
      listenWhen: (previous, current) =>
          previous.promotionNonce != current.promotionNonce,
      listener: (context, state) => _announceYourTurn(context),
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
            onMatchFound: widget.onMatchFound,
          ),
        },
      ),
    );
  }
}

class _MatchmakingReadyBody extends StatelessWidget {
  const _MatchmakingReadyBody({required this.state, this.onMatchFound});

  final MatchmakingState state;
  final VoidCallback? onMatchFound;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    final card = switch (snapshot) {
      _ when snapshot.isSearchingByMe => _SearchingSelfCard(
        state: state,
        snapshot: snapshot,
        onMatchFound: onMatchFound,
      ),
      _ when snapshot.isQueuedByMe || snapshot.blockingSearch != null =>
        _BlockedCard(state: state, snapshot: snapshot),
      _ => _IdleCard(state: state, snapshot: snapshot),
    };

    if (state.connection != MatchmakingConnection.disconnected) {
      return card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _ReconnectingIndicator(),
        const SizedBox(height: AppSpacing.sm),
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

class _IdleCard extends StatelessWidget {
  const _IdleCard({required this.state, required this.snapshot});

  final MatchmakingState state;
  final MyMatchmakingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    if (snapshot.hasNoLinkedTeam) {
      return AppCard(
        variant: AppCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppBanner(
              tone: AppBannerTone.warning,
              message: l10n.errorFcAccountNotLinkedToAnyTeam,
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
                  l10n.matchmakingIdleTitle,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
          const AppDivider(spacing: AppSpacing.xl),
          Text(
            l10n.matchmakingIdleMessage,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _StartSearchButton(
            isActionPending: state.isActionPending,
            label: l10n.matchmakingSearchAction,
            icon: Icons.search,
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _StartSearchButton extends StatelessWidget {
  const _StartSearchButton({
    required this.isActionPending,
    required this.label,
    required this.icon,
    required this.variant,
  });

  final bool isActionPending;
  final String label;
  final IconData icon;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    icon: icon,
    variant: variant,
    isLoading: isActionPending,
    onPressed: isActionPending
        ? null
        // O squad e opcional: sem nenhum configurado a busca acontece
        // igual, so sem escalacao associada (item 63).
        : () => context.read<MatchmakingCubit>().startSearch(
            context.read<GameModeCubit>().state,
            fcSquadId: context.read<FcSquadsCubit>().state.selectedSquadId,
          ),
  );
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

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<MatchmakingCubit>();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: l10n.matchmakingCancelConfirmTitle,
        message: l10n.matchmakingCancelConfirmMessage,
        confirmLabel: l10n.matchmakingCancelAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) {
      await cubit.cancel();
    }
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
                      : () => _confirmCancel(context),
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

/// Fila ou bloqueio: alguem mais esta buscando com um dos meus times
/// vinculados, ou eu mesmo entrei na fila esperando a vez.
class _BlockedCard extends StatelessWidget {
  const _BlockedCard({required this.state, required this.snapshot});

  final MatchmakingState state;
  final MyMatchmakingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final blocking = snapshot.blockingSearch;
    final isQueued = snapshot.isQueuedByMe;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (blocking != null)
            Row(
              children: <Widget>[
                AppAvatar(
                  label: blocking.displayName,
                  imageUrl: blocking.avatarUrl,
                  size: AppSizing.avatarMd,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.matchmakingSearchingOtherTitle(blocking.displayName),
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ],
            )
          else
            Text(
              l10n.matchmakingQueueSectionTitle,
              style: context.textStyles.titleMedium,
            ),
          if (isQueued && snapshot.myPosition != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            AppBadge(
              label: l10n.matchmakingQueuePositionLabel(snapshot.myPosition!),
              tone: AppBadgeTone.info,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            isQueued
                ? l10n.matchmakingSearchingSelfMessage
                : l10n.matchmakingQueueEmptyMessage,
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isQueued)
            AppButton.secondary(
              label: l10n.matchmakingLeaveQueueAction,
              icon: Icons.close,
              isLoading: state.isActionPending,
              onPressed: state.isActionPending
                  ? null
                  : () => context.read<MatchmakingCubit>().cancel(),
            )
          else
            _StartSearchButton(
              isActionPending: state.isActionPending,
              label: l10n.matchmakingJoinQueueAction,
              icon: Icons.playlist_add,
              variant: AppButtonVariant.primary,
            ),
        ],
      ),
    );
  }
}
