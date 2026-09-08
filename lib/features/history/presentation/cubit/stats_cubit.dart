import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:fifa_queue/features/history/presentation/cubit/stats_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._repository, {required this.teamId})
    : super(const StatsState());

  final HistoryRepository _repository;
  final String teamId;

  Future<void> load() async {
    emit(state.copyWith(status: StatsStatus.loading, clearFailure: true));
    try {
      final stats = await _repository.fetchStats(
        teamId: teamId,
        from: state.period.from(DateTime.now().toUtc()),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: StatsStatus.ready,
            stats: stats,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: StatsStatus.failure, failure: failure));
      }
    }
  }

  Future<void> setPeriod(StatsPeriod period) async {
    if (state.period == period) {
      return;
    }
    emit(state.copyWith(period: period));
    await load();
  }

  Future<void> refresh() => load();
}
