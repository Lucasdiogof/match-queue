import 'package:fifa_queue/core/config/app_config.dart';
import 'package:fifa_queue/core/config/auth_redirects.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;

  Stream<AuthState> watchAuthState();

  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._client, this._config);

  static const String displayNameMetadataKey = 'display_name';

  final SupabaseClient _client;
  final AppConfig _config;

  GoTrueClient get _auth => _client.auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<AuthState> watchAuthState() => _auth.onAuthStateChange;

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sessão não retornada pelo Supabase.');
    }
    return user;
  }

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{displayNameMetadataKey: displayName},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Conta não criada pelo Supabase.');
    }
    if (response.session == null) {
      throw const AuthFailure(
        reason: AuthFailureReason.emailConfirmationRequired,
      );
    }
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.resetPasswordForEmail(
    email,
    redirectTo: AuthRedirects.passwordReset(
      isWeb: kIsWeb,
      currentUri: Uri.base,
      appLinkHost: _config.appLinkHost,
    ),
  );

  @override
  Future<void> updatePassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword));

  @override
  Future<void> signOut() => _auth.signOut();
}
