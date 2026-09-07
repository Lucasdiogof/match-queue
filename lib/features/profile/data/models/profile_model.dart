import 'package:fifa_queue/features/profile/domain/entities/profile.dart';

class ProfileModel {
  const ProfileModel._();

  static const String table = 'profiles';
  static const String columnId = 'id';
  static const String columnDisplayName = 'display_name';
  static const String columnAvatarUrl = 'avatar_url';
  static const String columnLocale = 'locale';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static Profile fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json[columnCreatedAt]);
    return Profile(
      id: '${json[columnId]}',
      displayName: '${json[columnDisplayName]}',
      avatarUrl: _parseString(json[columnAvatarUrl]),
      locale: _parseString(json[columnLocale]),
      createdAt: createdAt,
      updatedAt: _parseDate(json[columnUpdatedAt], fallback: createdAt),
    );
  }

  static DateTime _parseDate(Object? value, {DateTime? fallback}) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed.toUtc();
      }
    }
    return fallback ?? DateTime.now().toUtc();
  }

  static String? _parseString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
