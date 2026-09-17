import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_cubit.dart';
import 'package:fifa_queue/features/history/presentation/widgets/activity_timeline_view.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({this.userId, super.key});

  /// Quando vem da tela da Conta (Etapa de Solicitacoes), filtra a
  /// atividade so daquele Elenco dentro do time selecionado. Null = aba
  /// raiz, historico do time inteiro.
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeamsCubit, TeamsState>(
      builder: (context, state) {
        final selected = state.selectedTeam;
        return AppScaffold(
          appBar: AppAppBar(title: l10n.navHistory, accentTitle: true),
          body: AppBackground(
            child: selected == null
                ? AppEmptyState(
                    icon: Icons.timeline_outlined,
                    title: l10n.historyEmptyTitle,
                    message: l10n.historyNoTeamMessage,
                  )
                : BlocProvider<ActivityHistoryCubit>(
                    key: ValueKey('${selected.id}:$userId'),
                    create: (_) => ActivityHistoryCubit(
                      getIt<HistoryRepository>(),
                      teamId: selected.id,
                      userId: userId,
                    )..load(),
                    child: const ActivityTimelineView(),
                  ),
          ),
        );
      },
    );
  }
}
