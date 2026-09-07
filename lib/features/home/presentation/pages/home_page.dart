import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.homeTitle, subtitle: l10n.homeSubtitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        children: <Widget>[
          const _GreetingCard(),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            variant: AppCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.travel_explore_outlined,
                      size: AppSizing.iconLg,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.homeSearchPlaceholderTitle,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                const AppDivider(spacing: AppSpacing.xl),
                Text(
                  l10n.homeSearchPlaceholderMessage,
                  style: context.textStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileCubit, ProfileState>(
    builder: (context, profileState) => BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final name = profileState.profile?.displayName.isNotEmpty ?? false
            ? profileState.profile!.displayName
            : (authState.user?.shortName ?? '');

        return Row(
          children: <Widget>[
            AppAvatar(
              label: name,
              imageUrl: profileState.profile?.avatarUrl,
              size: AppSizing.avatarLg,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.homeGreeting(name),
                    style: context.textStyles.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.l10n.appTagline,
                    style: context.textStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
