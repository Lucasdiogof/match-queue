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

  /// "Convites" virou uma aba de Times, nao rota propria -- este indice e
  /// passado como `extra` ao empurrar AppRoutes.team.path pra abrir direto
  /// nela (ex.: notificacao de pedido/convite recebido). Precisa bater com
  /// a ordem das abas em TeamsListPage.
  static const int teamRequestsTabIndex = 2;
  static const AppRoute accountHistory = AppRoute(
    'account-history',
    '/app/account/history',
  );
  static const AppRoute account = AppRoute('account', '/app/account');
  static const AppRoute accountAppearance = AppRoute(
    'account-appearance',
    '/app/account/appearance',
  );
  static const AppRoute accountLanguage = AppRoute(
    'account-language',
    '/app/account/language',
  );
  static const AppRoute accountNotifications = AppRoute(
    'account-notifications',
    '/app/account/notifications',
  );
  static const AppRoute notifications = AppRoute(
    'notifications',
    '/app/notifications',
  );
  static const AppRoute accountSharing = AppRoute(
    'account-sharing',
    '/app/account/sharing',
  );
  static const AppRoute publicProfile = AppRoute(
    'public-profile',
    '/u/:identifier',
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
  static const AppRoute market = AppRoute('market', '/app/market');
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

  static const AppRoute deleteAccount = AppRoute(
    'delete-account',
    '/app/account/delete-account',
  );
  static const AppRoute privacyPolicy = AppRoute('privacy', '/privacy');
  static const AppRoute termsOfUse = AppRoute('terms', '/terms');
  static const AppRoute about = AppRoute('about', '/app/account/about');

  static const AppRoute squadBuilder = AppRoute(
    'squad-builder',
    '/app/squads/:squadId',
  );

  static const String squadIdParam = 'squadId';
  static const String teamIdParam = 'teamId';
  static const String userIdParam = 'userId';
  static const String identifierParam = 'identifier';

  static const List<AppRoute> shellRoutes = <AppRoute>[
    central,
    team,
    control,
    market,
    account,
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

  static String squadBuilderLocation(String squadId) => '/app/squads/$squadId';

  static String teamDetailLocation(String teamId) => '/app/team/$teamId';

  static String publicTeamLocation(String teamId) => '/app/team/public/$teamId';

  static String playerProfileLocation(String teamId, String userId) =>
      '/app/team/$teamId/player/$userId';

  static bool isJoinTeamLocation(String location) =>
      location.startsWith('/join/');

  static bool isPublicProfileLocation(String location) =>
      location.startsWith('/u/');

  static String publicProfileLocation(String identifier) => '/u/$identifier';

}
