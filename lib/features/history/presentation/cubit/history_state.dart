import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_entry.dart';
import 'package:fifa_queue/features/history/domain/entities/match_history_page.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';

enum HistoryStatus { initial, loading, ready, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.items = const <MatchHistoryEntry>[],
    this.hasMore = false,
    this.cursor,
    this.isLoadingMore = false,
    this.statusFilter,
    this.period = StatsPeriod.all,
    this.failure,
  });

  final HistoryStatus status;
  final List<MatchHistoryEntry> items;
  final bool hasMore;
  final MatchHistoryCursor? cursor;
  final bool isLoadingMore;
  final MatchSearchStatus? statusFilter;
  final StatsPeriod period;
  final AppFailure? failure;

  bool get isEmpty => status == HistoryStatus.ready && items.isEmpty;

  HistoryState copyWith({
    HistoryStatus? status,
    List<MatchHistoryEntry>? items,
    bool? hasMore,
    MatchHistoryCursor? cursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    MatchSearchStatus? statusFilter,
    bool clearStatusFilter = false,
    StatsPeriod? period,
    AppFailure? failure,
    bool clearFailure = false,
  }) => HistoryState(
    status: status ?? this.status,
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    cursor: clearCursor ? null : (cursor ?? this.cursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    statusFilter: clearStatusFilter
        ? null
        : (statusFilter ?? this.statusFilter),
    period: period ?? this.period,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    hasMore,
    cursor,
    isLoadingMore,
    statusFilter,
    period,
    failure,
  ];
}
