import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/public_profile/data/datasources/public_profile_remote_data_source.dart';
import 'package:fifa_queue/features/public_profile/data/models/public_profile_model.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';
import 'package:fifa_queue/features/public_profile/domain/repositories/public_profile_repository.dart';

class SupabasePublicProfileRepository implements PublicProfileRepository {
  const SupabasePublicProfileRepository(this._dataSource, this._errorMapper);

  final PublicProfileRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<PublicSharingSettings> fetchMySettings() async {
    try {
      return publicSharingSettingsFromJson(await _dataSource.getMySettings());
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<PublicSharingSettings> updateMySettings(
    PublicSharingSettings settings,
  ) async {
    try {
      return publicSharingSettingsFromJson(
        await _dataSource.updateMySettings(
          isEnabled: settings.isEnabled,
          slug: settings.slug,
          fcAccountId: settings.fcAccountId,
          showSquad: settings.showSquad,
          showWeekendLeague: settings.showWeekendLeague,
          showRivals: settings.showRivals,
          showStats: settings.showStats,
        ),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<bool> isSlugAvailable(String slug) async {
    try {
      return await _dataSource.isSlugAvailable(slug);
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }

  @override
  Future<PublicProfile> fetchPublicProfile(String identifier) async {
    try {
      return publicProfileFromJson(
        await _dataSource.getPublicProfile(identifier),
      );
    } catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
