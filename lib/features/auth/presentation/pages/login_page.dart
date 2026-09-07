import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const String _localModeEmail = 'dev@fifaqueue.local';
  static const String _localModePassword = 'development';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = AppConfigScope.of(context);

    return AppScaffold(
      maxContentWidth: AppBreakpoints.maxFormWidth,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        children: <Widget>[
          const BrandLockup(markSize: BrandMarkSize.large, axis: Axis.vertical),
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.authWelcomeTitle, style: context.textStyles.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.authWelcomeMessage, style: context.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.authSignIn,
            onPressed: null,
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: l10n.authSignUp,
            onPressed: () => context.go(AppRoutes.signUp.path),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.ghost(
            label: l10n.authForgotPassword,
            expanded: true,
            onPressed: () => context.go(AppRoutes.forgotPassword.path),
          ),
          if (!config.hasSupabase) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            const _LocalModeCard(
              email: _localModeEmail,
              password: _localModePassword,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocalModeCard extends StatelessWidget {
  const _LocalModeCard({required this.email, required this.password});

  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) => AppCard(
        variant: AppCardVariant.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppBadge(label: 'dev', tone: AppBadgeTone.warning),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.authLocalModeTitle,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.authLocalModeMessage,
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              label: l10n.authLocalModeAction,
              isLoading: state.isSubmitting,
              onPressed: () => context.read<AuthCubit>().signIn(
                email: email,
                password: password,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
