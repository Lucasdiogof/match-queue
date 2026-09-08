import 'package:equatable/equatable.dart';

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyRegistered,
  weakPassword,
  userNotFound,
  sessionExpired,
  emailConfirmationRequired,
  tooManyRequests,
  unknown,
}

enum TeamFailureReason {
  invalidName,
  invalidTag,
  invalidSearchDuration,
  notFound,
  permissionDenied,
  profileMissing,
}

enum InviteFailureReason {
  notFound,
  notActive,
  expired,
  exhausted,
  generationFailed,
  permissionDenied,
}

enum MatchmakingFailureReason {
  noActiveSearch,
  notCurrentSearcher,
  alreadyInOtherState,
  teamInactive,
}

enum GameFailureReason {
  cooldown,
  matchNotFound,
  matchAlreadyFinished,
  invalidMode,
  invalidResult,
  invalidStatsPayload,
  playerNotInSquad,
  noSquadSnapshot,
  matchNotFinished,
}

enum FcAccountFailureReason {
  accountNotFound,
  accountNotLinkedToTeam,
  accountNotLinkedToAnyTeam,
  invalidName,
  invalidDivision,
}

enum SquadFailureReason {
  notFound,
  invalidName,
  invalidFormation,
  invalidSlot,
  cardCannotPlayPosition,
  inUseByActiveSearch,
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

final class TeamFailure extends AppFailure {
  const TeamFailure({required this.reason, super.debugMessage});

  final TeamFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class InviteFailure extends AppFailure {
  const InviteFailure({required this.reason, super.debugMessage});

  final InviteFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class MatchmakingFailure extends AppFailure {
  const MatchmakingFailure({required this.reason, super.debugMessage});

  final MatchmakingFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class GameFailure extends AppFailure {
  const GameFailure({required this.reason, super.debugMessage});

  final GameFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class FcAccountFailure extends AppFailure {
  const FcAccountFailure({required this.reason, super.debugMessage});

  final FcAccountFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason, debugMessage];
}

final class SquadFailure extends AppFailure {
  const SquadFailure({required this.reason, super.debugMessage});

  final SquadFailureReason reason;

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
