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
  String get actionCopy => 'Copy';

  @override
  String get actionShare => 'Share';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionEdit => 'Edit';

  @override
  String get navSearch => 'Play';

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
  String get profilePreferencesTitle => 'Preferences';

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
  String get inviteJoinTeam => 'Join team';

  @override
  String get inviteOpenTeam => 'Open team';

  @override
  String get inviteJoinMessage => 'You were invited to join this team.';

  @override
  String get inviteAlreadyMemberMessage => 'You are already part of this team.';

  @override
  String get inviteSignInToAccept => 'Sign in to accept';

  @override
  String get inviteCreateAccount => 'Create account';

  @override
  String get inviteInvalidTitle => 'Invite not found';

  @override
  String get inviteRevokedTitle => 'This link is no longer active';

  @override
  String get inviteExpiredTitle => 'This link has expired';

  @override
  String get inviteExhaustedTitle => 'This link reached its usage limit';

  @override
  String get inviteEnterCodeMessage => 'Paste or type the code you received.';

  @override
  String get inviteCodeFieldLabel => 'Invite code';

  @override
  String get inviteCodeFieldInvalid => 'Invalid code.';

  @override
  String get inviteSectionTitle => 'Invite players';

  @override
  String get inviteSectionSubtitle =>
      'Share this link with whoever you want to add to the team.';

  @override
  String get inviteLinkCopied => 'Link copied.';

  @override
  String get inviteShareSubject => 'Team invite on FIFA Queue';

  @override
  String inviteShareMessage(String url) {
    return 'Join my team on FIFA Queue: $url';
  }

  @override
  String inviteShareMessageCodeOnly(String code) {
    return 'Join my team on FIFA Queue with the code: $code';
  }

  @override
  String get inviteManageTitle => 'Manage link';

  @override
  String get inviteCreateLinkAction => 'Create invite link';

  @override
  String get inviteUnavailableMessage =>
      'This team\'s invite link is not available yet.';

  @override
  String get inviteRotateAction => 'Generate new link';

  @override
  String get inviteRotateConfirmTitle => 'Generate a new link?';

  @override
  String get inviteRotateConfirmMessage =>
      'The current link will stop working immediately.';

  @override
  String get inviteRevokeAction => 'Disable link';

  @override
  String get inviteRevokeConfirmTitle => 'Disable link?';

  @override
  String get inviteRevokeConfirmMessage =>
      'No one will be able to join the team using the current link.';

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
  String get forgotPasswordResend => 'Resend';

  @override
  String get forgotPasswordNotReceived => 'Didn\'t get the email?';

  @override
  String get forgotPasswordResending => 'Resending...';

  @override
  String get forgotPasswordResendSuccess => 'Email resent.';

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
  String get teamSwitchTitle => 'Your teams';

  @override
  String get teamSwitchAction => 'Switch team';

  @override
  String teamActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '1 active',
      zero: '0 active',
    );
    return '$_temp0';
  }

  @override
  String get teamSettingsInfoTitle => 'Info';

  @override
  String get teamSearchDurationLabel => 'Default search duration';

  @override
  String get teamSearchDurationHelper =>
      'How long each player stays at the front of the queue.';

  @override
  String get teamSearchDurationReadOnlyHelper =>
      'Only the owner or an admin can change this.';

  @override
  String get teamStatusInMatch => 'In a match';

  @override
  String get teamStatusSearching => 'Searching';

  @override
  String get teamStatusQueued => 'In queue';

  @override
  String teamStatusQueuedWithPosition(int position) {
    return 'In queue · #$position';
  }

  @override
  String get teamStatusOffline => 'Offline';

  @override
  String get teamStatusActiveNow => 'Active now';

  @override
  String teamStatusActiveMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

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

  @override
  String get errorInviteNotFound => 'Invite not found.';

  @override
  String get errorInviteNotActive => 'This invite is no longer valid.';

  @override
  String get errorInviteExpired => 'This invite has expired.';

  @override
  String get errorInviteExhausted => 'This invite reached its usage limit.';

  @override
  String get errorInviteGenerationFailed =>
      'We could not generate the invite link. Please try again.';

  @override
  String get errorInvitePermissionDenied =>
      'You do not have permission to manage this team\'s invite.';

  @override
  String get errorMatchmakingNoActiveSearch =>
      'There is no active search right now.';

  @override
  String get errorMatchmakingNotCurrentSearcher =>
      'You are no longer the one searching for a match.';

  @override
  String get errorMatchmakingAlreadyInOtherState =>
      'You are already in another queue state.';

  @override
  String get errorMatchmakingTeamInactive => 'This team is currently inactive.';

  @override
  String get errorGameCooldown => 'Wait a bit before searching again.';

  @override
  String get errorGameMatchNotFound => 'Match not found.';

  @override
  String get errorGameMatchAlreadyFinished =>
      'This match has already been finished.';

  @override
  String get errorGameInvalidMode => 'Invalid game mode.';

  @override
  String get errorGameInvalidResult =>
      'Enter a result or a score with no draw.';

  @override
  String get matchmakingIdleTitle => 'No one is searching for a match';

  @override
  String get matchmakingIdleMessage =>
      'Tap search for a match to start. The whole team sees it as soon as someone joins the queue.';

  @override
  String get matchmakingSearchAction => 'Search for a match';

  @override
  String get matchmakingJoinQueueAction => 'Join the queue';

  @override
  String get matchmakingCancelAction => 'Cancel';

  @override
  String get matchmakingLeaveQueueAction => 'Leave the queue';

  @override
  String get matchmakingMatchFoundAction => 'Found it';

  @override
  String get matchmakingSearchingSelfTitle => 'Searching for a match';

  @override
  String get matchmakingSearchingSelfMessage =>
      'As soon as the match starts, tap match found.';

  @override
  String matchmakingSearchingOtherTitle(String name) {
    return '$name is searching for a match';
  }

  @override
  String matchmakingQueuePositionLabel(int position) {
    return 'Position $position in the queue';
  }

  @override
  String get matchmakingQueueSectionTitle => 'Waiting queue';

  @override
  String get matchmakingQueueEmptyMessage => 'No one in the queue.';

  @override
  String get matchmakingYouBadge => 'You';

  @override
  String get matchmakingCancelConfirmTitle => 'Cancel search?';

  @override
  String get matchmakingCancelConfirmMessage =>
      'You will lose your spot in the current search.';

  @override
  String get matchmakingYourTurnTitle => 'Your turn to search!';

  @override
  String get matchmakingReconnecting => 'Reconnecting…';

  @override
  String get notificationsSectionTitle => 'Notifications';

  @override
  String get notificationsToggleYourTurn => 'Your turn to search';

  @override
  String get notificationsToggleYourTurnHint =>
      'When it becomes your turn in the team queue.';

  @override
  String get notificationsToggleExpiring => '30 seconds left';

  @override
  String get notificationsToggleExpiringHint =>
      'A heads-up before your search expires.';

  @override
  String get notificationsToggleExpired => 'Search time ended';

  @override
  String get notificationsToggleExpiredHint =>
      'When your search ends without a match.';

  @override
  String get notificationsEnableCta => 'Enable notifications';

  @override
  String get notificationsPermissionDeniedHint =>
      'Notifications are blocked. Turn them on in your system settings.';

  @override
  String get notificationsUnsupportedHint =>
      'This device does not receive push notifications yet.';

  @override
  String get notificationsEnableTitle => 'Don\'t miss your turn';

  @override
  String get notificationsEnableMessage =>
      'Turn on notifications to know the moment it\'s your turn to search — even with the app closed.';

  @override
  String get notificationsChannelQueueAlertsName => 'Queue alerts';

  @override
  String get notificationsChannelQueueAlertsDescription =>
      'Alerts about your turn to search and how your search is going.';

  @override
  String get historyTabMatches => 'Matches';

  @override
  String get historyTabStats => 'Statistics';

  @override
  String get historyPeriodAll => 'All time';

  @override
  String get historyPeriod7 => '7 days';

  @override
  String get historyPeriod30 => '30 days';

  @override
  String get historyPeriod90 => '90 days';

  @override
  String get historyStatusAll => 'All';

  @override
  String get historyStatusMatchFound => 'Found';

  @override
  String get historyStatusCancelled => 'Cancelled';

  @override
  String get historyStatusExpired => 'Expired';

  @override
  String get historyStatusMatchFoundLabel => 'Match found';

  @override
  String get historyStatusCancelledLabel => 'Cancelled';

  @override
  String get historyStatusExpiredLabel => 'Expired';

  @override
  String get historyEmptyTitle => 'No searches yet';

  @override
  String get historyEmptyMessage =>
      'The team\'s match searches show up here once they finish.';

  @override
  String get activityScopeAll => 'All';

  @override
  String get activityScopeGames => 'Matches';

  @override
  String get activityScopeSearches => 'Searches';

  @override
  String get activityNoResult => 'No result recorded';

  @override
  String get activityDetailMode => 'Mode';

  @override
  String get activityDetailDuration => 'Duration';

  @override
  String get activityDetailScore => 'Score';

  @override
  String get activityDetailResult => 'Result';

  @override
  String get activityDetailStatus => 'Status';

  @override
  String get activityDetailFcAccount => 'Account';

  @override
  String get historyLoadErrorTitle => 'We could not load the history';

  @override
  String get historyLoadMore => 'Load more';

  @override
  String historyEntryDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String historyEntryTime(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String get statsTotalSearches => 'Searches';

  @override
  String get statsMatchFound => 'Found';

  @override
  String get statsCancelled => 'Cancelled';

  @override
  String get statsExpired => 'Expired';

  @override
  String get statsSuccessRate => 'Success rate';

  @override
  String get statsAvgDuration => 'Avg. duration';

  @override
  String get statsPlayersTitle => 'By player';

  @override
  String get statsEmptyTitle => 'No data for this period';

  @override
  String get statsEmptyMessage =>
      'Once the team searches for matches, statistics show up here.';

  @override
  String get statsLoadErrorTitle => 'We could not load the statistics';

  @override
  String statsPlayerSearches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count searches',
      one: '1 search',
    );
    return '$_temp0';
  }

  @override
  String get gameModeWeekendLeague => 'Weekend League';

  @override
  String get gameModeDivisionRivals => 'Division Rivals';

  @override
  String get pendingMatchTitle => 'You have a match without a result';

  @override
  String get pendingMatchWinAction => 'Win';

  @override
  String get pendingMatchLossAction => 'Loss';

  @override
  String get pendingMatchAddScoreAction => 'Add score';

  @override
  String get finishMatchSheetTitle => 'Match result';

  @override
  String get finishMatchSheetMessage => 'Enter your match\'s score.';

  @override
  String get finishMatchGoalsForLabel => 'Your goals';

  @override
  String get finishMatchGoalsAgainstLabel => 'Opponent\'s goals';

  @override
  String get finishMatchGoalsRequired => 'Enter a valid number.';

  @override
  String get finishMatchDrawError => 'A draw is not a valid final result.';

  @override
  String get finishMatchSubmitAction => 'Save result';

  @override
  String weekendLeagueBadge(int number) {
    return 'Weekend League #$number';
  }

  @override
  String weekendLeagueWindow(String start, String end) {
    return '$start – $end';
  }

  @override
  String get weekendLeagueActiveBadge => 'Live now';

  @override
  String get errorFcAccountNotFound => 'Account not found.';

  @override
  String get errorFcAccountNotLinkedToTeam =>
      'This account isn\'t linked to this team.';

  @override
  String get errorFcAccountInvalidName =>
      'Enter a name from 2 to 40 characters.';

  @override
  String get errorFcAccountInvalidDivision => 'Invalid division.';

  @override
  String get validationFcAccountNameRequired => 'Enter a name for the account.';

  @override
  String validationFcAccountNameTooShort(int min) {
    return 'The name must be at least $min characters.';
  }

  @override
  String validationFcAccountNameTooLong(int max) {
    return 'The name can be at most $max characters.';
  }

  @override
  String get fcAccountRequiredToSearch =>
      'Create or select an account to search for a match.';

  @override
  String fcAccountLinkCta(String accountName, String teamName) {
    return 'Link $accountName to $teamName';
  }

  @override
  String get fcAccountsPageTitle => 'My Accounts';

  @override
  String get fcAccountsPageSubtitle => 'Your Ultimate Team accounts';

  @override
  String get fcAccountsEmptyTitle => 'You don\'t have an account yet';

  @override
  String get fcAccountsEmptyMessage =>
      'Create an account to link it to teams and start searching for matches.';

  @override
  String get fcAccountCreateAction => 'Create account';

  @override
  String get fcAccountCreateTitle => 'New account';

  @override
  String get fcAccountCreateSubtitle => 'Give this account a name.';

  @override
  String get fcAccountNameLabel => 'Account name';

  @override
  String get fcAccountNameHint => 'e.g. Main account';

  @override
  String get fcAccountRenameTitle => 'Rename account';

  @override
  String get fcAccountRenameAction => 'Rename';

  @override
  String get fcAccountArchiveAction => 'Archive account';

  @override
  String get fcAccountArchiveConfirmTitle => 'Archive account?';

  @override
  String get fcAccountArchiveConfirmMessage =>
      'The account stops showing in the list, but its history is kept.';

  @override
  String get fcAccountSwitchTitle => 'Switch account';

  @override
  String get fcAccountSwitchCreateAction => '+ Create new account';

  @override
  String get fcAccountLinkedTeamsTitle => 'Linked teams';

  @override
  String get fcAccountLinkedTeamsEmpty =>
      'This account isn\'t linked to any team yet.';

  @override
  String get fcAccountLinkTeamAction => 'Link';

  @override
  String get fcAccountUnlinkTeamAction => 'Unlink';

  @override
  String get fcAccountSettingsTitle => 'Settings';

  @override
  String get fcAccountDivisionTitle => 'Rivals Division';

  @override
  String get fcAccountDivisionPickerTitle => 'Select division';

  @override
  String get fcAccountDivisionNone => 'No division set';

  @override
  String get fcAccountWeekendLeagueTitle => 'Weekend League';

  @override
  String fcAccountWeekendLeagueComputedLabel(int wins, int losses) {
    return 'Tracked from matches: $wins–$losses';
  }

  @override
  String fcAccountWeekendLeagueManualLabel(int wins, int losses) {
    return 'Reported result: $wins–$losses';
  }

  @override
  String get fcAccountWeekendLeagueEditAction => 'Report result';

  @override
  String get fcAccountWeekendLeagueClearAction => 'Use tracked matches';

  @override
  String get fcAccountWeekendLeagueSheetTitle => 'Report result';

  @override
  String get fcAccountWeekendLeagueWinsLabel => 'Wins';

  @override
  String get fcAccountWeekendLeagueLossesLabel => 'Losses';

  @override
  String get fcAccountOnboardingTitle => 'Create your first account';

  @override
  String get fcAccountOnboardingMessage =>
      'An account represents an Ultimate Team account. Create one to link it to your teams and start searching for matches.';

  @override
  String get fcAccountOnboardingCreateAction => 'Create account';

  @override
  String pendingMatchElencoLabel(String name) {
    return 'Account: $name';
  }

  @override
  String historyElencoLabel(String name) {
    return 'Account: $name';
  }

  @override
  String get profileFcAccountsRow => 'Accounts';

  @override
  String get rivalsDivisionDiv10 => 'Division 10';

  @override
  String get rivalsDivisionDiv9 => 'Division 9';

  @override
  String get rivalsDivisionDiv8 => 'Division 8';

  @override
  String get rivalsDivisionDiv7 => 'Division 7';

  @override
  String get rivalsDivisionDiv6 => 'Division 6';

  @override
  String get rivalsDivisionDiv5 => 'Division 5';

  @override
  String get rivalsDivisionDiv4 => 'Division 4';

  @override
  String get rivalsDivisionDiv3 => 'Division 3';

  @override
  String get rivalsDivisionDiv2 => 'Division 2';

  @override
  String get rivalsDivisionDiv1 => 'Division 1';

  @override
  String get rivalsDivisionElite => 'Elite';

  @override
  String get squadsSectionTitle => 'Squads';

  @override
  String get squadsEmptyTitle => 'No squad yet';

  @override
  String get squadsEmptyMessage =>
      'Create a squad to set up your lineup. You can still search for a match without one.';

  @override
  String get squadCreateAction => 'Create squad';

  @override
  String get squadCreateTitle => 'New squad';

  @override
  String get squadCreateSubtitle => 'Name it and pick a starting formation.';

  @override
  String get squadNameLabel => 'Squad name';

  @override
  String get squadNameHint => 'e.g. Main';

  @override
  String get squadFormationLabel => 'Formation';

  @override
  String get squadRenameTitle => 'Rename squad';

  @override
  String get squadRenameAction => 'Rename';

  @override
  String get squadSetDefaultAction => 'Set as default';

  @override
  String get squadDefaultBadge => 'Default';

  @override
  String get squadArchiveAction => 'Archive squad';

  @override
  String get squadArchiveConfirmTitle => 'Archive squad?';

  @override
  String get squadArchiveConfirmMessage =>
      'It leaves the list, but the history of matches played with it is kept.';

  @override
  String get squadBenchTitle => 'Bench';

  @override
  String get squadManagerTitle => 'Manager';

  @override
  String get squadManagerAddAction => 'Add manager';

  @override
  String get squadManagerRemoveAction => 'Remove manager';

  @override
  String get squadManagerNationLabel => 'Country';

  @override
  String get squadManagerLeagueLabel => 'League';

  @override
  String get squadManagerPickNationFirst => 'Pick a country to see managers.';

  @override
  String get squadManagerNoneTitle => 'No manager';

  @override
  String get squadFormationPickerTitle => 'Choose formation';

  @override
  String get squadPlayerPickerTitle => 'Find player';

  @override
  String get squadPlayerSearchHint => 'Search player...';

  @override
  String get squadPlayerPickerEmpty => 'No cards found.';

  @override
  String get squadSlotChangeAction => 'Change player';

  @override
  String get squadSlotMoveAction => 'Move';

  @override
  String get squadSlotRemoveAction => 'Remove';

  @override
  String get squadMoveHint => 'Tap another slot to swap.';

  @override
  String get squadIncompleteLabel => 'Incomplete squad';

  @override
  String get squadLabel => 'Squad';

  @override
  String get squadNoneSelected => 'No squad';

  @override
  String get squadDevCatalogNotice =>
      'Development cards. The real catalog arrives in the next stage.';

  @override
  String get errorSquadNotFound => 'Squad not found.';

  @override
  String get errorSquadNameInvalid =>
      'Pick a name between 1 and 40 characters.';

  @override
  String get errorSquadFormationInvalid => 'That formation is not available.';

  @override
  String get errorSquadSlotInvalid =>
      'That slot does not exist in this formation.';

  @override
  String get errorSquadCardPosition =>
      'That player cannot play in that position.';

  @override
  String get errorSquadInUse => 'This squad is being used in an active search.';

  @override
  String squadCompletionLabel(int filled, int total) {
    return '$filled/$total starters';
  }

  @override
  String squadSummaryLabel(String name, String formation) {
    return '$name · $formation';
  }

  @override
  String get actionMore => 'More';
}
