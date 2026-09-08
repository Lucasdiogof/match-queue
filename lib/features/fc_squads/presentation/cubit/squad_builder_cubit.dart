import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/formation.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum SquadBuilderStatus { loading, ready, failure }

/// Slot marcado para mover. Guardar o alvo em vez de arrastar mantém a troca
/// possível no mobile sem depender de drag (item 37).
class PendingMove extends Equatable {
  const PendingMove({required this.type, required this.slotCode});

  final SquadSlotType type;
  final String slotCode;

  @override
  List<Object?> get props => <Object?>[type, slotCode];
}

class SquadBuilderState extends Equatable {
  const SquadBuilderState({
    this.status = SquadBuilderStatus.loading,
    this.squad,
    this.formations = const <FormationDefinition>[],
    this.pendingMove,
    this.savingSlot,
    this.isSaving = false,
    this.failure,
    this.actionFailure,
  });

  final SquadBuilderStatus status;
  final FcSquadDetail? squad;
  final List<FormationDefinition> formations;
  final PendingMove? pendingMove;

  /// Qual slot está gravando agora. Serve para o spinner ficar NO slot em vez
  /// de travar o campo inteiro a cada ação (item 105).
  final String? savingSlot;

  final bool isSaving;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  SquadBuilderState copyWith({
    SquadBuilderStatus? status,
    FcSquadDetail? squad,
    List<FormationDefinition>? formations,
    PendingMove? pendingMove,
    bool clearPendingMove = false,
    String? savingSlot,
    bool clearSavingSlot = false,
    bool? isSaving,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? actionFailure,
    bool clearActionFailure = false,
  }) => SquadBuilderState(
    status: status ?? this.status,
    squad: squad ?? this.squad,
    formations: formations ?? this.formations,
    pendingMove: clearPendingMove ? null : (pendingMove ?? this.pendingMove),
    savingSlot: clearSavingSlot ? null : (savingSlot ?? this.savingSlot),
    isSaving: isSaving ?? this.isSaving,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    squad,
    formations,
    pendingMove,
    savingSlot,
    isSaving,
    failure,
    actionFailure,
  ];
}

/// Estado do Squad Builder, escopado a UM squad.
///
/// Persistência é por ação: cada mudança chama a RPC e o estado passa a ser a
/// resposta dela. Não existe botão "salvar tudo" -- e, se uma chamada falhar,
/// o que fica na tela é o estado que o servidor devolveu, nunca um campo
/// otimista divergente do backend (item 106).
class SquadBuilderCubit extends Cubit<SquadBuilderState> {
  SquadBuilderCubit(this._repository, {required this.squadId})
    : super(const SquadBuilderState());

  final FcSquadRepository _repository;
  final String squadId;

  Future<void> load() async {
    emit(
      state.copyWith(status: SquadBuilderStatus.loading, clearFailure: true),
    );
    try {
      final formations = state.formations.isEmpty
          ? await _repository.listFormations()
          : state.formations;
      final squad = await _repository.getBuilder(squadId);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: SquadBuilderStatus.ready,
          squad: squad,
          formations: formations,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: SquadBuilderStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<bool> rename(String name) =>
      _run(() => _repository.renameSquad(squadId: squadId, name: name));

  Future<bool> setFormation(String formationCode) => _run(
    () => _repository.setFormation(
      squadId: squadId,
      formationCode: formationCode,
    ),
  );

  Future<bool> setDefault() => _run(() => _repository.setDefault(squadId));

  Future<bool> assignCard({
    required SquadSlotType type,
    required String slotCode,
    required String playerCardId,
  }) => _run(
    () => _repository.setSlot(
      squadId: squadId,
      type: type,
      slotCode: slotCode,
      playerCardId: playerCardId,
    ),
    slot: slotCode,
  );

  Future<bool> clearSlot({
    required SquadSlotType type,
    required String slotCode,
  }) => _run(
    () =>
        _repository.clearSlot(squadId: squadId, type: type, slotCode: slotCode),
    slot: slotCode,
  );

  /// Move/troca vindo de um drop (drag and drop). Reusa a MESMA RPC atômica
  /// do tap-to-swap (`swap_fc_squad_slots`) -- nunca um clear+set em dois
  /// passos, que deixaria o squad inconsistente se o segundo passo falhasse.
  /// Soltar em cima do próprio slot de origem é um no-op silencioso.
  Future<bool> moveOrSwap({
    required SquadSlotType fromType,
    required String fromSlotCode,
    required SquadSlotType toType,
    required String toSlotCode,
  }) {
    if (fromType == toType && fromSlotCode == toSlotCode) {
      return Future.value(false);
    }
    if (state.pendingMove != null) {
      emit(state.copyWith(clearPendingMove: true));
    }
    return _run(
      () => _repository.swapSlots(
        squadId: squadId,
        fromType: fromType,
        fromCode: fromSlotCode,
        toType: toType,
        toCode: toSlotCode,
      ),
      slot: toSlotCode,
    );
  }

  /// "Limpar escalação": apaga só os slots (titular+banco+reserva), nunca o
  /// squad em si. Confirmação mora na UI.
  Future<bool> clearAllSlots() => _run(() => _repository.clearSlots(squadId));

  Future<bool> setManager({String? managerId, String? managerLeagueId}) => _run(
    () => _repository.setManager(
      squadId: squadId,
      managerId: managerId,
      managerLeagueId: managerLeagueId,
    ),
  );

  /// Primeiro toque marca a origem; o segundo executa a troca. Tocar de novo
  /// no mesmo slot cancela.
  Future<void> tapForMove({
    required SquadSlotType type,
    required String slotCode,
  }) async {
    final pending = state.pendingMove;
    if (pending == null) {
      emit(
        state.copyWith(
          pendingMove: PendingMove(type: type, slotCode: slotCode),
        ),
      );
      return;
    }
    if (pending.type == type && pending.slotCode == slotCode) {
      emit(state.copyWith(clearPendingMove: true));
      return;
    }
    emit(state.copyWith(clearPendingMove: true));
    await _run(
      () => _repository.swapSlots(
        squadId: squadId,
        fromType: pending.type,
        fromCode: pending.slotCode,
        toType: type,
        toCode: slotCode,
      ),
      slot: slotCode,
    );
  }

  void cancelMove() {
    if (state.pendingMove != null) {
      emit(state.copyWith(clearPendingMove: true));
    }
  }

  void clearActionFailure() {
    if (state.actionFailure != null) {
      emit(state.copyWith(clearActionFailure: true));
    }
  }

  Future<bool> _run(
    Future<FcSquadDetail> Function() action, {
    String? slot,
  }) async {
    if (state.isSaving) {
      return false;
    }
    emit(
      state.copyWith(
        isSaving: true,
        savingSlot: slot,
        clearSavingSlot: slot == null,
        clearActionFailure: true,
      ),
    );
    try {
      final squad = await action();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SquadBuilderStatus.ready,
            squad: squad,
            isSaving: false,
            clearSavingSlot: true,
          ),
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSaving: false,
            clearSavingSlot: true,
            actionFailure: failure,
          ),
        );
        // Recarrega o estado autoritativo: melhor uma ida a mais ao servidor
        // do que a tela seguir mostrando algo que não aconteceu.
        await load();
      }
      return false;
    }
  }
}
