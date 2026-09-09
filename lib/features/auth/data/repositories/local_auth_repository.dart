import 'dart:async';

import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_snapshot.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository();

  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  final Map<String, _LocalAccount> _accounts = <String, _LocalAccount>{};

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthSnapshot> watchAuthState() => _controller.stream;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final key = AppValidators.normalizeEmail(email);
    final account = _accounts[key];
    if (account != null && account.password != password) {
      throw const AuthFailure(reason: AuthFailureReason.invalidCredentials);
    }
    final user =
        account?.user ??
        AuthUser(id: _idFor(key), email: key, displayName: _nameFrom(key));
    _accounts[key] = _LocalAccount(user: user, password: password);
    return _emit(user, AuthSessionEvent.signedIn);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = AppValidators.normalizeEmail(email);
    if (_accounts.containsKey(key)) {
      throw const AuthFailure(reason: AuthFailureReason.emailAlreadyRegistered);
    }
    final user = AuthUser(
      id: _idFor(key),
      email: key,
      displayName: AppValidators.normalizeDisplayName(displayName),
    );
    _accounts[key] = _LocalAccount(user: user, password: password);
    return _emit(user, AuthSessionEvent.signedIn);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    _accounts[user.email] = _LocalAccount(user: user, password: newPassword);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(const AuthSnapshot.signedOut());
  }

  @override
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    _accounts.remove(user.email);
    _currentUser = null;
    _controller.add(const AuthSnapshot.signedOut());
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  AuthUser _emit(AuthUser user, AuthSessionEvent event) {
    _currentUser = user;
    _controller.add(AuthSnapshot(event: event, user: user));
    return user;
  }

  String _idFor(String email) =>
      'local-${email.hashCode.toUnsigned(32).toRadixString(16)}';

  String _nameFrom(String email) {
    final localPart = email.split('@').first;
    return localPart.isEmpty ? 'Jogador' : localPart;
  }
}

class _LocalAccount {
  const _LocalAccount({required this.user, required this.password});

  final AuthUser user;
  final String password;
}
