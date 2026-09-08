import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_cubit.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_state.dart';
import 'package:fifa_queue/features/history/presentation/history_formatting.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityTimelineView extends StatefulWidget {
  const ActivityTimelineView({super.key});

  @override
  State<ActivityTimelineView> createState() => _ActivityTimelineViewState();
}

class _ActivityTimelineViewState extends State<ActivityTimelineView> {
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
      context.read<ActivityHistoryCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const _ActivityFilters(),
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: BlocBuilder<ActivityHistoryCubit, ActivityHistoryState>(
          builder: (context, state) => switch (state.status) {
            ActivityHistoryStatus.initial ||
            ActivityHistoryStatus.loading => const AppLoading(),
            ActivityHistoryStatus.failure when state.items.isEmpty =>
              _ActivityError(state: state),
            _ when state.isEmpty => _ActivityEmpty(),
            _ => _ActivityList(
              state: state,
              scrollController: _scrollController,
            ),
          },
        ),
      ),
    ],
  );
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ActivityHistoryCubit, ActivityHistoryState>(
      builder: (context, state) {
        final cubit = context.read<ActivityHistoryCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
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
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                AppChip(
                  label: l10n.activityScopeAll,
                  isSelected: state.scope == ActivityScope.all,
                  onPressed: () => cubit.setScope(ActivityScope.all),
                ),
                AppChip(
                  label: l10n.activityScopeGames,
                  isSelected: state.scope == ActivityScope.games,
                  onPressed: () => cubit.setScope(ActivityScope.games),
                ),
                AppChip(
                  label: l10n.activityScopeSearches,
                  isSelected: state.scope == ActivityScope.searches,
                  onPressed: () => cubit.setScope(ActivityScope.searches),
                ),
              ],
            ),
            if (state.scope == ActivityScope.games) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  AppChip(
                    label: l10n.historyStatusAll,
                    isSelected: state.gameResultFilter == null,
                    onPressed: () => cubit.setGameResultFilter(null),
                  ),
                  AppChip(
                    label: l10n.pendingMatchWinAction,
                    isSelected: state.gameResultFilter == GameResult.win,
                    onPressed: () => cubit.setGameResultFilter(GameResult.win),
                  ),
                  AppChip(
                    label: l10n.pendingMatchLossAction,
                    isSelected: state.gameResultFilter == GameResult.loss,
                    onPressed: () => cubit.setGameResultFilter(GameResult.loss),
                  ),
                ],
              ),
            ],
            if (state.scope == ActivityScope.searches) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  AppChip(
                    label: l10n.historyStatusAll,
                    isSelected: state.searchStatusFilter == null,
                    onPressed: () => cubit.setSearchStatusFilter(null),
                  ),
                  for (final status in MatchSearchStatus.values)
                    AppChip(
                      label: status.filterLabel(l10n),
                      isSelected: state.searchStatusFilter == status,
                      onPressed: () => cubit.setSearchStatusFilter(status),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.state, required this.scrollController});

  final ActivityHistoryState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => context.read<ActivityHistoryCubit>().refresh(),
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
        return _ActivityRow(entry: state.items[index]);
      },
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final TeamActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final e = entry;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => showActivityDetailSheet(context, e),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: e.displayName,
            imageUrl: e.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  e.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(switch (e) {
                  GameHistoryEntry() => e.gameMode.label(l10n).toUpperCase(),
                  SearchHistoryEntry() => e.gameMode.label(l10n).toUpperCase(),
                }, style: context.textStyles.labelSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _summary(l10n, e),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _StatusBadge(entry: e),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.historyEntryTime(e.occurredAt.toLocal()),
                style: context.textStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _summary(AppLocalizations l10n, TeamActivityEntry entry) {
    if (entry is GameHistoryEntry) {
      if (entry.hasScore) {
        return '${entry.goalsFor}–${entry.goalsAgainst}';
      }
      if (entry.result != null) {
        return entry.result == GameResult.win
            ? l10n.pendingMatchWinAction
            : l10n.pendingMatchLossAction;
      }
      return l10n.activityNoResult;
    }
    final search = entry as SearchHistoryEntry;
    return formatSearchDuration(search.durationSeconds);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.entry});

  final TeamActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (entry) {
      GameHistoryEntry(:final result) => AppBadge(
        label: result == GameResult.win
            ? l10n.pendingMatchWinAction
            : result == GameResult.loss
            ? l10n.pendingMatchLossAction
            : l10n.activityNoResult,
        tone: result == GameResult.win
            ? AppBadgeTone.success
            : result == GameResult.loss
            ? AppBadgeTone.danger
            : AppBadgeTone.neutral,
      ),
      SearchHistoryEntry(:final status) => AppBadge(
        label: status.label(l10n),
        tone: status.tone,
      ),
    };
  }
}

