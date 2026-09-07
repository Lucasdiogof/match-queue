import 'package:equatable/equatable.dart';

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyRegistered,
  weakPassword,
  userNotFound,
  sessionExpired,
  unknown,
}

sealed class AppFailure extends Equatable implements Exception {
  const AppFailure({this.debugMessage});

  final String? debugMessage;

  @override
  List<Object?> get props => <Object?>[debugMessage];

  @override
  String toString() => '$runtimeType(${debugMessage ?? ''})';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({super.debugMessage});
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({super.debugMessage});
}

final class AuthFailure extends AppFailure {
  const AuthFailure({required this.reason, super.debugMessage});

  final AuthFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure({super.debugMessage});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({super.debugMessage});
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({super.debugMessage});
}

final class ServerFailure extends AppFailure {
  const ServerFailure({super.debugMessage});
}

final class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure({required this.missingKeys, super.debugMessage});

  final List<String> missingKeys;

  @override
  List<Object?> get props => <Object?>[missingKeys, debugMessage];
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({super.debugMessage});
}
