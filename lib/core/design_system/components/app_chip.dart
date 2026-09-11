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
    // Selecionado nao pinta o chip inteiro de acento: fundo tingido, borda
    // e texto no acento. Uma fileira de chips totalmente preenchidos
    // competiria com o CTA da tela, e selecao nao e acao.
    final foreground = isSelected ? colors.accent : colors.textSecondary;

    return Material(
      color: isSelected ? colors.accentContainer : colors.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderPill,
        side: BorderSide(
          color: isSelected ? colors.accent : colors.borderSubtle,
          width: isSelected ? AppSizing.borderWidthStrong : AppSizing.borderWidth,
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
