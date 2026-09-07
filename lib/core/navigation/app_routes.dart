class AppRoute {
  const AppRoute(this.name, this.path);

  final String name;
  final String path;
}

class AppRoutes {
  const AppRoutes._();

  static const String inviteCodeParam = 'inviteCode';

  static const AppRoute splash = AppRoute('splash', '/');
  static const AppRoute login = AppRoute('login', '/login');
  static const AppRoute signUp = AppRoute('signup', '/signup');
  static const AppRoute forgotPassword = AppRoute(
    'forgot-password',
    '/forgot-password',
  );
  static const AppRoute resetPassword = AppRoute(
    'reset-password',
    '/reset-password',
  );
  static const AppRoute onboarding = AppRoute('onboarding', '/onboarding');
  static const AppRoute joinTeam = AppRoute('join-team', '/join/:inviteCode');

  static const AppRoute home = AppRoute('home', '/app/home');
  static const AppRoute team = AppRoute('team', '/app/team');
  static const AppRoute history = AppRoute('history', '/app/history');
  static const AppRoute profile = AppRoute('profile', '/app/profile');

  static const List<AppRoute> shellRoutes = <AppRoute>[
    home,
    team,
    history,
    profile,
  ];

  static const Set<String> unauthenticatedPaths = <String>{
    '/login',
    '/signup',
    '/forgot-password',
    '/onboarding',
  };

  static String joinTeamLocation(String inviteCode) => '/join/$inviteCode';

  static bool isJoinTeamLocation(String location) =>
      location.startsWith('/join/');
}
