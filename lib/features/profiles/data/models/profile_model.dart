import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile_platform.dart';
import 'package:fifa_queue/features/profiles/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/profiles/domain/repositories/profile_repository.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_event.dart';

class ProfileModel {
  const ProfileModel._();

  static ProfilesSnapshot snapshotFromResponse(Map<String, dynamic> json) {
    final rawProfiles = json['accounts'];
    final profiles = <Profile>[
      if (rawProfiles is List)
        for (final item in rawProfiles)
          if (item is Map) _fromJson(Map<String, dynamic>.from(item)),
    ];
    return ProfilesSnapshot(
      profiles: profiles,
      weekendLeagueEvent: _eventFromJson(json['weekend_league_event']),
    );
  }

  static Profile _fromJson(Map<String, dynamic> json) {
    final manual = json['weekend_league_manual'];
    final manualWins = manual is Map ? manual['wins'] as int? : null;
    final manualLosses = manual is Map ? manual['losses'] as int? : null;
    final rivalsManual = json['rivals_manual'];
    final teamIds = json['team_ids'];
    return Profile(
      id: '${json['id']}',
      name: '${json['name']}',
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      teamIds: teamIds is List
          ? teamIds.map((id) => '$id').toList(growable: false)
          : const <String>[],
      rivalsDivision: RivalsDivision.tryFromKey(json['rivals_division']),
      platform: ProfilePlatform.tryFromKey(json['platform']),
      weekendLeagueComputedWins:
          json['weekend_league_computed_wins'] as int? ?? 0,
      weekendLeagueComputedLosses:
          json['weekend_league_computed_losses'] as int? ?? 0,
      weekendLeagueManualWins: manualWins,
      weekendLeagueManualLosses: manualLosses,
      rivalsWins: rivalsManual is Map ? rivalsManual['wins'] as int? ?? 0 : 0,
      rivalsLosses: rivalsManual is Map
          ? rivalsManual['losses'] as int? ?? 0
          : 0,
    );
  }

  static WeekendLeagueEvent? _eventFromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(json);
    final id = m['id'];
    if (id == null) {
      return null;
    }
    return WeekendLeagueEvent(
      id: '$id',
      number: m['number'] is int ? m['number'] as int : 0,
      startsAt: DateTime.parse('${m['starts_at']}'),
      endsAt: DateTime.parse('${m['ends_at']}'),
    );
  }
}
