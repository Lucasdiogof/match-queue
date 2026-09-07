import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  String get shortName {
    final name = displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final localPart = email.split('@').first;
    return localPart.isEmpty ? email : localPart;
  }

  @override
  List<Object?> get props => <Object?>[id, email, displayName, avatarUrl];
}
