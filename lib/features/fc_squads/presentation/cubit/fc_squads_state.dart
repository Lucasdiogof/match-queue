import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';

enum FcSquadsStatus { initial, loading, ready, failure }

class FcSquadsState extends Equatable {
  const FcSquadsState({
    this.status = FcSquadsStatus.initial,
    this.squads = const <FcSquadSummary>[],
    this.formations = const <FormationDefinition>[],
    this.accountId,
    this.selectedSquadId,
    this.isSaving = false,
    this.failure,
    this.actionFailure,
  });

  final FcSquadsStatus status;
  final List<FcSquadSummary> squads;
  final List<FormationDefinition> formations;
  final String? accountId;

  /// Squad escolhido para a PRÓXIMA busca. Começa no default do elenco, mas
  /// trocar aqui não muda o default global (item 70) -- vale só para a
  /// partida que o usuário está prestes a procurar.
  final String? selectedSquadId;

  final bool isSaving;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  bool get isLoading => status == FcSquadsStatus.loading;

  bool get hasSquads => squads.isNotEmpty;

  FcSquadSummary? get selectedSquad {
    for (final squad in squads) {
      if (squad.id == selectedSquadId) {
        return squad;
      }
    }
    return null;
  }

  FcSquadSummary? get defaultSquad {
    for (final squad in squads) {
      if (squad.isDefault) {
        return squad;
      }
    }
    return null;
  }

  FcSquadsState copyWith({
    FcSquadsStatus? status,
    List<FcSquadSummary>? squads,
    List<FormationDefinition>? formations,
    String? accountId,
    String? selectedSquadId,
    bool clearSelectedSquadId = false,
    bool? isSaving,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => FcSquadsState(
    status: status ?? this.status,
    squads: squads ?? this.squads,
    formations: formations ?? this.formations,
    accountId: accountId ?? this.accountId,
    selectedSquadId: clearSelectedSquadId
        ? null
        : (selectedSquadId ?? this.selectedSquadId),
    isSaving: isSaving ?? this.isSaving,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    squads,
    formations,
    accountId,
    selectedSquadId,
    isSaving,
    failure,
    actionFailure,
  ];
}
