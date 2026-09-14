import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_history_entry.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';

PublicSharingSettings publicSharingSettingsFromJson(
  Map<String, dynamic> json,
) => PublicSharingSettings(
  isEnabled: json['is_enabled'] as bool? ?? false,
  slug: json['slug'] as String?,
  fcAccountId: json['fc_account_id'] as String?,
  showSquad: json['show_squad'] as bool? ?? false,
  showWeekendLeague: json['show_weekend_league'] as bool? ?? false,
  showRivals: json['show_rivals'] as bool? ?? false,
  showStats: json['show_stats'] as bool? ?? false,
);

PublicMatchAggregate? _aggregateFromJson(Object? json) {
  if (json is! Map) {
    return null;
  }
  final map = Map<String, dynamic>.from(json);
  return PublicMatchAggregate(
    matchesCount: (map['matches_count'] as num?)?.toInt() ?? 0,
    wins: (map['wins'] as num?)?.toInt() ?? 0,
    losses: (map['losses'] as num?)?.toInt() ?? 0,
    goalsFor: (map['goals_for'] as num?)?.toInt() ?? 0,
    goalsAgainst: (map['goals_against'] as num?)?.toInt() ?? 0,
    goalDiff: (map['goal_diff'] as num?)?.toInt() ?? 0,
  );
}

PublicSquadStarter _starterFromJson(Map<String, dynamic> json) =>
    PublicSquadStarter(
      slotCode: '${json['slot_code']}',
      playerName: '${json['player_name']}',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      position: '${json['position']}',
      chemistry: (json['chemistry'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String?,
      cardType: json['card_type'] as String?,
    );

PublicSquad? _squadFromJson(Object? json) {
  if (json is! Map) {
    return null;
  }
  final map = Map<String, dynamic>.from(json);
  final starters = (map['starters'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<dynamic, dynamic>>()
      .map((raw) => _starterFromJson(Map<String, dynamic>.from(raw)))
      .toList();
  return PublicSquad(
    name: '${map['name']}',
    formationCode: '${map['formation_code']}',
    formationDisplayName: '${map['formation_display_name']}',
    overall: (map['overall'] as num?)?.toInt(),
    chemistry: (map['chemistry'] as num?)?.toInt() ?? 0,
    chemistryRuleVersion: map['chemistry_rule_version'] as String?,
    starters: starters,
  );
}

List<WeekendLeagueHistoryEntry> _weekendLeagueHistoryFromJson(Object? json) {
  final list = (json as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<dynamic, dynamic>>()
      .map((raw) => Map<String, dynamic>.from(raw))
      .toList();
  return list
      .map(
        (row) => WeekendLeagueHistoryEntry(
          eventId: '${row['event_id']}',
          number: (row['number'] as num?)?.toInt() ?? 0,
          season: row['season'] as String?,
          startsAt: DateTime.parse('${row['starts_at']}'),
          wins: (row['wins'] as num?)?.toInt() ?? 0,
          losses: (row['losses'] as num?)?.toInt() ?? 0,
        ),
      )
      .toList(growable: false);
}

PublicProfile publicProfileFromJson(Map<String, dynamic> json) {
  if (json['found'] != true) {
    return PublicProfile.notFound;
  }

  final profile =
      json['profile'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{};
  final account = json['account'] as Map<dynamic, dynamic>?;
  final weekendLeague = json['weekend_league'] as Map<dynamic, dynamic>?;

  return PublicProfile(
    found: true,
    displayName: profile['display_name'] as String?,
    avatarUrl: profile['avatar_url'] as String?,
    accountName: account?['name'] as String?,
    rivalsDivision: account?['rivals_division'] as String?,
    stats: _aggregateFromJson(json['stats']),
    weekendLeague: ManualRecord.fromJson(weekendLeague?['manual']),
    weekendLeagueHistory: _weekendLeagueHistoryFromJson(
      weekendLeague?['history'],
    ),
    rivals: ManualRecord.fromJson(
      (json['rivals'] as Map<dynamic, dynamic>?)?['manual'],
    ),
    squad: _squadFromJson(json['squad']),
  );
}
