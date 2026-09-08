import 'package:fifa_queue/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchMyProfile();

  Future<Profile> ensureMyProfile({required String fallbackDisplayName});

  Future<Profile> updateDisplayName(String displayName);

  /// Escrita pura de `profiles.locale`, usada só para o worker de push saber
  /// em que idioma redigir a notificação. Nunca é lida de volta pelo app: a
  /// fonte da verdade do idioma na UI é a preferência local (LocaleCubit).
  Future<void> updateLocale(String localeTag);
}
