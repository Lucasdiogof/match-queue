import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/account/data/datasources/account_remote_data_source.dart';
import 'package:fifa_queue/features/account/data/models/account_model.dart';
import 'package:fifa_queue/features/account/domain/entities/account.dart';
import 'package:fifa_queue/features/account/domain/repositories/account_repository.dart';

class SupabaseAccountRepository implements AccountRepository {
  const SupabaseAccountRepository(this._dataSource, this._errorMapper);

  final AccountRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<Account?> fetchMyProfile() => _guard(() async {
    final json = await _dataSource.fetchById(_requireUserId());
    return json == null ? null : AccountModel.fromJson(json);
  });

  @override
  Future<Account> ensureMyProfile({required String fallbackDisplayName}) =>
      _guard(() async {
        final userId = _requireUserId();
        final existing = await _dataSource.fetchById(userId);
        if (existing != null) {
          return AccountModel.fromJson(existing);
        }
        final created = await _dataSource.insert(
          userId: userId,
          displayName: _sanitize(fallbackDisplayName),
        );
        return AccountModel.fromJson(created);
      });

  @override
  Future<Account> updateDisplayName(String displayName) => _guard(() async {
    final updated = await _dataSource.updateDisplayName(
      userId: _requireUserId(),
      displayName: _sanitize(displayName),
    );
    return AccountModel.fromJson(updated);
  });

  @override
  Future<void> updateLocale(String localeTag) => _guard(
    () => _dataSource.updateLocale(
      userId: _requireUserId(),
      localeTag: localeTag,
    ),
  );

  @override
  Future<void> touchActivity() =>
      _guard(() => _dataSource.touchActivity(_requireUserId()));

  String _requireUserId() {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return userId;
  }

  String _sanitize(String displayName) {
    final normalized = AppValidators.normalizeDisplayName(displayName);
    if (normalized.isEmpty) {
      return 'Jogador';
    }
    final runes = normalized.runes.toList();
    if (runes.length <= AppValidators.displayNameMaxLength) {
      return normalized;
    }
    return String.fromCharCodes(runes.take(AppValidators.displayNameMaxLength));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
