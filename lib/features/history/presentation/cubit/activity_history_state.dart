import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/history/domain/entities/match_search_status.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';
import 'package:fifa_queue/features/history/domain/entities/team_activity_entry.dart';

enum ActivityHistoryStatus { initial, loading, ready, failure }

class ActivityHistoryState extends Equatable {
  const ActivityHistoryState({
    this.status = ActivityHistoryStatus.initial,
    this.items = const <TeamActivityEntry>[],
    this.hasMore = false,
    this.cursor,
    this.isLoadingMore = false,
    this.searchStatusFilter,
    this.period = StatsPeriod.last7Days,
    this.failure,
  });

  final ActivityHistoryStatus status;
  final List<TeamActivityEntry> items;
  final bool hasMore;
  final ActivityHistoryCursor? cursor;
  final bool isLoadingMore;
  final MatchSearchStatus? searchStatusFilter;
  final StatsPeriod period;
  final AppFailure? failure;

  bool get isEmpty => status == ActivityHistoryStatus.ready && items.isEmpty;

  ActivityHistoryState copyWith({
    ActivityHistoryStatus? status,
    List<TeamActivityEntry>? items,
    bool? hasMore,
    ActivityHistoryCursor? cursor,
    bool clearCursor = false,
    bool? isLoadingMore,
    MatchSearchStatus? searchStatusFilter,
    bool clearSearchStatusFilter = false,
    StatsPeriod? period,
    AppFailure? failure,
    bool clearFailure = false,
  }) => ActivityHistoryState(
    status: status ?? this.status,
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    cursor: clearCursor ? null : (cursor ?? this.cursor),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchStatusFilter: clearSearchStatusFilter
        ? null
        : (searchStatusFilter ?? this.searchStatusFilter),
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
    searchStatusFilter,
    period,
    failure,
  ];
}
