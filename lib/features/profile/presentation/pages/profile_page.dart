import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/notifications/application/push_token_coordinator.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_state.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/edit_display_name_sheet.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.profileTitle,
        subtitle: l10n.profileSubtitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: <Widget>[
          _AccountSection(),
          const SizedBox(height: AppSpacing.lg),
          const _FcAccountsSection(),
          const SizedBox(height: AppSpacing.lg),
          _PreferencesSection(),
          const SizedBox(height: AppSpacing.lg),
          const _EnvironmentRow(),
          const SizedBox(height: AppSpacing.xxl),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  Future<void> _editName(BuildContext context, String currentName) async {
    final messenger = ScaffoldMessenger.of(context);
    final savedMessage = context.l10n.profileSaved;
    final saved = await showEditDisplayNameSheet(
      context: context,
      currentDisplayName: currentName,
    );
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(savedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        if (profileState.status == ProfileStatus.failure) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppBanner(
                  tone: AppBannerTone.danger,
                  title: l10n.profileLoadErrorTitle,
                  message:
                      profileState.failure?.localizedMessage(l10n) ??
                      l10n.errorUnexpected,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.secondary(
                  label: l10n.actionRetry,
                  icon: Icons.refresh,
                  onPressed: () => context.read<ProfileCubit>().load(
                    fallbackDisplayName:
                        context.read<AuthCubit>().state.user?.shortName ?? '',
                  ),
                ),
              ],
            ),
          );
        }

        if (profileState.status == ProfileStatus.loading ||
            profileState.profile == null) {
          return const AppCard(
            child: SizedBox(height: 96, child: AppLoading()),
          );
        }

        final profile = profileState.profile!;

        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) => AppCard(
            child: Row(
              children: <Widget>[
                AppAvatar(
                  label: profile.displayName,
                  imageUrl: profile.avatarUrl,
                  size: AppSizing.avatarLg,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        profile.displayName,
                        style: context.textStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        authState.user?.email ?? '',
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: l10n.profileEditName,
                  variant: AppIconButtonVariant.outlined,
                  onPressed: () => _editName(context, profile.displayName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FcAccountsSection extends StatelessWidget {
  const _FcAccountsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: _NavRow(
        icon: Icons.sports_esports_outlined,
        label: l10n.profileFcAccountsRow,
        onTap: () => context.push(AppRoutes.fcAccounts.path),
      ),
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.profilePreferencesTitle.toUpperCase(),
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavRow(
            icon: Icons.brightness_6_outlined,
            label: l10n.settingsAppearance,
            value: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) => Text(switch (mode) {
                ThemeMode.system => l10n.themeSystem,
                ThemeMode.light => l10n.themeLight,
                ThemeMode.dark => l10n.themeDark,
              }),
            ),
            onTap: () => context.push(AppRoutes.profileAppearance.path),
          ),
          const AppDivider(),
          _NavRow(
            icon: Icons.language_outlined,
            label: l10n.settingsLanguage,
            value: BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) => Text(switch (locale) {
                null => l10n.languageSystem,
                AppLocales.portuguese => l10n.languagePortuguese,
                AppLocales.english => l10n.languageEnglish,
                AppLocales.spanish => l10n.languageSpanish,
                _ => l10n.languageSystem,
              }),
            ),
            onTap: () => context.push(AppRoutes.profileLanguage.path),
          ),
          const AppDivider(),
          _NavRow(
            icon: Icons.notifications_outlined,
            label: l10n.notificationsSectionTitle,
            onTap: () => context.push(AppRoutes.profileNotifications.path),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final Widget? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: AppSizing.iconMd, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
            if (value != null)
              DefaultTextStyle.merge(
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                child: value!,
              ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: AppSizing.iconMd,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentRow extends StatelessWidget {
  const _EnvironmentRow();

  @override
  Widget build(BuildContext context) {
    final config = AppConfigScope.of(context);
    if (config.environment.isProduction) {
      return const SizedBox.shrink();
    }
    return Row(
      children: <Widget>[
        AppBadge(
          label: context.l10n.environmentBadge(config.environment.key),
          tone: AppBadgeTone.warning,
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  Future<void> _signOut(BuildContext context) async {
    // Ordem importa: a baixa do device depende de auth.uid(), então precisa
    // acontecer com a sessão ainda válida, ANTES do signOut.
    final authCubit = context.read<AuthCubit>();
    await getIt<PushTokenCoordinator>().deactivateForSignOut();
    await authCubit.signOut();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) => AppButton.secondary(
      label: context.l10n.actionSignOut,
      icon: Icons.logout,
      isLoading: state.isSubmitting,
      onPressed: state.isSubmitting ? null : () => _signOut(context),
    ),
  );
}
