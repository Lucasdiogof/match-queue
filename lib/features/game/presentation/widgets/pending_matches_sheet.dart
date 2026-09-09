import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_state.dart';
import 'package:fifa_queue/features/game/presentation/widgets/finish_match_sheet.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lista das partidas sem resultado, da mais recente para a mais antiga.
/// Cada linha resolve a si mesma: informar ou dispensar. Fechar a folha sem
/// tocar em nada e um desfecho valido -- pendencia nao bloqueia nada.
Future<void> showPendingMatchesSheet(BuildContext context) {
  final cubit = context.read<PendingMatchCubit>();
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<PendingMatchCubit>.value(
      value: cubit,
      child: const _PendingMatchesSheet(),
    ),
  );
}

class _PendingMatchesSheet extends StatelessWidget {
  const _PendingMatchesSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PendingMatchCubit, PendingMatchState>(
      builder: (context, state) => AppBottomSheet(
        title: l10n.pendingMatchesSheetTitle,
        subtitle: l10n.pendingMatchesSheetMessage,
        isChildScrollable: true,
        child: state.matches.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  l10n.pendingMatchesAllClear,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: state.matches.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) => _PendingRow(
                  match: state.matches[index],
                  isSaving: state.isSaving,
                ),
              ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.match, required this.isSaving});

  final PendingGameMatch match;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final when = match.startedAt.toLocal();
    final context_ = <String>[
      if (match.fcAccountName != null) match.fcAccountName!,
      if (match.teamName != null) match.teamName!,
    ];

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  match.gameMode.label(l10n),
                  style: context.textStyles.titleSmall,
                ),
              ),
              Text(
                '${l10n.historyEntryDate(when)} · '
                '${l10n.historyEntryTime(when)}',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          if (context_.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context_.join(' · '),
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.secondary(
                  label: l10n.pendingMatchLossAction,
                  onPressed: isSaving
                      ? null
                      : () => context.read<PendingMatchCubit>().finish(
                          matchId: match.id,
                          result: GameResult.loss,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l10n.pendingMatchWinAction,
                  onPressed: isSaving
                      ? null
                      : () => context.read<PendingMatchCubit>().finish(
                          matchId: match.id,
                          result: GameResult.win,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.ghost(
                  label: l10n.pendingMatchAddScoreAction,
                  onPressed: isSaving
                      ? null
                      : () => showFinishMatchSheet(context, matchId: match.id),
                ),
              ),
              Expanded(
                child: AppButton.ghost(
                  label: l10n.pendingMatchesSkipOneAction,
                  onPressed: isSaving
                      ? null
                      : () => context.read<PendingMatchCubit>().discard(
                          matchId: match.id,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
