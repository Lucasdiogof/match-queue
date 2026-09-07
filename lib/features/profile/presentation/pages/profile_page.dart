import 'package:fifa_queue/core/config/app_config_scope.dart';
import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/app_locales.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_state.dart';
import 'package:fifa_queue/features/profile/presentation/widgets/edit_display_name_sheet.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/locale_cubit.dart';
import 'package:fifa_queue/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        children: const <Widget>[
          _AccountSection(),
          SizedBox(height: AppSpacing.lg),
          _AppearanceSection(),
          SizedBox(height: AppSpacing.lg),
          _LanguageSection(),
          SizedBox(height: AppSpacing.lg),
          _EnvironmentRow(),
          SizedBox(height: AppSpacing.xxl),
          _SignOutButton(),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
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
                            l10n.profileMemberSince(profile.createdAt),
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
                const AppDivider(spacing: AppSpacing.xl),
                _InfoRow(
                  label: l10n.profileEmailLabel,
                  value: authState.user?.email ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label.toUpperCase(), style: context.textStyles.labelSmall),
      const SizedBox(height: AppSpacing.xxs),
      SelectableText(value, style: context.textStyles.bodyLarge),
    ],
  );
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SectionCard(
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
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SectionCard(
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
              onPressed: () =>
                  context.read<LocaleCubit>().select(AppLocales.portuguese),
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

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) => AppButton.secondary(
      label: context.l10n.actionSignOut,
      icon: Icons.logout,
      isLoading: state.isSubmitting,
      onPressed: state.isSubmitting
          ? null
          : () => context.read<AuthCubit>().signOut(),
    ),
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
