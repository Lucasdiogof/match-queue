import 'dart:typed_data';

import 'package:fifa_queue/core/supabase/supabase_error_mapper.dart';
import 'package:fifa_queue/features/profiles/data/datasources/profile_remote_data_source.dart';
import 'package:fifa_queue/features/profiles/data/models/profile_model.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_platform.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_stats.dart';
import 'package:fifa_queue/features/profiles/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/profiles/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/game/data/models/weekend_league_event_model.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._dataSource, this._errorMapper);

  final ProfileRemoteDataSource _dataSource;
  final SupabaseErrorMapper _errorMapper;

  @override
  Future<ProfilesSnapshot> fetchMyProfiles() => _guard(() async {
    final json = await _dataSource.listMyProfiles();
    return ProfileModel.snapshotFromResponse(json);
  });

  @override
  Future<String> createProfile(String name) =>
      _guard(() => _dataSource.createProfile(name));

  @override
  Future<void> updateProfile({required String id, required String name}) =>
      _guard(() => _dataSource.updateProfile(id: id, name: name));

  @override
  Future<void> updatePlatform({
    required String id,
    ProfilePlatform? platform,
  }) =>
      _guard(() => _dataSource.updatePlatform(id: id, platform: platform?.key));

  @override
  Future<String> uploadAndSetAvatar({
    required String profileId,
    required Uint8List bytes,
    required String contentType,
  }) => _guard(() async {
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final url = await _dataSource.uploadAvatar(
      profileId: profileId,
      bytes: bytes,
      contentType: contentType,
      extension: extension,
    );
    await _dataSource.updateAvatarUrl(id: profileId, avatarUrl: url);
    return url;
  });

  @override
  Future<void> removeAvatar(String profileId) => _guard(() async {
    await _dataSource.deleteAvatarFile(profileId);
    await _dataSource.updateAvatarUrl(id: profileId);
  });

  @override
  Future<void> archiveProfile(String id) =>
      _guard(() => _dataSource.archiveProfile(id));

  @override
  Future<void> updateRivalsDivision({
    required String id,
    RivalsDivision? division,
  }) => _guard(
    () => _dataSource.updateRivalsDivision(id: id, division: division?.key),
  );

  @override
  Future<void> linkToTeam({
    required String profileId,
    required String teamId,
  }) => _guard(
    () => _dataSource.linkToTeam(profileId: profileId, teamId: teamId),
  );

  @override
  Future<void> unlinkFromTeam({
    required String profileId,
    required String teamId,
  }) => _guard(
    () => _dataSource.unlinkFromTeam(profileId: profileId, teamId: teamId),
  );

  @override
  Future<void> setWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
    required int wins,
    required int losses,
  }) => _guard(
    () => _dataSource.setWeekendLeagueManualRecord(
      profileId: profileId,
      eventId: eventId,
      wins: wins,
      losses: losses,
    ),
  );

  @override
  Future<void> clearWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
  }) => _guard(
    () => _dataSource.clearWeekendLeagueManualRecord(
      profileId: profileId,
      eventId: eventId,
    ),
  );

  @override
  Future<void> incrementWeekendLeagueManualRecord({
    required String profileId,
    required String eventId,
    int winDelta = 0,
    int lossDelta = 0,
  }) => _guard(
    () => _dataSource.incrementWeekendLeagueManualRecord(
      profileId: profileId,
      eventId: eventId,
      winDelta: winDelta,
      lossDelta: lossDelta,
    ),
  );

  @override
  Future<void> incrementRivalsManualRecord({
    required String profileId,
    int winDelta = 0,
    int lossDelta = 0,
  }) => _guard(
    () => _dataSource.incrementRivalsManualRecord(
      profileId: profileId,
      winDelta: winDelta,
      lossDelta: lossDelta,
    ),
  );

  @override
  Future<ProfileStats> fetchProfileStats(String profileId) => _guard(() async {
    final json = await _dataSource.getProfileStats(profileId);
    return ProfileStats.fromJson(json);
  });

  @override
  Future<List<WeekendLeagueEvent>> fetchWeekendLeagueEvents() =>
      _guard(() async {
        final rows = await _dataSource.listWeekendLeagueEvents();
        return <WeekendLeagueEvent>[
          for (final row in rows) ?WeekendLeagueEventModel.fromResponse(row),
        ];
      });

  @override
  Future<WeekendLeagueProfileStats> fetchWeekendLeagueProfileStats({
    required String profileId,
    required String eventId,
  }) => _guard(() async {
    final json = await _dataSource.getWeekendLeagueProfileStats(
      profileId: profileId,
      eventId: eventId,
    );
    return WeekendLeagueProfileStats.fromJson(json);
  });

  @override
  Future<RivalsProfileStats> fetchRivalsProfileStats(String profileId) =>
      _guard(() async {
        final json = await _dataSource.getRivalsProfileStats(profileId);
        return RivalsProfileStats.fromJson(json);
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error) {
      throw _errorMapper.map(error);
    }
  }
}
