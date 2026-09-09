import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:fifa_queue/features/game/presentation/widgets/pending_matches_sheet.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Depois de finalizar, se a partida tinha squad no momento da busca, oferece
/// ir direto pro detalhe pra registrar gols/assistencias -- nunca
/// obrigatorio, nunca automatico.
Future<void> maybeOfferMatchDetails({
  required BuildContext context,
  required PendingGameMatch match,
  required bool finishSucceeded,
}) async {
  if (!finishSucceeded || match.fcSquadName == null || !context.mounted) {
    return;
  }
  final l10n = context.l10n;
  // O router e capturado ANTES do dialogo, de proposito. Salvar o resultado
  // tira a partida da lista, o card pode sair da arvore e este context
  // desmonta enquanto o dialogo esta aberto -- entao um context.push depois
  // dele caia num mounted falso e nao navegava, sem erro nenhum.
  final router = GoRouter.of(context);
  final wantsDetails = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: l10n.pendingMatchDetailsPromptTitle,
      message: l10n.pendingMatchDetailsPromptMessage,
      confirmLabel: l10n.pendingMatchDetailsPromptAddAction,
      cancelLabel: l10n.pendingMatchDetailsPromptSkipAction,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  if (wantsDetails == true) {
    await router.push(AppRoutes.matchDetailLocation(match.id));
  }
}

/// Um card so para todas as pendencias, nunca um por partida: quem jogou
/// varias sem registrar via a Home virar uma pilha de cards iguais.
class PendingMatchCard extends StatelessWidget {
  const PendingMatchCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PendingMatchCubit, PendingMatchState>(
        buildWhen: (previous, current) =>
            previous.matches != current.matches ||
            previous.isSaving != current.isSaving,
        builder: (context, state) {
          if (!state.hasPending) {
            return const SizedBox.shrink();
          }
          return _PendingSummaryCard(state: state);
        },
      );
}

class _PendingSummaryCard extends StatelessWidget {
  const _PendingSummaryCard({required this.state});

  final PendingMatchState state;

  Future<void> _dismissAll(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<PendingMatchCubit>();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: l10n.pendingMatchesDismissAllTitle,
        message: l10n.pendingMatchesDismissAllMessage,
        confirmLabel: l10n.pendingMatchesDismissAllAction,
        cancelLabel: l10n.actionCancel,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed == true) {
      await cubit.dismissAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final latest = state.match!;
    final when = latest.startedAt.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        variant: AppCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.assignment_late_outlined,
                  size: AppSizing.iconLg,
                  color: colors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.pendingMatchesCardTitle(state.pendingCount),
                    style: context.textStyles.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.pendingMatchesCardLatest(
                latest.gameMode.label(l10n),
                l10n.historyEntryDate(when),
                l10n.historyEntryTime(when),
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: l10n.pendingMatchesOpenListAction,
                    onPressed: state.isSaving
                        ? null
                        : () => showPendingMatchesSheet(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.ghost(
                    label: l10n.pendingMatchesDismissAllAction,
                    onPressed: state.isSaving
                        ? null
                        : () => _dismissAll(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
