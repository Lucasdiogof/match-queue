import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/profile/domain/entities/profile.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._authRepository);

  final AuthRepository _authRepository;
  final Map<String, Profile> _profiles = <String, Profile>{};

  @override
  Future<Profile?> fetchMyProfile() async => _profiles[_requireUserId()];

  @override
  Future<Profile> ensureMyProfile({required String fallbackDisplayName}) async {
    final userId = _requireUserId();
    return _profiles[userId] ??= _create(userId, fallbackDisplayName);
  }

  @override
  Future<Profile> updateDisplayName(String displayName) async {
    final userId = _requireUserId();
    final existing = _profiles[userId] ?? _create(userId, displayName);
    final updated = existing.copyWith(
      displayName: AppValidators.normalizeDisplayName(displayName),
    );
    _profiles[userId] = updated;
    return updated;
  }

  Profile _create(String userId, String displayName) {
    final now = DateTime.now().toUtc();
    return Profile(
      id: userId,
      displayName: AppValidators.normalizeDisplayName(displayName),
      createdAt: now,
      updatedAt: now,
    );
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const AuthFailure(reason: AuthFailureReason.sessionExpired);
    }
    return user.id;
  }
}
