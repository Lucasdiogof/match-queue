import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';

extension AppFailureL10n on AppFailure {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    TimeoutFailure() => l10n.errorTimeout,
    PermissionFailure() => l10n.errorPermission,
    NotFoundFailure() => l10n.errorNotFound,
    ConflictFailure() => l10n.errorConflict,
    ServerFailure() => l10n.errorServer,
    UnexpectedFailure() => l10n.errorUnexpected,
    ConfigurationFailure(:final missingKeys) => l10n.errorConfiguration(
      missingKeys.join(', '),
    ),
    AuthFailure(:final reason) => switch (reason) {
      AuthFailureReason.invalidCredentials => l10n.errorInvalidCredentials,
      AuthFailureReason.emailAlreadyRegistered =>
        l10n.errorEmailAlreadyRegistered,
      AuthFailureReason.weakPassword => l10n.errorWeakPassword,
      AuthFailureReason.userNotFound => l10n.errorUserNotFound,
      AuthFailureReason.sessionExpired => l10n.errorSessionExpired,
      AuthFailureReason.emailConfirmationRequired =>
        l10n.errorEmailConfirmationRequired,
      AuthFailureReason.tooManyRequests => l10n.errorTooManyRequests,
      AuthFailureReason.unknown => l10n.errorAuthUnknown,
    },
    TeamFailure(:final reason) => switch (reason) {
      TeamFailureReason.invalidName => l10n.errorTeamNameInvalid,
      TeamFailureReason.invalidTag => l10n.errorTeamTagInvalid,
      TeamFailureReason.invalidSearchDuration =>
        l10n.errorTeamSearchDurationInvalid,
      TeamFailureReason.notFound => l10n.errorTeamNotFound,
      TeamFailureReason.permissionDenied => l10n.errorTeamPermissionDenied,
      TeamFailureReason.profileMissing => l10n.errorTeamProfileMissing,
    },
    InviteFailure(:final reason) => switch (reason) {
      InviteFailureReason.notFound => l10n.errorInviteNotFound,
      InviteFailureReason.notActive => l10n.errorInviteNotActive,
      InviteFailureReason.expired => l10n.errorInviteExpired,
      InviteFailureReason.exhausted => l10n.errorInviteExhausted,
      InviteFailureReason.permissionDenied => l10n.errorInvitePermissionDenied,
    },
    MatchmakingFailure(:final reason) => switch (reason) {
      MatchmakingFailureReason.noActiveSearch =>
        l10n.errorMatchmakingNoActiveSearch,
      MatchmakingFailureReason.notCurrentSearcher =>
        l10n.errorMatchmakingNotCurrentSearcher,
      MatchmakingFailureReason.alreadyInOtherState =>
        l10n.errorMatchmakingAlreadyInOtherState,
      MatchmakingFailureReason.teamInactive =>
        l10n.errorMatchmakingTeamInactive,
    },
  };
}
