import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';

enum PendingMatchStatus { initial, loading, ready, failure }

class PendingMatchState extends Equatable {
  const PendingMatchState({
    this.status = PendingMatchStatus.initial,
    this.match,
    this.isSaving = false,
    this.actionFailure,
  });

  final PendingMatchStatus status;
  final PendingGameMatch? match;
  final bool isSaving;
  final AppFailure? actionFailure;

  bool get hasPending => match != null;

  PendingMatchState copyWith({
    PendingMatchStatus? status,
    PendingGameMatch? match,
    bool clearMatch = false,
    bool? isSaving,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => PendingMatchState(
    status: status ?? this.status,
    match: clearMatch ? null : (match ?? this.match),
    isSaving: isSaving ?? this.isSaving,
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[status, match, isSaving, actionFailure];
}
