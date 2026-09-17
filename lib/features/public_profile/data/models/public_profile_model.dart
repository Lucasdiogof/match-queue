import 'package:fifa_queue/features/account/domain/entities/account_stats.dart';
import 'package:fifa_queue/features/game/domain/entities/weekend_league_history_entry.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_profile.dart';
import 'package:fifa_queue/features/public_profile/domain/entities/public_sharing_settings.dart';

PublicSharingSettings publicSharingSettingsFromJson(
  Map<String, dynamic> json,
) => PublicSharingSettings(
  isEnabled: json['is_enabled'] as bool? ?? false,
  slug: json['slug'] as String?,
  showSquad: json['show_squad'] as bool? ?? true,
  showWeekendLeague: json['show_weekend_league'] as bool? ?? true,
  showRivals: json['show_rivals'] as bool? ?? true,
  showStats: json['show_stats'] as bool? ?? true,
);


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
          endsAt: row['ends_at'] != null
              ? DateTime.parse('${row['ends_at']}')
              : null,
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

  // 'profile' aqui e o bloco publico do usuario no payload da RPC (nome
  // exibido, avatar, divisao) -- nome de wire, nao o conceito removido.
  final user =
      json['profile'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{};
  final weekendLeague = json['weekend_league'] as Map<dynamic, dynamic>?;

  return PublicProfile(
    found: true,
    displayName: user['display_name'] as String?,
    avatarUrl: user['avatar_url'] as String?,
    rivalsDivision: user['rivals_division'] as String?,
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
