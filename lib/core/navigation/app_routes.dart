import 'package:flutter/widgets.dart';

class AppRoute {
  const AppRoute(this.name, this.path);

  final String name;
  final String path;
}

class AppRoutes {
  const AppRoutes._();

  /// Vive aqui (nao em app/router/app_router.dart) para que widgets fora do
  /// app-shell -- como PendingInviteListener -- consigam navegar sem
  /// depender do BuildContext de um BlocListener, que pode ficar orfao de
  /// GoRouter logo apos um redirect (ver PendingInviteListener).
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static const String inviteCodeParam = 'inviteCode';

  static const AppRoute splash = AppRoute('splash', '/');
  static const AppRoute login = AppRoute('login', '/login');
  static const AppRoute signUp = AppRoute('signup', '/signup');
  static const AppRoute resetPassword = AppRoute(
    'reset-password',
    '/reset-password',
  );
  static const AppRoute onboarding = AppRoute('onboarding', '/onboarding');
  static const AppRoute joinTeam = AppRoute('join-team', '/join/:inviteCode');

  static const AppRoute home = AppRoute('home', '/app/home');
  static const AppRoute team = AppRoute('team', '/app/team');
  static const AppRoute teamDetail = AppRoute(
    'team-detail',
    '/app/team/:teamId',
  );
  static const AppRoute playerProfile = AppRoute(
    'player-profile',
    '/app/team/:teamId/player/:userId',
  );
  static const AppRoute teamSettings = AppRoute(
    'team-settings',
    '/app/team/settings',
  );
  static const AppRoute history = AppRoute('history', '/app/history');
  static const AppRoute profile = AppRoute('profile', '/app/profile');
  static const AppRoute profileAppearance = AppRoute(
    'profile-appearance',
    '/app/profile/appearance',
  );
  static const AppRoute profileLanguage = AppRoute(
    'profile-language',
    '/app/profile/language',
  );
  static const AppRoute profileNotifications = AppRoute(
    'profile-notifications',
    '/app/profile/notifications',
  );
  static const AppRoute fcAccounts = AppRoute(
    'fc-accounts',
    '/app/fc-accounts',
  );
  static const AppRoute fcAccountDetail = AppRoute(
    'fc-account-detail',
    '/app/fc-accounts/:fcAccountId',
  );

  static const AppRoute squadBuilder = AppRoute(
    'squad-builder',
    '/app/squads/:squadId',
  );

  static const AppRoute matchDetail = AppRoute(
    'match-detail',
    '/app/history/match/:matchId',
  );

  static const String fcAccountIdParam = 'fcAccountId';
  static const String squadIdParam = 'squadId';
  static const String teamIdParam = 'teamId';
  static const String userIdParam = 'userId';
  static const String matchIdParam = 'matchId';

  static const List<AppRoute> shellRoutes = <AppRoute>[
    home,
    team,
    history,
    profile,
  ];

  static const Set<String> unauthenticatedPaths = <String>{
    '/login',
    '/signup',
    '/onboarding',
  };

  static String joinTeamLocation(String inviteCode) => '/join/$inviteCode';

  static String fcAccountDetailLocation(String fcAccountId) =>
      '/app/fc-accounts/$fcAccountId';

  static String squadBuilderLocation(String squadId) => '/app/squads/$squadId';

  static String matchDetailLocation(String matchId) =>
      '/app/history/match/$matchId';

  static String teamDetailLocation(String teamId) => '/app/team/$teamId';

  static String playerProfileLocation(String teamId, String userId) =>
      '/app/team/$teamId/player/$userId';

  static bool isJoinTeamLocation(String location) =>
      location.startsWith('/join/');
}
