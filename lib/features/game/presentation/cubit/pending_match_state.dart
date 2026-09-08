import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

enum PendingMatchStatus { initial, loading, ready, failure }

class PendingMatchState extends Equatable {
  const PendingMatchState({
    this.status = PendingMatchStatus.initial,
    this.match,
    this.weekendLeagueEvent,
    this.isSaving = false,
    this.actionFailure,
  });

  final PendingMatchStatus status;
  final PendingGameMatch? match;
  final WeekendLeagueEvent? weekendLeagueEvent;
  final bool isSaving;
  final AppFailure? actionFailure;

  bool get hasPending => match != null;

  PendingMatchState copyWith({
    PendingMatchStatus? status,
    PendingGameMatch? match,
    bool clearMatch = false,
    WeekendLeagueEvent? weekendLeagueEvent,
    bool clearWeekendLeagueEvent = false,
    bool? isSaving,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => PendingMatchState(
    status: status ?? this.status,
    match: clearMatch ? null : (match ?? this.match),
    weekendLeagueEvent: clearWeekendLeagueEvent
        ? null
        : (weekendLeagueEvent ?? this.weekendLeagueEvent),
    isSaving: isSaving ?? this.isSaving,
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    match,
    weekendLeagueEvent,
    isSaving,
    actionFailure,
  ];
}
