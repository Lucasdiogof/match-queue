import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/fc_squad.dart';
import 'package:fifa_queue/features/fc_squads/domain/repositories/fc_squad_repository.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lista de squads do Elenco selecionado, mais a escolha de qual usar na
/// próxima busca.
///
/// Um cubit só, não dois: a lista e a seleção mudam sempre juntas (trocar de
/// elenco troca as duas), e separá-las obrigaria a sincronizar dois estados
/// que nunca divergem. O estado detalhado do builder tem cubit próprio,
/// escopado por squad -- esse sim é outro ciclo de vida.
class FcSquadsCubit extends Cubit<FcSquadsState> {
  FcSquadsCubit(this._repository) : super(const FcSquadsState());

  final FcSquadRepository _repository;

  /// Trocar de elenco descarta a lista anterior ANTES de buscar a nova: sem
  /// isso a tela mostraria por um instante os squads da conta antiga (item
  /// 127).
  Future<void> load(String? accountId) async {
    if (accountId == null) {
      emit(const FcSquadsState(status: FcSquadsStatus.ready));
      return;
    }

    emit(
      FcSquadsState(
        status: FcSquadsStatus.loading,
        accountId: accountId,
      ).copyWith(formations: state.formations),
    );

    try {
      final formations = state.formations.isEmpty
          ? await _repository.listFormations()
          : state.formations;
      final squads = await _repository.listSquads(accountId);
      if (isClosed || state.accountId != accountId) {
        return;
      }
      emit(
        state.copyWith(
          status: FcSquadsStatus.ready,
          squads: squads,
          formations: formations,
          selectedSquadId: _resolveSelected(squads),
          clearSelectedSquadId: squads.isEmpty,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed && state.accountId == accountId) {
        emit(state.copyWith(status: FcSquadsStatus.failure, failure: failure));
      }
    }
  }

  Future<void> refresh() => load(state.accountId);

  /// Escolha válida só para a próxima busca; o default do elenco continua
  /// como está.
  void selectForNextSearch(String squadId) {
    if (state.squads.any((s) => s.id == squadId)) {
      emit(state.copyWith(selectedSquadId: squadId));
    }
  }

  Future<FcSquadDetail?> createSquad({
    required String name,
    required String formationCode,
  }) async {
    final accountId = state.accountId;
    if (accountId == null || state.isSaving) {
      return null;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      final squad = await _repository.createSquad(
        fcAccountId: accountId,
        name: name,
        formationCode: formationCode,
      );
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
        await refresh();
      }
      return squad;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return null;
    }
  }

  Future<bool> setDefault(String squadId) =>
      _run(() => _repository.setDefault(squadId));

  Future<bool> archive(String squadId) =>
      _run(() => _repository.archiveSquad(squadId));

  void clearActionFailure() {
    if (state.actionFailure != null) {
      emit(state.copyWith(clearActionFailure: true));
    }
  }

  void clear() => emit(const FcSquadsState());

  String? _resolveSelected(List<FcSquadSummary> squads) {
    if (squads.isEmpty) {
      return null;
    }
    // Mantém a escolha do usuário se ela ainda existe; senão volta pro
    // default do elenco (item 126).
    final current = state.selectedSquadId;
    if (current != null && squads.any((s) => s.id == current)) {
      return current;
    }
    for (final squad in squads) {
      if (squad.isDefault) {
        return squad.id;
      }
    }
    return squads.first.id;
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await action();
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
        await refresh();
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }
}
