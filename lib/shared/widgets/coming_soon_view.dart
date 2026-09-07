import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        Text(title, style: context.textStyles.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(description, style: context.textStyles.bodyLarge),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          variant: AppCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: AppSizing.iconLg,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.comingSoonTitle,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                  AppBadge(label: l10n.comingSoonNextStage),
                ],
              ),
              const AppDivider(spacing: AppSpacing.xl),
              Text(
                l10n.comingSoonMessage,
                style: context.textStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
