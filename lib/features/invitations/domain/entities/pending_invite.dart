import 'package:equatable/equatable.dart';

class PendingInvite extends Equatable {
  const PendingInvite({required this.code, required this.capturedAt});

  static const Duration defaultTtl = Duration(hours: 24);

  final String code;
  final DateTime capturedAt;

  bool isExpired(DateTime now, {Duration ttl = defaultTtl}) =>
      now.difference(capturedAt) > ttl;

  @override
  List<Object?> get props => <Object?>[code, capturedAt];
}

class InviteCode {
  const InviteCode._();

  static final RegExp _pattern = RegExp(r'^[A-Z0-9]{4,16}$');

  static String normalize(String raw) => raw.trim().toUpperCase();

  static bool isValid(String raw) => _pattern.hasMatch(normalize(raw));
}
