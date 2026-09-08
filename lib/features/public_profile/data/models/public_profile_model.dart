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

PublicProfile publicProfileFromJson(Map<String, dynamic> json) {
  if (json['found'] != true) {
    return PublicProfile.notFound;
  }

  final profile =
      json['profile'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{};
  final account = json['account'] as Map<dynamic, dynamic>?;

  return PublicProfile(
    found: true,
    displayName: profile['display_name'] as String?,
    avatarUrl: profile['avatar_url'] as String?,
    accountName: account?['name'] as String?,
    rivalsDivision: account?['rivals_division'] as String?,
    stats: _aggregateFromJson(json['stats']),
    weekendLeague: _aggregateFromJson(
      (json['weekend_league'] as Map<dynamic, dynamic>?)?['computed'],
    ),
    rivals: _aggregateFromJson(
      (json['rivals'] as Map<dynamic, dynamic>?)?['aggregate'],
    ),
    squad: _squadFromJson(json['squad']),
  );
}
