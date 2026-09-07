// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FIFA Queue';

  @override
  String get appTagline => 'One at a time in the queue.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSave => 'Save';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get navSearch => 'Search';

  @override
  String get navTeam => 'Team';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get comingSoonTitle => 'Under construction';

  @override
  String get comingSoonMessage =>
      'This area will be built in the upcoming stages of the project.';

  @override
  String comingSoonStage(String stage) {
    return 'Planned for $stage';
  }

  @override
  String get homeTitle => 'Find a match';

  @override
  String get homeSubtitle => 'Coordinate who is searching right now.';

  @override
  String get teamTitle => 'My team';

  @override
  String get teamSubtitle => 'Players, roles and invites.';

  @override
  String get historyTitle => 'History';

  @override
  String get historySubtitle => 'Searches, matches found and expirations.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Account, appearance and language.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Create account';

  @override
  String get authForgotPassword => 'Forgot my password';

  @override
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authRevealPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authWelcomeTitle => 'Sign in to coordinate your team';

  @override
  String get authWelcomeMessage =>
      'The authentication screens will be built in the next stage. The auth architecture is already in place.';

  @override
  String get authLocalModeTitle => 'Local development mode';

  @override
  String get authLocalModeMessage =>
      'No Supabase project is configured. You can sign in with a local session to browse the app structure.';

  @override
  String get authLocalModeAction => 'Sign in locally';

  @override
  String authSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languagePortuguese => 'Portuguese (Brazil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get inviteTitle => 'You were invited to';

  @override
  String get inviteJoinTeam => 'Join team';

  @override
  String inviteCodeLabel(String code) {
    return 'Invite code: $code';
  }

  @override
  String get inviteSignInRequiredTitle => 'Sign in to accept the invite';

  @override
  String get inviteSignInRequiredMessage =>
      'We saved this invite. As soon as you sign in it will resume automatically.';

  @override
  String get invitePendingRestored => 'Pending invite restored.';

  @override
  String get inviteResolutionComingSoon =>
      'Joining a team will be implemented in the next stage.';

  @override
  String invitePlayersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
      zero: 'No players',
    );
    return '$_temp0';
  }

  @override
  String inviteReceivedAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Invite received on $dateString';
  }

  @override
  String queuePositionLabel(int position) {
    final intl.NumberFormat positionNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String positionString = positionNumberFormat.format(position);

    return '#$positionString in queue';
  }

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorTimeout => 'The operation took too long. Try again.';

  @override
  String get errorServer =>
      'Something went wrong on the server. Try again shortly.';

  @override
  String get errorPermission => 'You do not have permission to do that.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorConflict =>
      'This action conflicts with the current state. Refresh and try again.';

  @override
  String get errorUnexpected => 'Unexpected error. Try again.';

  @override
  String errorConfiguration(String keys) {
    return 'Missing configuration: $keys';
  }

  @override
  String get errorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorEmailAlreadyRegistered => 'This email is already registered.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorUserNotFound => 'Account not found.';

  @override
  String get errorSessionExpired =>
      'Your session expired. Please sign in again.';

  @override
  String get errorAuthUnknown => 'We could not complete the authentication.';

  @override
  String get startupErrorTitle => 'FIFA Queue could not start';

  @override
  String startupErrorMessage(String keys) {
    return 'Required environment variables are missing: $keys';
  }

  @override
  String environmentBadge(String environment) {
    return 'Environment: $environment';
  }

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage =>
      'The address you opened does not exist in this app.';

  @override
  String get notFoundAction => 'Go to start';
}
