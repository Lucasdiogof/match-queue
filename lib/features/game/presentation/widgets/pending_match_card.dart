import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:fifa_queue/features/game/presentation/widgets/finish_match_sheet.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Depois de finalizar (rapido ou com placar), se a partida tinha squad no
/// momento da busca, oferece secundariamente ir direto pro detalhe pra
/// registrar gols/assistencias -- nunca obrigatorio, nunca automatico.
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
  // limpa a partida pendente, o card sai da arvore e este context desmonta
  // enquanto o dialogo esta aberto -- entao um context.push depois dele caia
  // num mounted falso e nao navegava, sem erro nenhum. O router nao depende
  // do ciclo de vida deste widget.
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

/// Descartar e irreversivel (a partida nao volta a ser registravel), entao
/// confirma -- mas continua sendo um toque, nunca um requisito.
Future<void> _discard(BuildContext context, AppLocalizations l10n) async {
  final cubit = context.read<PendingMatchCubit>();
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: l10n.pendingMatchSkipConfirmTitle,
      message: l10n.pendingMatchSkipConfirmMessage,
      confirmLabel: l10n.pendingMatchSkipAction,
      cancelLabel: l10n.actionCancel,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  if (confirmed == true) {
    await cubit.discard();
  }
}

class PendingMatchCard extends StatelessWidget {
  const PendingMatchCard({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PendingMatchCubit, PendingMatchState>(
        buildWhen: (previous, current) =>
            previous.match != current.match ||
            previous.isSaving != current.isSaving,
        builder: (context, state) {
          final match = state.match;
          if (match == null) {
            return const SizedBox.shrink();
          }
          return _PendingMatchCardBody(match: match, isSaving: state.isSaving);
        },
      );
}

class _PendingMatchCardBody extends StatelessWidget {
  const _PendingMatchCardBody({required this.match, required this.isSaving});

  final PendingGameMatch match;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final startedAt = match.startedAt;
    final wlNumber = match.weekendLeagueNumber;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: AppCard(
        variant: AppCardVariant.elevated,
        borderColor: colors.warning.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.sports_score_outlined,
                  size: AppSizing.iconLg,
                  color: colors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.pendingMatchTitle,
                    style: context.textStyles.titleMedium,
                  ),
                ),
                AppBadge(
                  label: wlNumber != null
                      ? l10n.weekendLeagueBadge(wlNumber)
                      : match.gameMode.label(l10n),
                  tone: AppBadgeTone.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.historyEntryDate(startedAt)} · '
              '${l10n.historyEntryTime(startedAt)}',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (match.fcAccountName != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.pendingMatchElencoLabel(match.fcAccountName!),
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (match.fcSquadName != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                match.fcFormationCode == null
                    ? match.fcSquadName!
                    : l10n.squadSummaryLabel(
                        match.fcSquadName!,
                        match.fcFormationCode!,
                      ),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton.secondary(
                    label: l10n.pendingMatchLossAction,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final cubit = context.read<PendingMatchCubit>();
                            final ok = await cubit.finish(
                              result: GameResult.loss,
                            );
                            if (context.mounted) {
                              await maybeOfferMatchDetails(
                                context: context,
                                match: match,
                                finishSucceeded: ok,
                              );
                            }
                          },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: l10n.pendingMatchWinAction,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final cubit = context.read<PendingMatchCubit>();
                            final ok = await cubit.finish(
                              result: GameResult.win,
                            );
                            if (context.mounted) {
                              await maybeOfferMatchDetails(
                                context: context,
                                match: match,
                                finishSucceeded: ok,
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.ghost(
              label: l10n.pendingMatchAddScoreAction,
              expanded: true,
              onPressed: isSaving
                  ? null
                  : () async {
                      final ok = await showFinishMatchSheet(context);
                      if (context.mounted) {
                        await maybeOfferMatchDetails(
                          context: context,
                          match: match,
                          finishSucceeded: ok == true,
                        );
                      }
                    },
            ),
            AppButton.ghost(
              label: l10n.pendingMatchSkipAction,
              expanded: true,
              onPressed: isSaving ? null : () => _discard(context, l10n),
            ),
          ],
        ),
      ),
    );
  }
}
