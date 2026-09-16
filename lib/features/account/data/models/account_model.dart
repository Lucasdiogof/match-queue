import 'package:fifa_queue/features/account/domain/entities/account.dart';

class AccountModel {
  const AccountModel._();

  static const String table = 'profiles';
  static const String columnId = 'id';
  static const String columnDisplayName = 'display_name';
  static const String columnAvatarUrl = 'avatar_url';
  static const String columnLocale = 'locale';
  static const String columnLastActiveAt = 'last_active_at';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static Account fromJson(Map<String, dynamic> json) {
    final createdAt = _parseDate(json[columnCreatedAt]);
    return Account(
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
