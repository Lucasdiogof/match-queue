import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppBadgeTone { neutral, success, warning, danger, info }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = switch (tone) {
      AppBadgeTone.neutral => colors.textSecondary,
      AppBadgeTone.success => colors.success,
      AppBadgeTone.warning => colors.warning,
      AppBadgeTone.danger => colors.danger,
      AppBadgeTone.info => colors.info,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone == AppBadgeTone.neutral
            ? colors.surfaceHighest
            : foreground.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderXs,
        border: Border.all(
          color: tone == AppBadgeTone.neutral
              ? colors.borderSubtle
              : foreground.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
