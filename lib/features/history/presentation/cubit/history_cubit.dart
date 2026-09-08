import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:fifa_queue/features/history/presentation/cubit/history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository, {required this.teamId})
    : super(const HistoryState());

  final HistoryRepository _repository;
  final String teamId;

  static const int _pageSize = 20;

  Future<void> load() async {
    emit(state.copyWith(status: HistoryStatus.loading, clearFailure: true));
    try {
      final page = await _repository.fetchHistory(
        teamId: teamId,
        limit: _pageSize,
        status: state.statusFilter,
        from: state.period.from(DateTime.now().toUtc()),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: HistoryStatus.ready,
            items: page.items,
            hasMore: page.hasMore,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            isLoadingMore: false,
            clearFailure: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: HistoryStatus.failure, failure: failure));
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.cursor == null) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchHistory(
        teamId: teamId,
        limit: _pageSize,
        cursor: state.cursor,
        status: state.statusFilter,
        from: state.period.from(DateTime.now().toUtc()),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            items: <MatchHistoryEntry>[...state.items, ...page.items],
            hasMore: page.hasMore,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            isLoadingMore: false,
          ),
        );
      }
    } on AppFailure {
      // Falha ao paginar não derruba a lista já carregada; só solta o spinner
      // do rodapé e deixa o usuário tentar de novo rolando.
      if (!isClosed) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> setStatusFilter(MatchSearchStatus? status) async {
    if (state.statusFilter == status) {
      return;
    }
    emit(
      state.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
    await load();
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
