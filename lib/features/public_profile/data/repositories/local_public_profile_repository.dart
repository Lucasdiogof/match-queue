import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/auth/domain/repositories/auth_repository.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sem backend real nao ha ninguem para visitar o link de outro device --
/// so guarda a propria configuracao localmente e nunca resolve um perfil
/// alheio (sempre `PublicProfile.notFound`).
class LocalPublicProfileRepository implements PublicProfileRepository {
  LocalPublicProfileRepository(this._authRepository, this._preferences);

  final AuthRepository _authRepository;
  final SharedPreferences _preferences;

  static const String _enabledKey = 'public_profile.local.enabled.';
  static const String _slugKey = 'public_profile.local.slug.';
  static const String _accountKey = 'public_profile.local.account.';
  static const String _squadKey = 'public_profile.local.show_squad.';
  static const String _wlKey = 'public_profile.local.show_wl.';
  static const String _rivalsKey = 'public_profile.local.show_rivals.';
  static const String _statsKey = 'public_profile.local.show_stats.';

  @override
  Future<PublicSharingSettings> fetchMySettings() async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      return PublicSharingSettings.empty;
    }
    return PublicSharingSettings(
      isEnabled: _preferences.getBool('$_enabledKey$userId') ?? false,
      slug: _preferences.getString('$_slugKey$userId'),
      fcAccountId: _preferences.getString('$_accountKey$userId'),
      showSquad: _preferences.getBool('$_squadKey$userId') ?? false,
      showWeekendLeague: _preferences.getBool('$_wlKey$userId') ?? false,
      showRivals: _preferences.getBool('$_rivalsKey$userId') ?? false,
      showStats: _preferences.getBool('$_statsKey$userId') ?? false,
    );
  }

  @override
  Future<PublicSharingSettings> updateMySettings(
    PublicSharingSettings settings,
  ) async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      throw const PublicProfileFailure(
        reason: PublicProfileFailureReason.slugRequired,
      );
    }
    if (settings.isEnabled && (settings.slug ?? '').isEmpty) {
      throw const PublicProfileFailure(
        reason: PublicProfileFailureReason.slugRequired,
      );
    }
    await _preferences.setBool('$_enabledKey$userId', settings.isEnabled);
    if (settings.slug != null) {
      await _preferences.setString('$_slugKey$userId', settings.slug!);
    }
    if (settings.fcAccountId != null) {
      await _preferences.setString(
        '$_accountKey$userId',
        settings.fcAccountId!,
      );
    } else {
      await _preferences.remove('$_accountKey$userId');
    }
    await _preferences.setBool('$_squadKey$userId', settings.showSquad);
    await _preferences.setBool('$_wlKey$userId', settings.showWeekendLeague);
    await _preferences.setBool('$_rivalsKey$userId', settings.showRivals);
    await _preferences.setBool('$_statsKey$userId', settings.showStats);
    return fetchMySettings();
  }

  @override
  Future<bool> isSlugAvailable(String slug) async => true;

  @override
  Future<PublicProfile> fetchPublicProfile(String identifier) async =>
      PublicProfile.notFound;
}
