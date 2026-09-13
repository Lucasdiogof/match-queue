import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/weekend_league_week_picker.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_rank.dart';
import 'package:fifa_queue/features/game/presentation/widgets/debounced_win_loss_counter.dart';
import 'package:fifa_queue/features/game/presentation/widgets/weekend_league_rank_l10n.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalhe de uma campanha de Weekend League de uma conta: record manual
/// (unica fonte, ver FcAccount.weekendLeagueRecord). Artilharia/assistencia
/// saiu -- o produto nao rastreia mais gol/assistencia por partida, so o
/// placar que o usuario preenche.
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

  /// Capturados uma vez, nunca via `context.read`/`context.l10n` dentro do
  /// closure de onFlush -- ele pode ser chamado pelo dispose() do contador
  /// debounced, quando o context deste State pode ja estar desativado (ver
  /// doc de DebouncedWinLossCounter).
  late final FcAccountsCubit _cubit;

  /// `context.l10n` usa `Localizations.of`, que registra uma dependencia de
  /// InheritedWidget -- nunca seguro em initState() (so em build()/
  /// didChangeDependencies()). Capturado ali, nao aqui.
  late AppLocalizations _l10n;

  /// Carregada uma vez e reusada: trocar de semana refaz so as estatisticas,
  /// nunca a lista de semanas.
  late Future<List<WeekendLeagueEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<FcAccountsCubit>();
    _event = widget.event;
    _eventsFuture = getIt<FcAccountRepository>().fetchWeekendLeagueEvents();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = context.l10n;
  }

  void _load() {
    _future = getIt<FcAccountRepository>().fetchWeekendLeagueAccountStats(
      accountId: widget.account.id,
      eventId: _event.id,
    );
  }

  Future<String?> _flushIncrement(int winDelta, int lossDelta) async {
    final ok = await _cubit.incrementWeekendLeagueRecord(
      accountId: widget.account.id,
      winDelta: winDelta,
      lossDelta: lossDelta,
    );
    if (ok) {
      if (mounted) setState(_load);
      return null;
    }
    final failure = _cubit.state.actionFailure;
    _cubit.clearActionFailure();
    return failure?.localizedMessage(_l10n) ?? _l10n.errorUnexpected;
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
            onFlushIncrement: _flushIncrement,
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
    required this.onFlushIncrement,
  });

  final FcAccount account;
  final WeekendLeagueEvent event;
  final WeekendLeagueAccountStats stats;
  final Future<void> Function() onPickWeek;
  final Future<String?> Function(int winDelta, int lossDelta) onFlushIncrement;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    children: <Widget>[
      WeekendLeagueWeekSelector(event: event, onTap: onPickWeek),
      const SizedBox(height: AppSpacing.lg),
      _SummarySection(stats: stats, onFlush: onFlushIncrement),
    ],
  );
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.stats, required this.onFlush});

  final WeekendLeagueAccountStats stats;
  final Future<String?> Function(int winDelta, int lossDelta) onFlush;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manual = stats.manual;
    final wins = manual?.wins ?? 0;
    final losses = manual?.losses ?? 0;
    final rank = WeekendLeagueRank.fromWins(wins);

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (rank != null) ...<Widget>[
            AppBadge(label: rank.label),
            const SizedBox(height: AppSpacing.md),
          ],
          DebouncedWinLossCounter(
            wins: wins,
            losses: losses,
            winsLabel: l10n.statsWinsLabel,
            lossesLabel: l10n.statsLossesLabel,
            addWinTooltip: l10n.recordAddWinTooltip,
            addLossTooltip: l10n.recordAddLossTooltip,
            removeWinTooltip: l10n.recordRemoveWinTooltip,
            removeLossTooltip: l10n.recordRemoveLossTooltip,
            onFlush: onFlush,
          ),
        ],
      ),
    );
  }
}
