import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/presentation/cubit/history_cubit.dart';
import 'package:fifa_queue/features/history/presentation/cubit/history_state.dart';
import 'package:fifa_queue/features/history/presentation/history_formatting.dart';
import 'package:fifa_queue/features/history/presentation/widgets/filter_chip_row.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MatchHistoryView extends StatefulWidget {
  const MatchHistoryView({super.key});

  @override
  State<MatchHistoryView> createState() => _MatchHistoryViewState();
}

class _MatchHistoryViewState extends State<MatchHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<HistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const _HistoryFilters(),
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) => switch (state.status) {
            HistoryStatus.initial ||
            HistoryStatus.loading => const AppLoading(),
            HistoryStatus.failure when state.items.isEmpty => _HistoryError(
              state: state,
            ),
            _ when state.isEmpty => _HistoryEmpty(),
            _ => _HistoryList(
              state: state,
              scrollController: _scrollController,
            ),
          },
        ),
      ),
    ],
  );
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<HistoryCubit, HistoryState>(
      buildWhen: (previous, current) =>
          previous.statusFilter != current.statusFilter ||
          previous.period != current.period,
      builder: (context, state) {
        final cubit = context.read<HistoryCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FilterChipRow(
              children: <Widget>[
                for (final period in StatsPeriod.values)
                  AppChip(
                    label: period.label(l10n),
                    isSelected: state.period == period,
                    onPressed: () => cubit.setPeriod(period),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FilterChipRow(
              children: <Widget>[
                AppChip(
                  label: l10n.historyStatusAll,
                  isSelected: state.statusFilter == null,
                  onPressed: () => cubit.setStatusFilter(null),
                ),
                for (final status in MatchSearchStatus.values)
                  AppChip(
                    label: status.filterLabel(l10n),
                    isSelected: state.statusFilter == status,
                    onPressed: () => cubit.setStatusFilter(status),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state, required this.scrollController});

  final HistoryState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => context.read<HistoryCubit>().refresh(),
    child: ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: AppLoading.inline(),
          );
        }
        return _HistoryRow(entry: state.items[index]);
      },
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final MatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: entry.displayName,
            imageUrl: entry.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${l10n.historyEntryDate(entry.finishedAt.toLocal())}'
                  ' · ${l10n.historyEntryTime(entry.finishedAt.toLocal())}'
                  ' · ${formatSearchDuration(entry.durationSeconds)}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (entry.hasMatch || entry.fcAccountName != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  _MatchLine(entry: entry),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppBadge(label: entry.status.label(l10n), tone: entry.status.tone),
        ],
      ),
    );
  }
}

/// Contexto da partida que saiu da busca: conta, modalidade e desfecho.
/// Resultado ausente vira rotulo neutro -- o app nunca deduz derrota de um
/// registro que o jogador escolheu nao preencher.
class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.entry});

  final MatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final context_ = <String>[
      if (entry.fcAccountName != null) entry.fcAccountName!,
      if (entry.gameMode != null) entry.gameMode!.label(l10n),
    ];

    return Row(
      children: <Widget>[
        if (context_.isNotEmpty)
          Flexible(
            child: Text(
              context_.join(' · '),
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        if (entry.hasMatch) ...<Widget>[
          if (context_.isNotEmpty) const SizedBox(width: AppSpacing.sm),
          if (entry.result != null)
            Text(
              entry.hasScore
                  ? '${_resultLabel(l10n, entry.result!)} '
                        '${entry.goalsFor}–${entry.goalsAgainst}'
                  : _resultLabel(l10n, entry.result!),
              style: context.textStyles.bodySmall?.copyWith(
                color: entry.result == GameResult.win
                    ? colors.success
                    : colors.danger,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              l10n.historyResultNotInformed,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ],
    );
  }

  static String _resultLabel(AppLocalizations l10n, GameResult result) =>
      result == GameResult.win
      ? l10n.pendingMatchWinAction
      : l10n.pendingMatchLossAction;
}

class _HistoryEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
      const SizedBox(height: AppSpacing.huge),
      AppEmptyState(
        icon: Icons.history,
        title: context.l10n.historyEmptyTitle,
        message: context.l10n.historyEmptyMessage,
      ),
    ],
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppErrorState(
      title: l10n.historyLoadErrorTitle,
      message: state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
      retryLabel: l10n.actionRetry,
      onRetry: () => context.read<HistoryCubit>().refresh(),
    );
  }
}
