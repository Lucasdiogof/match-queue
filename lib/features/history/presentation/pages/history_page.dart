import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_cubit.dart';
import 'package:fifa_queue/features/history/presentation/cubit/stats_cubit.dart';
import 'package:fifa_queue/features/history/presentation/widgets/activity_timeline_view.dart';
import 'package:fifa_queue/features/history/presentation/widgets/matchmaking_stats_view.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({this.fcAccountId, super.key});

  /// Quando vem da tela da Conta (Etapa de Solicitacoes), filtra a
  /// atividade so daquele Elenco dentro do time selecionado. Null = aba
  /// raiz, historico do time inteiro.
  final String? fcAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;
        return AppScaffold(
          appBar: AppAppBar(
            title: fcAccountId == null ? null : l10n.navHistory,
          ),
          body: AppBackground(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (fcAccountId == null) FeatureHeader(title: l10n.navHistory),
                Expanded(
                  child: selected == null
                      ? AppEmptyState(
                          icon: Icons.timeline_outlined,
                          title: l10n.historyEmptyTitle,
                          message: l10n.historyNoTeamMessage,
                        )
                      : _HistoryScope(
                          key: ValueKey('${selected.id}:$fcAccountId'),
                          teamId: selected.id,
                          fcAccountId: fcAccountId,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryScope extends StatelessWidget {
  const _HistoryScope({required this.teamId, this.fcAccountId, super.key});

  final String teamId;
  final String? fcAccountId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ActivityHistoryCubit>(
        create: (_) => ActivityHistoryCubit(
          getIt<HistoryRepository>(),
          teamId: teamId,
          fcAccountId: fcAccountId,
        )..load(),
      ),
      BlocProvider<StatsCubit>(
        create: (_) =>
            StatsCubit(getIt<HistoryRepository>(), teamId: teamId)..load(),
      ),
    ],
    child: const _HistoryTabs(),
  );
}

class _HistoryTabs extends StatefulWidget {
  const _HistoryTabs();

  @override
  State<_HistoryTabs> createState() => _HistoryTabsState();
}

class _HistoryTabsState extends State<_HistoryTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            AppChip(
              label: l10n.historyTabMatches,
              isSelected: _index == 0,
              onPressed: () => setState(() => _index = 0),
            ),
            AppChip(
              label: l10n.historyTabStats,
              isSelected: _index == 1,
              onPressed: () => setState(() => _index = 1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: IndexedStack(
            index: _index,
            sizing: StackFit.expand,
            children: const <Widget>[
              ActivityTimelineView(),
              MatchmakingStatsView(),
            ],
          ),
        ),
      ],
    );
  }
}
