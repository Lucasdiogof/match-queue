import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/profiles/presentation/widgets/create_profile_sheet.dart';
import 'package:flutter/material.dart';

/// Estado vazio da tela de Jogar quando o usuário ainda não tem nenhum
/// elenco -- não há como buscar partida sem um.
class ProfileOnboardingCard extends StatelessWidget {
  const ProfileOnboardingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      variant: AppCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            Icons.sports_esports_outlined,
            size: AppSizing.iconLg,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.profileOnboardingTitle,
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.profileOnboardingMessage,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.profileOnboardingCreateAction,
            icon: Icons.add,
            onPressed: () => showCreateProfileSheet(context),
          ),
        ],
      ),
    );
  }
}
