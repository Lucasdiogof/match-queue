import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_snapshot.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, {Stream<void>? sessionExpired})
    : _sessionExpired = sessionExpired,
      super(const AuthState());

  final AuthRepository _repository;
  final Stream<void>? _sessionExpired;

  StreamSubscription<AuthSnapshot>? _subscription;
  StreamSubscription<void>? _sessionExpiredSubscription;
  bool _recoveringSession = false;

  void initialize() {
    _applyUser(_repository.currentUser);
    _subscription ??= _repository.watchAuthState().listen(_applySnapshot);
    _sessionExpiredSubscription ??= _sessionExpired?.listen(
      (_) => unawaited(_recoverSession()),
    );
  }

  /// Chamado ao voltar do segundo plano: renova o token so se ja venceu (ou
  /// esta pra vencer), antes de o usuario tocar em algo e tomar erro.
  Future<void> refreshSessionIfNeeded() async {
    if (state.status != AuthStatus.authenticated ||
        !_repository.isSessionExpiring) {
      return;
    }
    await _recoverSession();
  }

  /// Tenta renovar a sessao uma vez. Sem internet nao faz nada (o token pode
  /// estar bom); token invalido de verdade desloga e leva pro login com
  /// aviso -- em vez de cada tela mostrar um erro generico.
  Future<void> _recoverSession() async {
    if (_recoveringSession || state.status != AuthStatus.authenticated) {
      return;
    }
    _recoveringSession = true;
    try {
      await _repository.refreshSession();
    } on NetworkFailure {
      // sem rede: mantem a sessao, a proxima acao tenta de novo.
    } on TimeoutFailure {
      // idem.
    } on AppFailure {
      await _expireSession();
    } finally {
      _recoveringSession = false;
    }
  }

  Future<void> _expireSession() async {
    try {
      await _repository.signOut();
    } on AppFailure {
      // O token ja nao vale; o que importa e limpar o estado local abaixo.
    }
    if (!isClosed) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          failure: AuthFailure(reason: AuthFailureReason.sessionExpired),
        ),
      );
    }
  }

  Future<bool> signIn({required String email, required String password}) =>
      _submit(
        () => _repository.signInWithEmail(
          email: AppValidators.normalizeEmail(email),
          password: password,
        ),
      );

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _submit(
    () => _repository.signUpWithEmail(
      email: AppValidators.normalizeEmail(email),
      password: password,
      displayName: AppValidators.normalizeDisplayName(displayName),
    ),
  );

  Future<bool> sendPasswordReset(String email) => _run(
    () => _repository.sendPasswordReset(AppValidators.normalizeEmail(email)),
  );

  Future<bool> updatePassword(String newPassword) async {
    final succeeded = await _run(() => _repository.updatePassword(newPassword));
    if (succeeded && !isClosed) {
      emit(state.copyWith(isPasswordRecovery: false));
    }
    return succeeded;
  }

  Future<bool> signOut() async {
    final succeeded = await _run(_repository.signOut);
    if (succeeded && !isClosed) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
    return succeeded;
  }

  Future<bool> deleteAccount() async {
    final succeeded = await _run(_repository.deleteAccount);
    if (succeeded && !isClosed) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
    return succeeded;
  }

  void clearFailure() {
    if (state.failure != null) {
      emit(state.copyWith(clearFailure: true));
    }
  }

  void dismissPasswordRecovery() {
    if (state.isPasswordRecovery) {
      emit(state.copyWith(isPasswordRecovery: false));
    }
  }

  Future<bool> _submit(Future<AuthUser> Function() action) async {
    if (state.isSubmitting) {
      return false;
    }
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      final user = await action();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isSubmitting: false,
          ),
        );
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSubmitting: false, failure: failure));
      }
      return false;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isSubmitting) {
      return false;
    }
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      await action();
      if (!isClosed) {
        emit(state.copyWith(isSubmitting: false));
      }
      return true;
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(state.copyWith(isSubmitting: false, failure: failure));
      }
      return false;
    }
  }

  void _applySnapshot(AuthSnapshot snapshot) {
    if (isClosed) {
      return;
    }
    if (snapshot.isPasswordRecovery) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: snapshot.user,
          isSubmitting: false,
          isPasswordRecovery: true,
        ),
      );
      return;
    }
    _applyUser(snapshot.user);
  }

  void _applyUser(AuthUser? user) {
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        status: user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        user: user,
        clearUser: user == null,
        isSubmitting: false,
        isPasswordRecovery: user == null ? false : state.isPasswordRecovery,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _sessionExpiredSubscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
