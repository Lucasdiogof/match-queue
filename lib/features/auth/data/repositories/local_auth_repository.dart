import 'dart:async';

import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository();

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> watchCurrentUser() => _controller.stream;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async => _emit(
    AuthUser(id: 'local-${email.hashCode}', email: email, displayName: null),
  );

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async => _emit(
    AuthUser(
      id: 'local-${email.hashCode}',
      email: email,
      displayName: displayName,
    ),
  );

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  AuthUser _emit(AuthUser user) {
    _currentUser = user;
    _controller.add(user);
    return user;
  }
}