class _ActivityEmpty extends StatelessWidget {
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

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.state});

  final ActivityHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppErrorState(
      title: l10n.historyLoadErrorTitle,
      message: state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
      retryLabel: l10n.actionRetry,
      onRetry: () => context.read<ActivityHistoryCubit>().refresh(),
    );
  }
}

Future<void> showActivityDetailSheet(
  BuildContext context,
  TeamActivityEntry entry,
) => showAppBottomSheet<void>(
  context: context,
  builder: (sheetContext) => _ActivityDetailSheet(entry: entry),
);

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({required this.entry});

  final TeamActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = entry;

    return AppBottomSheet(
      title: e.displayName,
      actions: <Widget>[
        AppButton.ghost(
          label: l10n.actionClose,
          expanded: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (e) {
          GameHistoryEntry() => <Widget>[
            _DetailRow(
              label: l10n.activityDetailMode,
              value: e.gameMode.label(l10n),
            ),
            _DetailRow(
              label: l10n.historyEntryDate(e.startedAt.toLocal()),
              value: l10n.historyEntryTime(e.startedAt.toLocal()),
            ),
            _DetailRow(
              label: l10n.activityDetailDuration,
              value: formatSearchDuration(
                e.occurredAt.difference(e.startedAt).inSeconds,
              ),
            ),
            if (e.hasScore)
              _DetailRow(
                label: l10n.activityDetailScore,
                value: '${e.goalsFor}–${e.goalsAgainst}',
              )
            else if (e.result != null)
              _DetailRow(
                label: l10n.activityDetailResult,
                value: e.result == GameResult.win
                    ? l10n.pendingMatchWinAction
                    : l10n.pendingMatchLossAction,
              ),
            // Historico anterior a Etapa 9 nao tem elenco: a linha some em
            // vez de mostrar vazio.
            if (e.fcAccountName != null)
              _DetailRow(
                label: l10n.activityDetailFcAccount,
                value: e.fcAccountName!,
              ),
            // Vem do snapshot da partida: partidas anteriores à Etapa 10 não
            // têm squad e a linha simplesmente não aparece.
            if (e.fcSquadName != null)
              _DetailRow(
                label: l10n.squadLabel,
                value: e.fcFormationCode == null
                    ? e.fcSquadName!
                    : l10n.squadSummaryLabel(
                        e.fcSquadName!,
                        e.fcFormationCode!,
                      ),
              ),
          ],
          SearchHistoryEntry() => <Widget>[
            _DetailRow(
              label: l10n.activityDetailMode,
              value: e.gameMode.label(l10n),
            ),
            _DetailRow(
              label: l10n.historyEntryDate(e.startedAt.toLocal()),
              value: l10n.historyEntryTime(e.startedAt.toLocal()),
            ),
            _DetailRow(
              label: l10n.activityDetailDuration,
              value: formatSearchDuration(e.durationSeconds),
            ),
            _DetailRow(
              label: l10n.activityDetailStatus,
              value: e.status.label(l10n),
            ),
            if (e.fcAccountName != null)
              _DetailRow(
                label: l10n.activityDetailFcAccount,
                value: e.fcAccountName!,
              ),
          ],
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        Text(value, style: context.textStyles.bodyMedium),
      ],
    ),
  );
}
