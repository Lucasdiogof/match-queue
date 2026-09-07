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
  String get comingSoonNextStage => 'Stage 3';

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
  String get errorEmailConfirmationRequired =>
      'We sent a confirmation link to your email. Confirm the address to sign in.';

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

  @override
  String get loginTitle => 'Sign in to your account';

  @override
  String get loginNoAccount => 'Don\'t have an account yet?';

  @override
  String get loginLocalModeBadge => 'Local mode';

  @override
  String get loginLocalModeMessage =>
      'No Supabase project configured. Accounts created here live on this device only.';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpSubtitle => 'Choose how your team will call you.';

  @override
  String get signUpHaveAccount => 'Already have an account?';

  @override
  String get authDisplayName => 'Name or nickname';

  @override
  String get authDisplayNameHint => 'Lucas, ratowrld, Panda...';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String authPasswordHelper(int count) {
    return 'At least $count characters';
  }

  @override
  String get forgotPasswordTitle => 'Recover access';

  @override
  String get forgotPasswordMessage =>
      'Enter your account email and we will send the link to create a new password.';

  @override
  String get forgotPasswordAction => 'Send instructions';

  @override
  String get forgotPasswordSentTitle => 'Check your email';

  @override
  String get forgotPasswordSentMessage =>
      'If there is an account for this email, you will receive the instructions to reset your password.';

  @override
  String get forgotPasswordBackToLogin => 'Back to sign in';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordMessage =>
      'Choose a new password to get back into FIFA Queue.';

  @override
  String get resetPasswordNewPassword => 'New password';

  @override
  String get resetPasswordAction => 'Save new password';

  @override
  String get resetPasswordSuccess => 'Password updated. Welcome back.';

  @override
  String get resetPasswordInvalidTitle => 'Expired or invalid link';

  @override
  String get resetPasswordInvalidMessage =>
      'Request a new recovery link to set your password.';

  @override
  String get validationEmailRequired => 'Enter your email.';

  @override
  String get validationEmailInvalid => 'Enter a valid email.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String validationPasswordTooShort(int count) {
    return 'The password needs at least $count characters.';
  }

  @override
  String get validationPasswordConfirmationRequired => 'Confirm your password.';

  @override
  String get validationPasswordConfirmationMismatch =>
      'The passwords do not match.';

  @override
  String get validationDisplayNameRequired => 'Enter a name or nickname.';

  @override
  String validationDisplayNameTooShort(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String validationDisplayNameTooLong(int count) {
    return 'Use at most $count characters.';
  }

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errorSignUpFailed => 'We could not create your account.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String get homeSearchPlaceholderTitle =>
      'Coordinated search arrives in Stage 3';

  @override
  String get homeSearchPlaceholderMessage =>
      'First we build teams and members. After that, only one player per team searches at a time.';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileDisplayNameLabel => 'Name or nickname';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileEditNameTitle => 'What should we call you?';

  @override
  String profileDisplayNameCounter(int count, int max) {
    return '$count/$max';
  }

  @override
  String get profileSaved => 'Name updated.';

  @override
  String get profileLoadErrorTitle => 'We could not load your profile';

  @override
  String profileMemberSince(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'On FIFA Queue since $dateString';
  }

  @override
  String get teamNoTeamTitle => 'You are not part of a team yet';

  @override
  String get teamNoTeamMessage =>
      'Create your team or join with an invite code to get started.';

  @override
  String get teamCreateCta => 'Create team';

  @override
  String get teamHaveInviteCode => 'I have an invite code';

  @override
  String get teamInviteComingSoonTitle => 'Invites arrive in the next stage';

  @override
  String get teamInviteComingSoonMessage =>
      'Joining by link and code is coming soon. For now, create a team to get started.';

  @override
  String get teamCreateTitle => 'Create your team';

  @override
  String get teamCreateSubtitle =>
      'You can tweak colors, logo and search duration later.';

  @override
  String get teamNameLabel => 'Team name';

  @override
  String get teamNameHint => 'Falcons FC';

  @override
  String get teamTagLabel => 'Tag (optional)';

  @override
  String get teamTagHint => 'FLC';

  @override
  String get teamTagHelper => '2 to 6 letters or digits';

  @override
  String get teamCreateAction => 'Create team';

  @override
  String get teamCreateAnother => 'Create another team';

  @override
  String get teamMembersTitle => 'Members';

  @override
  String teamMembersCount(int count) {
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
  String get teamRoleOwner => 'Owner';

  @override
  String get teamRoleAdmin => 'Admin';

  @override
  String get teamRolePlayer => 'Player';

  @override
  String get teamYou => 'You';

  @override
  String get teamManageAction => 'Team settings';

  @override
  String get teamEditTitle => 'Edit team';

  @override
  String get teamInvitePlayers => 'Invite players';

  @override
  String get teamInvitePlayersHint => 'Available in the next stage.';

  @override
  String get teamSwitchTitle => 'Your teams';

  @override
  String get teamSwitchAction => 'Switch team';

  @override
  String get teamNoActiveSearchTitle => 'No active search';

  @override
  String get teamNoActiveSearchMessage =>
      'The match queue is coming soon. This is where the team will coordinate who searches now.';

  @override
  String get teamSearchDurationLabel => 'Default search duration';

  @override
  String get teamSearchDurationHelper =>
      'How long each player stays at the front of the queue.';

  @override
  String teamDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String teamDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String get teamLoadErrorTitle => 'We could not load your teams';

  @override
  String get teamMembersErrorTitle => 'We could not load the members';

  @override
  String get validationTeamNameRequired => 'Enter the team name.';

  @override
  String validationTeamNameTooShort(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String validationTeamNameTooLong(int count) {
    return 'Use at most $count characters.';
  }

  @override
  String validationTeamTagTooShort(int count) {
    return 'The tag needs at least $count characters.';
  }

  @override
  String validationTeamTagTooLong(int count) {
    return 'The tag can have at most $count characters.';
  }

  @override
  String get validationTeamTagInvalid => 'Use letters and digits only.';

  @override
  String get errorTeamNameInvalid => 'Choose a valid team name.';

  @override
  String get errorTeamTagInvalid => 'Choose a valid tag.';

  @override
  String get errorTeamSearchDurationInvalid =>
      'Choose a valid search duration.';

  @override
  String get errorTeamNotFound => 'Team not found.';

  @override
  String get errorTeamPermissionDenied =>
      'You do not have permission to manage this team.';

  @override
  String get errorTeamProfileMissing =>
      'Finish your profile before creating a team.';
}
