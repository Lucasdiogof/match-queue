import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_accounts/data/selected_fc_account_store.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Elencos do usuário + qual está selecionado agora. App-scoped como
/// TeamsCubit -- mesma forma (lista + seleção persistida e revalidada
/// contra a lista real, nunca "accounts.first" cego), mesmo motivo.
class FcAccountsCubit extends Cubit<FcAccountsState> {
  FcAccountsCubit(this._repository, this._selectedStore)
    : super(const FcAccountsState());

  final FcAccountRepository _repository;
  final SelectedFcAccountStore _selectedStore;

  String? _userId;

  Future<void> load({required String userId}) async {
    _userId = userId;
    emit(state.copyWith(status: FcAccountsStatus.loading, clearFailure: true));
    try {
      final snapshot = await _repository.fetchMyAccounts();
      final selectedId = _resolveSelectedId(snapshot.accounts, userId);
      emit(
        state.copyWith(
          status: FcAccountsStatus.ready,
          accounts: snapshot.accounts,
          weekendLeagueEvent: snapshot.weekendLeagueEvent,
          clearWeekendLeagueEvent: snapshot.weekendLeagueEvent == null,
          selectedAccountId: selectedId,
          clearSelectedAccountId: selectedId == null,
          clearFailure: true,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(status: FcAccountsStatus.failure, failure: failure),
        );
      }
    }
  }

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await load(userId: userId);
  }

  Future<void> selectAccount(String accountId) async {
    if (state.selectedAccountId == accountId) {
      return;
    }
    if (!state.accounts.any((account) => account.id == accountId)) {
      return;
    }
    emit(state.copyWith(selectedAccountId: accountId));
    await _persistSelected(accountId);
  }

  Future<bool> createAccount(String name) =>
      _mutate(() => _repository.createAccount(name), selectNewest: true);

  Future<bool> updateAccount({required String id, required String name}) =>
      _mutate(() => _repository.updateAccount(id: id, name: name));

  Future<bool> archiveAccount(String id) => _mutate(
    () => _repository.archiveAccount(id),
    clearSelectionIfArchived: id,
  );

  Future<bool> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  }) => _mutate(
    () => _repository.updateRivalsDivision(id: id, division: division),
  );

  Future<bool> linkToTeam({
    required String accountId,
    required String teamId,
  }) => _mutate(
    () => _repository.linkToTeam(accountId: accountId, teamId: teamId),
  );

  Future<bool> unlinkFromTeam({
    required String accountId,
    required String teamId,
  }) => _mutate(
    () => _repository.unlinkFromTeam(accountId: accountId, teamId: teamId),
  );

  Future<bool> setWeekendLeagueManualRecord({
    required String accountId,
    required int wins,
    required int losses,
  }) async {
    final eventId = state.weekendLeagueEvent?.id;
    if (eventId == null) {
      return false;
    }
    return _mutate(
      () => _repository.setWeekendLeagueManualRecord(
        accountId: accountId,
        eventId: eventId,
        wins: wins,
        losses: losses,
      ),
    );
  }

  Future<bool> clearWeekendLeagueManualRecord(String accountId) async {
    final eventId = state.weekendLeagueEvent?.id;
    if (eventId == null) {
      return false;
    }
    return _mutate(
      () => _repository.clearWeekendLeagueManualRecord(
        accountId: accountId,
        eventId: eventId,
      ),
    );
  }

  void clearActionFailure() {
    if (state.actionFailure != null) {
      emit(state.copyWith(clearActionFailure: true));
    }
  }

  void clear() {
    _userId = null;
    emit(const FcAccountsState());
  }

  Future<bool> _mutate(
    Future<void> Function() action, {
    bool selectNewest = false,
    String? clearSelectionIfArchived,
  }) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearActionFailure: true));
    try {
      await action();
      final userId = _userId;
      if (userId == null) {
        emit(state.copyWith(isSaving: false));
        return true;
      }
      final snapshot = await _repository.fetchMyAccounts();
      var selectedId = state.selectedAccountId;
      if (clearSelectionIfArchived != null &&
          selectedId == clearSelectionIfArchived) {
        selectedId = null;
      }
      if (selectNewest && snapshot.accounts.isNotEmpty) {
        selectedId = snapshot.accounts.last.id;
      }
      final resolvedId = _resolveSelectedId(
        snapshot.accounts,
        userId,
        preferred: selectedId,
      );
      emit(
        state.copyWith(
          status: FcAccountsStatus.ready,
          accounts: snapshot.accounts,
          weekendLeagueEvent: snapshot.weekendLeagueEvent,
          clearWeekendLeagueEvent: snapshot.weekendLeagueEvent == null,
          selectedAccountId: resolvedId,
          clearSelectedAccountId: resolvedId == null,
          isSaving: false,
          clearActionFailure: true,
        ),
      );
      await _persistSelected(resolvedId);
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, actionFailure: failure));
      }
      return false;
    }
  }

  String? _resolveSelectedId(
    List<FcAccount> accounts,
    String userId, {
    String? preferred,
  }) {
    if (accounts.isEmpty) {
      return null;
    }
    final candidate = preferred ?? _selectedStore.read(userId);
    if (candidate != null &&
        accounts.any((account) => account.id == candidate)) {
      return candidate;
    }
    return accounts.first.id;
  }

  Future<void> _persistSelected(String? accountId) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _selectedStore.write(userId, accountId);
  }
}
