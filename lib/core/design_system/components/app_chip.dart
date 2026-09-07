import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onPressed,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected ? colors.background : colors.textSecondary;

    return Material(
      color: isSelected ? colors.textPrimary : colors.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderPill,
        side: BorderSide(
          color: isSelected ? colors.textPrimary : colors.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizing.iconSm, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
