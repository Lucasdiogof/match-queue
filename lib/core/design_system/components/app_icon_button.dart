import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:flutter/material.dart';

enum AppIconButtonVariant { plain, surface, outlined }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = AppIconButtonVariant.plain,
    this.size = AppSizing.iconButtonSize,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final AppIconButtonVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: variant == AppIconButtonVariant.surface
              ? colors.surfaceElevated
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderSm,
            side: variant == AppIconButtonVariant.outlined
                ? BorderSide(color: colors.borderStrong)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: AppSizing.iconLg,
                color: isEnabled ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
