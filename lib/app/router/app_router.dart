import 'package:fifa_queue/app/pages/app_shell_page.dart';
import 'package:fifa_queue/app/pages/route_error_page.dart';
import 'package:fifa_queue/app/pages/splash_page.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/navigation/go_router_refresh_stream.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/pages/login_page.dart';
import 'package:fifa_queue/features/auth/presentation/pages/reset_password_page.dart';
import 'package:fifa_queue/features/auth/presentation/pages/sign_up_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/fc_account_detail_page.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/pages/fc_accounts_page.dart';
import 'package:fifa_queue/features/fc_squads/presentation/pages/squad_builder_page.dart';
import 'package:fifa_queue/features/history/presentation/pages/history_page.dart';
import 'package:fifa_queue/features/home/presentation/pages/home_page.dart';
import 'package:fifa_queue/features/invitations/presentation/pages/join_team_page.dart';
import 'package:fifa_queue/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_appearance_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_language_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_notifications_page.dart';
import 'package:fifa_queue/features/profile/presentation/pages/profile_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/team_page.dart';
import 'package:fifa_queue/features/teams/presentation/pages/team_settings_page.dart';
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
        path: AppRoutes.fcAccounts.path,
        name: AppRoutes.fcAccounts.name,
        builder: (context, state) => const FcAccountsPage(),
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home.path,
                name: AppRoutes.home.name,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.team.path,
                name: AppRoutes.team.name,
                builder: (context, state) => const TeamPage(),
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
    final isUnauthenticatedArea = AppRoutes.unauthenticatedPaths.contains(
      location,
    );
    final isResetPassword = location == AppRoutes.resetPassword.path;

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
      return AppRoutes.home.path;
    }

    return null;
  }
}
