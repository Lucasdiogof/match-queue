import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_cubit.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_state.dart';
import 'package:fifa_queue/features/history/presentation/history_formatting.dart';
import 'package:fifa_queue/features/history/presentation/widgets/filter_chip_row.dart';
import 'package:fifa_queue/features/matchmaking/presentation/widgets/game_mode_selector.dart';
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
    final e = entry;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                Text(
                  e.gameMode.label(l10n).toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              AppBadge(label: e.status.label(l10n), tone: e.status.tone),
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
