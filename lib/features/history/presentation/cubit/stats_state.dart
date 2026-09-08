import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/history/domain/entities/matchmaking_stats.dart';
import 'package:fifa_queue/features/history/domain/entities/stats_period.dart';

enum StatsStatus { initial, loading, ready, failure }

class StatsState extends Equatable {
  const StatsState({
    this.status = StatsStatus.initial,
    this.stats,
    this.period = StatsPeriod.all,
    this.failure,
  });

  final StatsStatus status;
  final MatchmakingStats? stats;
  final StatsPeriod period;
  final AppFailure? failure;

  StatsState copyWith({
    StatsStatus? status,
    MatchmakingStats? stats,
    StatsPeriod? period,
    AppFailure? failure,
    bool clearFailure = false,
  }) => StatsState(
    status: status ?? this.status,
    stats: stats ?? this.stats,
    period: period ?? this.period,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[status, stats, period, failure];
}
