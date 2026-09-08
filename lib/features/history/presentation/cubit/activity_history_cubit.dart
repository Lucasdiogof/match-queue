import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/game_result.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';
import 'package:fifa_queue/features/history/domain/repositories/history_repository.dart';
import 'package:fifa_queue/features/history/presentation/cubit/activity_history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityHistoryCubit extends Cubit<ActivityHistoryState> {
  ActivityHistoryCubit(this._repository, {required this.teamId})
    : super(const ActivityHistoryState());

  final HistoryRepository _repository;
  final String teamId;

  static const int _pageSize = 20;

  Future<void> load() async {
    emit(
      state.copyWith(status: ActivityHistoryStatus.loading, clearFailure: true),
    );
    try {
      final page = await _repository.fetchActivityHistory(
        teamId: teamId,
        limit: _pageSize,
        scope: state.scope,
        gameResult: state.gameResultFilter,
        searchStatus: state.searchStatusFilter,
        from: state.period.from(DateTime.now().toUtc()),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ActivityHistoryStatus.ready,
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
        emit(
          state.copyWith(status: ActivityHistoryStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.cursor == null) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchActivityHistory(
        teamId: teamId,
        limit: _pageSize,
        cursor: state.cursor,
        scope: state.scope,
        gameResult: state.gameResultFilter,
        searchStatus: state.searchStatusFilter,
        from: state.period.from(DateTime.now().toUtc()),
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            items: <TeamActivityEntry>[...state.items, ...page.items],
            hasMore: page.hasMore,
            cursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            isLoadingMore: false,
          ),
        );
      }
    } on AppFailure {
      if (!isClosed) {
        emit(state.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> setScope(ActivityScope scope) async {
    if (state.scope == scope) {
      return;
    }
    emit(
      state.copyWith(
        scope: scope,
        clearGameResultFilter: true,
        clearSearchStatusFilter: true,
      ),
    );
    await load();
  }

  Future<void> setGameResultFilter(GameResult? result) async {
    if (state.gameResultFilter == result) {
      return;
    }
    emit(
      state.copyWith(
        gameResultFilter: result,
        clearGameResultFilter: result == null,
      ),
    );
    await load();
  }

  Future<void> setSearchStatusFilter(MatchSearchStatus? status) async {
    if (state.searchStatusFilter == status) {
      return;
    }
    emit(
      state.copyWith(
        searchStatusFilter: status,
        clearSearchStatusFilter: status == null,
      ),
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
