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

class HistoryPage extends StatefulWidget {
  const HistoryPage({this.fcAccountId, super.key});

  /// Quando vem da tela da Conta (Etapa de Solicitacoes), filtra a
  /// atividade so daquele Elenco dentro do time selecionado. Null = aba
  /// raiz, historico do time inteiro.
  final String? fcAccountId;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  // Dono unico do controller: sem time selecionado a TabBar nem aparece,
  // mas o controller precisa sobreviver a troca de time (a chave do
  // MultiBlocProvider recria os cubits, nao a aba selecionada).
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;
        return AppScaffold(
          appBar: AppAppBar(
            title: l10n.navHistory,
            accentTitle: true,
            bottom: selected == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: TabBar(
                      controller: _tabController,
                      tabs: <Widget>[
                        Tab(text: l10n.historyTabMatches),
                        Tab(text: l10n.historyTabStats),
                      ],
                    ),
                  ),
          ),
          body: AppBackground(
            child: selected == null
                ? AppEmptyState(
                    icon: Icons.timeline_outlined,
                    title: l10n.historyEmptyTitle,
                    message: l10n.historyNoTeamMessage,
                  )
                : _HistoryScope(
                    key: ValueKey('${selected.id}:${widget.fcAccountId}'),
                    teamId: selected.id,
                    fcAccountId: widget.fcAccountId,
                    tabController: _tabController,
                  ),
          ),
        );
      },
    );
  }
}

class _HistoryScope extends StatelessWidget {
  const _HistoryScope({
    required this.teamId,
    required this.tabController,
    this.fcAccountId,
    super.key,
  });

  final String teamId;
  final String? fcAccountId;
  final TabController tabController;

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
    child: TabBarView(
      controller: tabController,
      children: const <Widget>[ActivityTimelineView(), MatchmakingStatsView()],
    ),
  );
}
