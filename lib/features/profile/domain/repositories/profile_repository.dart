import 'package:fifa_queue/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetchMyProfile();

  Future<Profile> ensureMyProfile({required String fallbackDisplayName});

  Future<Profile> updateDisplayName(String displayName);
}
