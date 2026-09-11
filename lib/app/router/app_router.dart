import 'package:fifa_queue/app/pages/app_shell_page.dart';
import 'package:fifa_queue/app/pages/route_error_page.dart';
import 'package:fifa_queue/app/pages/splash_page.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/navigation/go_router_refresh_stream.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/pages/login_page.dart';
import 'package:fifa_queue/features/auth/presentation/pages/reset_password_page.dart';
import 'package:fifa_queue/features/auth/presentation/pages/sign_up_page.dart';
import 'package:fifa_queue/features/control/presentation/pages/control_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/fc_account_detail_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/fc_accounts_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/cards_catalog_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/club_detail_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/clubs_catalog_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/squad_builder_page.dart';
import 'package:fifa_queue/features/game/presentation/pages/match_details_page.dart';
import 'package:fifa_queue/features/history/presentation/pages/history_page.dart';
import 'package:fifa_queue/features/central/presentation/pages/central_page.dart';
import 'package:fifa_queue/features/invitations/presentation/pages/join_team_page.dart';
import 'package:fifa_queue/features/legal/presentation/pages/privacy_policy_page.dart';
import 'package:fifa_queue/features/legal/presentation/pages/terms_of_use_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/chemistry_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/chemistry_styles_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/consumables_catalog_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/controls/defending_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/controls/dribbling_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/controls/passing_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/controls/shooting_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/evolutions_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/managers_catalog_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/playstyle_detail_page.dart';
import 'package:fifa_queue/features/mechanics/presentation/pages/playstyles_page.dart';
import 'package:fifa_queue/features/notifications/presentation/pages/notifications_inbox_page.dart';
import 'package:fifa_queue/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/about_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/delete_account_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_appearance_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_language_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_notifications_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_page.dart';
import 'package:fifa_queue/features/public_profile/presentation/pages/public_profile_page.dart';
import 'package:fifa_queue/features/public_profile/presentation/pages/public_profile_settings_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/player_profile_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/team_detail_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/team_public_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/team_settings_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/teams_list_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  const AppRouter({required this.authCubit});

  final AuthCubit authCubit;

  GoRouter build() => GoRouter(
    navigatorKey: AppRoutes.rootNavigatorKey,
    initialLocation: AppRoutes.splash.path,
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: _redirect,
    errorBuilder: (context, state) => const RouteErrorPage(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash.path,
        name: AppRoutes.splash.name,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        name: AppRoutes.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp.path,
        name: AppRoutes.signUp.name,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword.path,
        name: AppRoutes.resetPassword.name,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding.path,
        name: AppRoutes.onboarding.name,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.joinTeam.path,
        name: AppRoutes.joinTeam.name,
        builder: (context, state) => JoinTeamPage(
          inviteCode: state.pathParameters[AppRoutes.inviteCodeParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.teamSettings.path,
        name: AppRoutes.teamSettings.name,
        builder: (context, state) => const TeamSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.playerProfile.path,
        name: AppRoutes.playerProfile.name,
        builder: (context, state) => PlayerProfilePage(
          teamId: state.pathParameters[AppRoutes.teamIdParam] ?? '',
          userId: state.pathParameters[AppRoutes.userIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.publicTeam.path,
        name: AppRoutes.publicTeam.name,
        builder: (context, state) => TeamPublicPage(
          teamId: state.pathParameters[AppRoutes.teamIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.teamDetail.path,
        name: AppRoutes.teamDetail.name,
        builder: (context, state) => TeamDetailPage(
          teamId: state.pathParameters[AppRoutes.teamIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.profileAppearance.path,
        name: AppRoutes.profileAppearance.name,
        builder: (context, state) => const ProfileAppearancePage(),
      ),
      GoRoute(
        path: AppRoutes.profileLanguage.path,
        name: AppRoutes.profileLanguage.name,
        builder: (context, state) => const ProfileLanguagePage(),
      ),
      GoRoute(
        path: AppRoutes.profileNotifications.path,
        name: AppRoutes.profileNotifications.name,
        builder: (context, state) => const ProfileNotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount.path,
        name: AppRoutes.deleteAccount.name,
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.about.path,
        name: AppRoutes.about.name,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy.path,
        name: AppRoutes.privacyPolicy.name,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsOfUse.path,
        name: AppRoutes.termsOfUse.name,
        builder: (context, state) => const TermsOfUsePage(),
      ),
      GoRoute(
        path: AppRoutes.profileSharing.path,
        name: AppRoutes.profileSharing.name,
        builder: (context, state) => PublicProfileSettingsPage(
          preselectFcAccountId: state.uri.queryParameters['fcAccountId'],
          preselectShowSquad: state.uri.queryParameters['showSquad'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.publicProfile.path,
        name: AppRoutes.publicProfile.name,
        builder: (context, state) => PublicProfilePage(
          identifier: state.pathParameters[AppRoutes.identifierParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications.path,
        name: AppRoutes.notifications.name,
        builder: (context, state) => const NotificationsInboxPage(),
      ),
      GoRoute(
        path: AppRoutes.fcAccounts.path,
        name: AppRoutes.fcAccounts.name,
        builder: (context, state) => const FcAccountsPage(),
      ),
      GoRoute(
        path: AppRoutes.cardsCatalog.path,
        name: AppRoutes.cardsCatalog.name,
        builder: (context, state) => const CardsCatalogPage(),
      ),
      GoRoute(
        path: AppRoutes.clubsCatalog.path,
        name: AppRoutes.clubsCatalog.name,
        builder: (context, state) => const ClubsCatalogPage(),
      ),
      GoRoute(
        path: AppRoutes.clubDetail.path,
        name: AppRoutes.clubDetail.name,
        builder: (context, state) => ClubDetailPage(
          clubId: state.pathParameters[AppRoutes.clubIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.fcAccountDetail.path,
        name: AppRoutes.fcAccountDetail.name,
        builder: (context, state) => FcAccountDetailPage(
          fcAccountId: state.pathParameters[AppRoutes.fcAccountIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.squadBuilder.path,
        name: AppRoutes.squadBuilder.name,
        builder: (context, state) => SquadBuilderPage(
          squadId: state.pathParameters[AppRoutes.squadIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.matchDetail.path,
        name: AppRoutes.matchDetail.name,
        builder: (context, state) => MatchDetailsPage(
          matchId: state.pathParameters[AppRoutes.matchIdParam] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.managersCatalog.path,
        name: AppRoutes.managersCatalog.name,
        builder: (context, state) => const ManagersCatalogPage(),
      ),
      GoRoute(
        path: AppRoutes.consumablesCatalog.path,
        name: AppRoutes.consumablesCatalog.name,
        builder: (context, state) => const ConsumablesCatalogPage(),
      ),
      GoRoute(
        path: AppRoutes.playstyles.path,
        name: AppRoutes.playstyles.name,
        builder: (context, state) => const PlaystylesPage(),
      ),
      GoRoute(
        path: AppRoutes.playstyleDetail.path,
        name: AppRoutes.playstyleDetail.name,
        builder: (context, state) => PlaystyleDetailPage(
          playstyleName: Uri.decodeComponent(
            state.pathParameters[AppRoutes.playstyleNameParam] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.chemistry.path,
        name: AppRoutes.chemistry.name,
        builder: (context, state) => const ChemistryPage(),
      ),
      GoRoute(
        path: AppRoutes.chemistryStyles.path,
        name: AppRoutes.chemistryStyles.name,
        builder: (context, state) => const ChemistryStylesPage(),
      ),
      GoRoute(
        path: AppRoutes.evolutions.path,
        name: AppRoutes.evolutions.name,
        builder: (context, state) => const EvolutionsPage(),
      ),
      GoRoute(
        path: AppRoutes.controlsDribbling.path,
        name: AppRoutes.controlsDribbling.name,
        builder: (context, state) => const DribblingPage(),
      ),
      GoRoute(
        path: AppRoutes.controlsPassing.path,
        name: AppRoutes.controlsPassing.name,
        builder: (context, state) => const PassingPage(),
      ),
      GoRoute(
        path: AppRoutes.controlsShooting.path,
        name: AppRoutes.controlsShooting.name,
        builder: (context, state) => const ShootingPage(),
      ),
      GoRoute(
        path: AppRoutes.controlsDefending.path,
        name: AppRoutes.controlsDefending.name,
        builder: (context, state) => const DefendingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.central.path,
                name: AppRoutes.central.name,
                builder: (context, state) => const CentralPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.team.path,
                name: AppRoutes.team.name,
                builder: (context, state) => const TeamsListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.control.path,
                name: AppRoutes.control.name,
                builder: (context, state) => const ControlPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.history.path,
                name: AppRoutes.history.name,
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile.path,
                name: AppRoutes.profile.name,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authCubit.state;
    final location = state.matchedLocation;
    final isSplash = location == AppRoutes.splash.path;
    final isJoinTeam = AppRoutes.isJoinTeamLocation(location);
    final isPublicProfile = AppRoutes.isPublicProfileLocation(location);
    final isAlwaysPublic = AppRoutes.alwaysPublicPaths.contains(location);
    final isUnauthenticatedArea = AppRoutes.unauthenticatedPaths.contains(
      location,
    );
    final isResetPassword = location == AppRoutes.resetPassword.path;

    // /u/:identifier e /privacy /terms funcionam sem sessao -- nunca
    // redireciona pro login, com ou sem sessao resolvida, igual
    // join/:inviteCode.
    if (isPublicProfile || isAlwaysPublic) {
      return null;
    }

    if (!authState.isResolved) {
      return isSplash ? null : AppRoutes.splash.path;
    }

    if (authState.isPasswordRecovery) {
      return isResetPassword ? null : AppRoutes.resetPassword.path;
    }

    if (!authState.isAuthenticated) {
      if (isJoinTeam || isUnauthenticatedArea || isResetPassword) {
        return null;
      }
      return AppRoutes.login.path;
    }

    if (isSplash || isUnauthenticatedArea) {
      // Jogar e a tela inicial: matchmaking e o que traz a pessoa ao app.
      // Continua sendo redirect (substitui), nao push, entao a raiz do shell
      // segue sem nada para voltar.
      return AppRoutes.control.path;
    }

    return null;
  }
}
