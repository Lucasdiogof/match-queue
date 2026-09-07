import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;

  Stream<User?> watchCurrentUser();

  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  Future<User> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> watchCurrentUser() =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

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
    String? displayName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: displayName == null
          ? null
          : <String, dynamic>{'display_name': displayName},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Conta não criada pelo Supabase.');
    }
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email);

  @override
  Future<void> signOut() => _auth.signOut();
}
