import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  StreamSubscription<AuthUser?>? _subscription;

  void initialize() {
    _apply(_repository.currentUser);
    _subscription ??= _repository.watchCurrentUser().listen(_apply);
  }

  Future<void> signIn({required String email, required String password}) =>
      _submit(
        () => _repository.signInWithEmail(email: email, password: password),
      );

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) => _submit(
    () => _repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    ),
  );

  Future<void> sendPasswordReset(String email) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      await _repository.sendPasswordReset(email);
      emit(state.copyWith(isSubmitting: false));
    } on AppFailure catch (failure) {
      emit(state.copyWith(isSubmitting: false, failure: failure));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      await _repository.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on AppFailure catch (failure) {
      emit(state.copyWith(isSubmitting: false, failure: failure));
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  Future<void> _submit(Future<AuthUser> Function() action) async {
    emit(state.copyWith(isSubmitting: true, clearFailure: true));
    try {
      final user = await action();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
        ),
      );
    } on AppFailure catch (failure) {
      emit(state.copyWith(isSubmitting: false, failure: failure));
    }
  }

  void _apply(AuthUser? user) {
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
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
