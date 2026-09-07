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
      createdAt: createdAt,
      updatedAt: parseDate(json[columnUpdatedAt], fallback: createdAt),
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
