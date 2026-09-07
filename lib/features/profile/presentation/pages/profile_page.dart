import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = AppConfigScope.of(context);

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.profileTitle,
        subtitle: l10n.profileSubtitle,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: <Widget>[
          const _AccountCard(),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: l10n.settingsAppearance,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  AppChip(
                    label: l10n.themeSystem,
                    isSelected: mode == ThemeMode.system,
                    onPressed: () =>
                        context.read<ThemeCubit>().select(ThemeMode.system),
                  ),
                  AppChip(
                    label: l10n.themeLight,
                    isSelected: mode == ThemeMode.light,
                    onPressed: () =>
                        context.read<ThemeCubit>().select(ThemeMode.light),
                  ),
                  AppChip(
                    label: l10n.themeDark,
                    isSelected: mode == ThemeMode.dark,
                    onPressed: () =>
                        context.read<ThemeCubit>().select(ThemeMode.dark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: l10n.settingsLanguage,
            child: BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  AppChip(
                    label: l10n.languageSystem,
                    isSelected: locale == null,
                    onPressed: () => context.read<LocaleCubit>().select(null),
                  ),
                  AppChip(
                    label: l10n.languagePortuguese,
                    isSelected: locale == AppLocales.portuguese,
                    onPressed: () => context.read<LocaleCubit>().select(
                      AppLocales.portuguese,
                    ),
                  ),
                  AppChip(
                    label: l10n.languageEnglish,
                    isSelected: locale == AppLocales.english,
                    onPressed: () =>
                        context.read<LocaleCubit>().select(AppLocales.english),
                  ),
                  AppChip(
                    label: l10n.languageSpanish,
                    isSelected: locale == AppLocales.spanish,
                    onPressed: () =>
                        context.read<LocaleCubit>().select(AppLocales.spanish),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              AppBadge(
                label: l10n.environmentBadge(config.environment.key),
                tone: config.environment.isProduction
                    ? AppBadgeTone.neutral
                    : AppBadgeTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton.secondary(
            label: l10n.actionSignOut,
            icon: Icons.logout,
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      final user = state.user;
      return AppCard(
        child: Row(
          children: <Widget>[
            AppAvatar(
              label: user?.shortName ?? '?',
              imageUrl: user?.avatarUrl,
              size: AppSizing.avatarLg,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user?.shortName ?? context.l10n.profileTitle,
                    style: context.textStyles.titleLarge,
                  ),
                  if (user != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.l10n.authSignedInAs(user.email),
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppCard(
    variant: AppCardVariant.elevated,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title.toUpperCase(), style: context.textStyles.labelSmall),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    ),
  );
}
