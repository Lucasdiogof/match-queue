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

  static const AppRoute central = AppRoute('central', '/app/central');
  static const AppRoute control = AppRoute('control', '/app/control');
  static const AppRoute team = AppRoute('team', '/app/team');
  static const AppRoute publicTeam = AppRoute(
    'public-team',
    '/app/team/public/:teamId',
  );
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
  static const AppRoute notifications = AppRoute(
    'notifications',
    '/app/notifications',
  );
  static const AppRoute profileSharing = AppRoute(
    'profile-sharing',
    '/app/profile/sharing',
  );
  static const AppRoute publicProfile = AppRoute(
    'public-profile',
    '/u/:identifier',
  );
  static const AppRoute fcAccounts = AppRoute(
    'fc-accounts',
    '/app/fc-accounts',
  );
  static const AppRoute cardsCatalog = AppRoute(
    'cards-catalog',
    '/app/catalog/cards',
  );
  static const AppRoute clubsCatalog = AppRoute(
    'clubs-catalog',
    '/app/catalog/clubs',
  );
  static const AppRoute clubDetail = AppRoute(
    'club-detail',
    '/app/catalog/clubs/:clubId',
  );
  static const String clubIdParam = 'clubId';

  static const AppRoute managersCatalog = AppRoute(
    'managers-catalog',
    '/app/catalog/managers',
  );
  static const AppRoute consumablesCatalog = AppRoute(
    'consumables-catalog',
    '/app/catalog/consumables',
  );

  static const AppRoute playstyles = AppRoute(
    'playstyles',
    '/app/mechanics/playstyles',
  );
  static const AppRoute playstyleDetail = AppRoute(
    'playstyle-detail',
    '/app/mechanics/playstyles/:playstyleName',
  );
  static const String playstyleNameParam = 'playstyleName';
  static const AppRoute chemistry = AppRoute(
    'chemistry',
    '/app/mechanics/chemistry',
  );
  static const AppRoute chemistryStyles = AppRoute(
    'chemistry-styles',
    '/app/mechanics/chemistry-styles',
  );
  static const AppRoute evolutions = AppRoute(
    'evolutions',
    '/app/mechanics/evolutions',
  );

  static const AppRoute controlsDribbling = AppRoute(
    'controls-dribbling',
    '/app/controls/dribbling',
  );
  static const AppRoute controlsPassing = AppRoute(
    'controls-passing',
    '/app/controls/passing',
  );
  static const AppRoute controlsShooting = AppRoute(
    'controls-shooting',
    '/app/controls/shooting',
  );
  static const AppRoute controlsDefending = AppRoute(
    'controls-defending',
    '/app/controls/defending',
  );

  static const AppRoute fcAccountDetail = AppRoute(
    'fc-account-detail',
    '/app/fc-accounts/:fcAccountId',
  );
  static const AppRoute deleteAccount = AppRoute(
    'delete-account',
    '/app/profile/delete-account',
  );
  static const AppRoute privacyPolicy = AppRoute('privacy', '/privacy');
  static const AppRoute termsOfUse = AppRoute('terms', '/terms');
  static const AppRoute about = AppRoute('about', '/app/profile/about');

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
  static const String identifierParam = 'identifier';

  static const List<AppRoute> shellRoutes = <AppRoute>[
    central,
    team,
    control,
    history,
    profile,
  ];

  static const Set<String> unauthenticatedPaths = <String>{
    '/login',
    '/signup',
    '/onboarding',
  };

  /// Acessíveis com ou sem sessão, nunca redirecionadas -- mesmo padrão de
  /// `/u/:identifier` (ver `isPublicProfileLocation`), mas path fixo em vez
  /// de prefixo.
  static const Set<String> alwaysPublicPaths = <String>{'/privacy', '/terms'};

  static String clubDetailLocation(String clubId) =>
      '/app/catalog/clubs/$clubId';

  static String playstyleDetailLocation(String playstyleName) =>
      '/app/mechanics/playstyles/${Uri.encodeComponent(playstyleName)}';

  static String joinTeamLocation(String inviteCode) => '/join/$inviteCode';

  static String fcAccountDetailLocation(String fcAccountId) =>
      '/app/fc-accounts/$fcAccountId';

  static String squadBuilderLocation(String squadId) => '/app/squads/$squadId';

  static String matchDetailLocation(String matchId) =>
      '/app/history/match/$matchId';

  static String teamDetailLocation(String teamId) => '/app/team/$teamId';

  static String publicTeamLocation(String teamId) => '/app/team/public/$teamId';

  static String playerProfileLocation(String teamId, String userId) =>
      '/app/team/$teamId/player/$userId';

  static bool isJoinTeamLocation(String location) =>
      location.startsWith('/join/');

  static bool isPublicProfileLocation(String location) =>
      location.startsWith('/u/');

  static String publicProfileLocation(String identifier) => '/u/$identifier';

  static String profileSharingLocation({
    String? preselectFcAccountId,
    bool preselectShowSquad = false,
  }) {
    final query = <String, String>{
      'fcAccountId': ?preselectFcAccountId,
      if (preselectShowSquad) 'showSquad': '1',
    };
    if (query.isEmpty) {
      return profileSharing.path;
    }
    return Uri(path: profileSharing.path, queryParameters: query).toString();
  }
}
