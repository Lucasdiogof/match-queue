import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/game/domain/entities/pending_game_match.dart';

enum PendingMatchStatus { initial, loading, ready, failure }

class PendingMatchState extends Equatable {
  const PendingMatchState({
    this.status = PendingMatchStatus.initial,
    this.matches = const <PendingGameMatch>[],
    this.isSaving = false,
    this.actionFailure,
  });

  final PendingMatchStatus status;

  /// Todas as partidas sem resultado e nao dispensadas, da mais recente para
  /// a mais antiga. Podem ser varias: informar resultado nunca foi
  /// obrigatorio, entao pendencia se acumula em vez de se perder.
  final List<PendingGameMatch> matches;

  final bool isSaving;
  final AppFailure? actionFailure;

  bool get hasPending => matches.isNotEmpty;

  int get pendingCount => matches.length;

  /// A mais recente. Os fluxos de "informar agora" agem sobre ela por
  /// padrao, que e o que o usuario acabou de jogar.
  PendingGameMatch? get match => matches.isEmpty ? null : matches.first;

  PendingGameMatch? byId(String id) {
    for (final candidate in matches) {
      if (candidate.id == id) {
        return candidate;
      }
    }
    return null;
  }

  PendingMatchState copyWith({
    PendingMatchStatus? status,
    List<PendingGameMatch>? matches,
    bool? isSaving,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => PendingMatchState(
    status: status ?? this.status,
    matches: matches ?? this.matches,
    isSaving: isSaving ?? this.isSaving,
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    matches,
    isSaving,
    actionFailure,
  ];
}
