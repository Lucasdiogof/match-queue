import 'package:fifa_queue/features/auth/domain/entities/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class AuthUserModel {
  const AuthUserModel._();

  static AuthUser fromSupabase(User user) => AuthUser(
    id: user.id,
    email: user.email ?? '',
    displayName: _readString(user.userMetadata, 'display_name'),
    avatarUrl: _readString(user.userMetadata, 'avatar_url'),
  );

  static String? _readString(Map<String, dynamic>? metadata, String key) {
    final value = metadata?[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
