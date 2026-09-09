import 'package:fifa_queue/features/auth/domain/entities/auth_snapshot.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthSnapshot> watchAuthState();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  /// Apaga a conta do usuário autenticado (perfil, elencos, participação em
  /// times, dispositivos, notificações, perfil público) e o remove de
  /// `auth.users`. Irreversível.
  Future<void> deleteAccount();

  Future<void> dispose();
}
