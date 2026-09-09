import 'package:fifa_queue/features/teams/domain/entities/team.dart';

class TeamModel {
  const TeamModel._();

  static const String table = 'teams';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnTag = 'tag';
  static const String columnLogoUrl = 'logo_url';
  static const String columnPrimaryColor = 'primary_color';
  static const String columnSecondaryColor = 'secondary_color';
  static const String columnSearchDuration = 'default_search_duration_seconds';
  static const String columnIsActive = 'is_active';
  static const String columnIsPublic = 'is_public';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static Team fromJson(Map<String, dynamic> json) {
    final createdAt = parseDate(json[columnCreatedAt]);
    return Team(
      id: '${json[columnId]}',
      name: '${json[columnName]}',
      tag: parseString(json[columnTag]),
      logoUrl: parseString(json[columnLogoUrl]),
      primaryColor: parseString(json[columnPrimaryColor]),
      secondaryColor: parseString(json[columnSecondaryColor]),
      defaultSearchDuration: Duration(
        seconds: json[columnSearchDuration] is int
            ? json[columnSearchDuration] as int
            : 180,
      ),
      isActive: json[columnIsActive] is bool
          ? json[columnIsActive] as bool
          : true,
      isPublic: json[columnIsPublic] is bool
          ? json[columnIsPublic] as bool
          : true,
      createdAt: createdAt,
      updatedAt: parseDate(json[columnUpdatedAt], fallback: createdAt),
    );
  }

  static PublicTeamSummary summaryFromJson(Map<String, dynamic> json) =>
      PublicTeamSummary(
        id: '${json['id']}',
        name: '${json['name']}',
        tag: parseString(json['tag']),
        logoUrl: parseString(json['logo_url']),
        primaryColor: parseString(json['primary_color']),
        secondaryColor: parseString(json['secondary_color']),
        memberCount: json['member_count'] is int
            ? json['member_count'] as int
            : 0,
      );

  static PublicTeam publicTeamFromJson(Map<String, dynamic> json) {
    final found = json['found'] == true;
    if (!found) {
      return const PublicTeam(found: false);
    }
    final team = Map<String, dynamic>.from(json['team'] as Map);
    final record = json['record'] is Map
        ? Map<String, dynamic>.from(json['record'] as Map)
        : null;
    final membersRaw = json['members'];
    return PublicTeam(
      found: true,
      id: '${team['id']}',
      name: '${team['name']}',
      tag: parseString(team['tag']),
      logoUrl: parseString(team['logo_url']),
      primaryColor: parseString(team['primary_color']),
      secondaryColor: parseString(team['secondary_color']),
      memberCount: team['member_count'] is int
          ? team['member_count'] as int
          : 0,
      members: <PublicTeamMember>[
        if (membersRaw is List)
          for (final entry in membersRaw)
            if (entry is Map)
              PublicTeamMember(
                displayName: '${entry['display_name']}',
                role: '${entry['role']}',
                avatarUrl: parseString(entry['avatar_url']),
                publicProfileSlug: parseString(entry['slug']),
              ),
      ],
      record: record == null
          ? null
          : PublicTeamRecord(
              wins: record['wins'] is int ? record['wins'] as int : 0,
              losses: record['losses'] is int ? record['losses'] as int : 0,
              goalsFor: record['goals_for'] is int
                  ? record['goals_for'] as int
                  : 0,
              goalsAgainst: record['goals_against'] is int
                  ? record['goals_against'] as int
                  : 0,
            ),
    );
  }

  static DateTime parseDate(Object? value, {DateTime? fallback}) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return fallback ?? DateTime.now().toUtc();
  }

  static String? parseString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
