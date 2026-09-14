import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';

abstract interface class PublicProfileRepository {
  Future<PublicSharingSettings> fetchMySettings(String fcAccountId);

  Future<PublicSharingSettings> updateMySettings(
    PublicSharingSettings settings,
  );

  Future<bool> isSlugAvailable(String slug, {String? fcAccountId});

  /// Sem depender de sessao -- funciona igual autenticado ou anonimo.
  Future<PublicProfile> fetchPublicProfile(String identifier);
}
