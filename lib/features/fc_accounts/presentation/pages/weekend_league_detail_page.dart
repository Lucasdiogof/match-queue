import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/weekend_league_manual_record_sheet.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/weekend_league_week_picker.dart';
import 'package:fifa_queue/features/game/domain/entities/player_leaderboard_entry.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:flutter/material.dart';

/// Detalhe de uma campanha de Weekend League de uma conta: record
/// computado x manual (nunca somados), artilharia e assistencias. Secoes
/// em vez de abas -- simples e suficiente pro volume de dados aqui.
class WeekendLeagueDetailPage extends StatefulWidget {
  const WeekendLeagueDetailPage({
    required this.account,
    required this.event,
    super.key,
  });

  final FcAccount account;
  final WeekendLeagueEvent event;

  @override
  State<WeekendLeagueDetailPage> createState() =>
      _WeekendLeagueDetailPageState();
}

class _WeekendLeagueDetailPageState extends State<WeekendLeagueDetailPage> {
  late Future<WeekendLeagueAccountStats> _future;
  late WeekendLeagueEvent _event;

  /// Carregada uma vez e reusada: trocar de semana refaz so as estatisticas,
  /// nunca a lista de semanas.
  late Future<List<WeekendLeagueEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _eventsFuture = getIt<FcAccountRepository>().fetchWeekendLeagueEvents();
    _load();
  }

  void _load() {
    _future = getIt<FcAccountRepository>().fetchWeekendLeagueAccountStats(
      accountId: widget.account.id,
      eventId: _event.id,
    );
  }

  Future<void> _pickWeek() async {
    final events = await _eventsFuture;
    if (!mounted || events.isEmpty) {
      return;
    }
    final picked = await showWeekendLeagueWeekPicker(
      context: context,
      events: events,
      selectedId: _event.id,
    );
    if (picked != null && picked.id != _event.id && mounted) {
      setState(() {
        _event = picked;
        _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.weekendLeagueBadge(_event.number)),
      body: FutureBuilder<WeekendLeagueAccountStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading();
          }
          final error = snapshot.error;
          if (error != null) {
            return AppErrorState(
              title: l10n.errorUnexpected,
              message: error is AppFailure
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => setState(_load),
            );
          }
          final stats = snapshot.data;
          if (stats == null) {
            return const SizedBox.shrink();
          }
          return _Body(
            account: widget.account,
            event: _event,
            stats: stats,
            onPickWeek: _pickWeek,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.account,
    required this.event,
    required this.stats,
    required this.onPickWeek,
  });

  final FcAccount account;
  final WeekendLeagueEvent event;
  final WeekendLeagueAccountStats stats;
  final Future<void> Function() onPickWeek;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    children: <Widget>[
      WeekendLeagueWeekSelector(event: event, onTap: onPickWeek),
      const SizedBox(height: AppSpacing.lg),
      _SummarySection(account: account, event: event, stats: stats),
      const SizedBox(height: AppSpacing.lg),
      _LeaderboardSection(
        title: context.l10n.statsTopScorersTitle,
        entries: stats.topScorers,
        showGoals: true,
      ),
      const SizedBox(height: AppSpacing.lg),
      _LeaderboardSection(
        title: context.l10n.statsTopAssistsTitle,
        entries: stats.topAssists,
        showGoals: false,
      ),
    ],
  );
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.account,
    required this.event,
    required this.stats,
  });

  final FcAccount account;
  final WeekendLeagueEvent event;
  final WeekendLeagueAccountStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final computed = stats.computed;
    final manual = stats.manual;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            manual != null
                ? '${manual.wins}–${manual.losses}'
                : '${computed.wins}–${computed.losses}',
            style: context.textStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            manual != null
                ? l10n.fcAccountWeekendLeagueManualLabel(
                    manual.wins,
                    manual.losses,
                  )
                : l10n.fcAccountWeekendLeagueComputedLabel(
                    computed.wins,
                    computed.losses,
                  ),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: l10n.statsGoalsLabel,
                  value: '${computed.goalsFor}',
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: l10n.statsGoalDiffLabel,
                  value: '${computed.goalDiff}',
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: l10n.statsMatchesLabel,
                  value: '${computed.matchesCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: l10n.fcAccountWeekendLeagueEditAction,
            icon: Icons.edit_outlined,
            onPressed: () => showWeekendLeagueManualRecordSheet(
              context: context,
              account: account,
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
    children: <Widget>[
      Text(value, style: context.textStyles.titleMedium),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    ],
  );
}

class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({
    required this.title,
    required this.entries,
    required this.showGoals,
  });

  final String title;
  final List<PlayerLeaderboardEntry> entries;
  final bool showGoals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title.toUpperCase(), style: context.textStyles.labelSmall),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text(
              showGoals
                  ? l10n.statsEmptyScorersMessage
                  : l10n.statsEmptyAssistsMessage,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.playerName,
                        style: context.textStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      showGoals ? '${entry.goals}' : '${entry.assists}',
                      style: context.textStyles.titleSmall,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
