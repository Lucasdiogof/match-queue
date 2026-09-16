import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/profiles/domain/entities/profile.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/create_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(
        title: l10n.profilesPageTitle,
        subtitle: l10n.profilesPageSubtitle,
      ),
      body: BlocBuilder<ProfilesCubit, ProfilesState>(
        builder: (context, state) {
          if (state.isLoading && !state.hasProfiles) {
            return const AppLoading();
          }
          if (!state.hasProfiles) {
            return _EmptyState(onCreate: () => showCreateProfileSheet(context));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            children: <Widget>[
              for (final profile in state.profiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ProfileCard(profile: profile),
                ),
              AppButton.secondary(
                label: l10n.profileCreateAction,
                icon: Icons.add,
                onPressed: () => showCreateProfileSheet(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.sports_esports_outlined,
              size: AppSizing.iconXl,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.profilesEmptyTitle,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.profilesEmptyMessage,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.profileCreateAction,
              icon: Icons.add,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      onTap: () => context.push(AppRoutes.profileDetailLocation(profile.id)),
      child: Row(
        children: <Widget>[
          AppAvatar(
            label: profile.name,
            imageUrl: profile.avatarUrl,
            size: AppSizing.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(profile.name, style: context.textStyles.titleMedium),
          ),
          Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
  }
}
