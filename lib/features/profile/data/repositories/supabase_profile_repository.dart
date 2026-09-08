import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:fifa_queue/features/profile/data/models/profile_model.dart';
import 'package:fifa_queue/features/profile/domain/entities/profile.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._dataSource, this._errorMapper);

  final ProfileRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<Profile?> fetchMyProfile() => _guard(() async {
    final json = await _dataSource.fetchById(_requireUserId());
    return json == null ? null : ProfileModel.fromJson(json);
  });

  @override
  Future<Profile> ensureMyProfile({required String fallbackDisplayName}) =>
      _guard(() async {
        final userId = _requireUserId();
        final existing = await _dataSource.fetchById(userId);
        if (existing != null) {
          return ProfileModel.fromJson(existing);
        }
        final created = await _dataSource.insert(
          userId: userId,
          displayName: _sanitize(fallbackDisplayName),
        );
        return ProfileModel.fromJson(created);
      });

  @override
  Future<Profile> updateDisplayName(String displayName) => _guard(() async {
    final updated = await _dataSource.updateDisplayName(
      userId: _requireUserId(),
      displayName: _sanitize(displayName),
    );
    return ProfileModel.fromJson(updated);
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
