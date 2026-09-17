import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/account/domain/entities/platform.dart';
import 'package:fifa_queue/features/account/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/account/domain/repositories/account_repository.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repository) : super(const AccountState());

  final AccountRepository _repository;

  Future<void> load({required String fallbackDisplayName}) async {
    emit(state.copyWith(status: AccountStatus.loading, clearFailure: true));
    try {
      final account = await _repository.ensureMyAccount(
        fallbackDisplayName: fallbackDisplayName,
      );
      if (!isClosed) {
        emit(AccountState(status: AccountStatus.ready, account: account));
      }
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(status: AccountStatus.failure, failure: failure));
      }
    }
  }

  Future<void> refresh() async {
    try {
      final account = await _repository.fetchMyAccount();
      if (!isClosed && account != null) {
        emit(state.copyWith(status: AccountStatus.ready, account: account));
      }
    } on AppFailure {
      // Silencioso de proposito: refresh nunca deve derrubar uma tela que
      // ja tinha dado certo antes.
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearFailure: true));
    try {
      final account = await _repository.updateDisplayName(displayName);
      if (!isClosed) {
        emit(AccountState(status: AccountStatus.ready, account: account));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, failure: failure));
      }
      return false;
    }
  }

  Future<bool> updatePlatforms(List<Platform> platforms) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearFailure: true));
    try {
      await _repository.updatePlatforms(platforms);
      await refresh();
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, failure: failure));
      }
      return false;
    }
  }

  Future<bool> updateRivalsDivision(RivalsDivision? division) async {
    if (state.isSaving) {
      return false;
    }
    emit(state.copyWith(isSaving: true, clearFailure: true));
    try {
      await _repository.updateRivalsDivision(division);
      await refresh();
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, failure: failure));
      }
      return false;
    }
  }

  Future<bool> incrementRivalsRecord({int winDelta = 0, int lossDelta = 0}) =>
      _mutateThenRefresh(
        () => _repository.incrementRivalsRecord(
          winDelta: winDelta,
          lossDelta: lossDelta,
        ),
      );

  Future<bool> incrementWeekendLeagueRecord({
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) => _mutateThenRefresh(
    () => _repository.incrementWeekendLeagueRecord(
      eventId: eventId,
      winDelta: winDelta,
      lossDelta: lossDelta,
    ),
  );

  /// Sobrescreve o placar da campanha inteira de uma vez (o sheet de "editar
  /// resultado"), em vez de somar delta a delta como o contador da tela.
  Future<bool> setWeekendLeagueManualRecord({
    required String eventId,
    required int wins,
    required int losses,
  }) => _mutateThenRefresh(
    () => _repository.setWeekendLeagueManualRecord(
      eventId: eventId,
      wins: wins,
      losses: losses,
    ),
  );

  /// Volta a campanha pro estado "sem registro manual" -- diferente de zerar,
  /// que gravaria 0-0 como se a pessoa tivesse jogado e perdido nada.
  Future<bool> clearWeekendLeagueManualRecord(String eventId) =>
      _mutateThenRefresh(
        () => _repository.clearWeekendLeagueManualRecord(eventId),
      );

  Future<bool> _mutateThenRefresh(Future<void> Function() action) async {
    try {
      await action();
      await refresh();
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(failure: failure));
      }
      return false;
    }
  }

  void clearActionFailure() => clearFailure();

  void clearFailure() {
    if (state.failure != null) {
      emit(state.copyWith(clearFailure: true));
    }
  }

  void clear() => emit(const AccountState());
}
