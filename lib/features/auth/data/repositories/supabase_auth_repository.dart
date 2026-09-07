import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fifa_queue/features/auth/data/models/auth_user_model.dart';
import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._dataSource, this._errorMapper);

  final AuthRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  AuthUser? get currentUser {
    final user = _dataSource.currentUser;
    return user == null ? null : AuthUserModel.fromSupabase(user);
  }

  @override
  Stream<AuthUser?> watchCurrentUser() => _dataSource.watchCurrentUser().map(
    (user) => user == null ? null : AuthUserModel.fromSupabase(user),
  );

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () async => AuthUserModel.fromSupabase(
      await _dataSource.signInWithEmail(email: email, password: password),
    ),
  );

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(
    () async => AuthUserModel.fromSupabase(
      await _dataSource.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    ),
  );

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _dataSource.sendPasswordReset(email));

  @override
  Future<void> signOut() => _guard(_dataSource.signOut);

  @override
  Future<void> dispose() async {}

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
