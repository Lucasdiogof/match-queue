import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/presentation/cubit/stats_cubit.dart';
import 'package:fifa_queue/features/history/presentation/cubit/stats_state.dart';
import 'package:fifa_queue/features/history/presentation/history_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MatchmakingStatsView extends StatelessWidget {
  const MatchmakingStatsView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const _PeriodFilter(),
      const SizedBox(height: AppSpacing.md),
      Expanded(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) => switch (state.status) {
            StatsStatus.initial || StatsStatus.loading => const AppLoading(),
            StatsStatus.failure => _StatsError(state: state),
            StatsStatus.ready => _StatsBody(stats: state.stats!),
          },
        ),
      ),
    ],
  );
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<StatsCubit, StatsState>(
      buildWhen: (previous, current) => previous.period != current.period,
      builder: (context, state) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final period in StatsPeriod.values)
            AppChip(
              label: period.label(l10n),
              isSelected: state.period == period,
              onPressed: () => context.read<StatsCubit>().setPeriod(period),
            ),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final MatchmakingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (stats.totals.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: AppSpacing.huge),
          AppEmptyState(
            icon: Icons.query_stats,
            title: l10n.statsEmptyTitle,
            message: l10n.statsEmptyMessage,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StatsCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: <Widget>[
          _TotalsCard(totals: stats.totals),
          if (stats.players.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.statsPlayersTitle.toUpperCase(),
              style: context.textStyles.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final player in stats.players)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlayerRow(player: player),
              ),
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final MatchmakingTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: l10n.statsTotalSearches,
                  value: '${totals.total}',
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: l10n.statsMatchFound,
                  value: '${totals.matchFound}',
                ),
              ),
            ],
          ),
          const AppDivider(spacing: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: l10n.statsSuccessRate,
                  value: formatSuccessRate(totals.successRate),
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: l10n.statsAvgDuration,
                  value: totals.avgDurationSeconds == null
                      ? '—'
                      : formatSearchDuration(totals.avgDurationSeconds!),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${l10n.statsCancelled}: ${totals.cancelled}'
            '   ·   ${l10n.statsExpired}: ${totals.expired}',
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        value,
        style: context.textStyles.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});

  final PlayerStats player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: player.displayName,
            imageUrl: player.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  player.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.statsPlayerSearches(player.total),
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
              Text(
                formatSuccessRate(player.successRate),
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.statsSuccessRate.toLowerCase(),
                style: context.textStyles.labelSmall?.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.state});

  final StatsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppErrorState(
      title: l10n.statsLoadErrorTitle,
      message: state.failure?.localizedMessage(l10n) ?? l10n.errorUnexpected,
      retryLabel: l10n.actionRetry,
      onRetry: () => context.read<StatsCubit>().refresh(),
    );
  }
}
