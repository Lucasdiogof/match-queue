import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  });

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    super.key,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  double get _height => switch (size) {
    AppButtonSize.small => AppSizing.buttonHeightSmall,
    AppButtonSize.medium => AppSizing.buttonHeightMedium,
    AppButtonSize.large => AppSizing.buttonHeightLarge,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnabled = onPressed != null && !isLoading;

    final (
      Color background,
      Color foreground,
      Color? border,
    ) = switch (variant) {
      // O primario era literalmente branco no escuro e preto no claro. E o
      // CTA da tela inteira -- e por ele que "acao" precisa ter cor.
      AppButtonVariant.primary => (colors.accent, colors.onAccent, null),
      AppButtonVariant.secondary => (
        colors.surfaceElevated,
        colors.textPrimary,
        colors.borderStrong,
      ),
      AppButtonVariant.ghost => (Colors.transparent, colors.textPrimary, null),
      AppButtonVariant.danger => (colors.danger, colors.onAccent, null),
    };

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? (variant == AppButtonVariant.ghost
                  ? Colors.transparent
                  : colors.surfaceHighest)
            : background,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colors.textTertiary
            : foreground,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) &&
                variant == AppButtonVariant.primary
            ? colors.accentPressed.withValues(alpha: 0.35)
            : foreground.withValues(alpha: 0.08),
      ),
      side: border == null
          ? null
          : WidgetStateProperty.all(BorderSide(color: border)),
      elevation: const WidgetStatePropertyAll<double>(0),
      shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.small
              ? AppSpacing.lg
              : AppSpacing.xl,
        ),
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        size == AppButtonSize.small
            ? context.textStyles.labelMedium
            : context.textStyles.labelLarge,
      ),
      minimumSize: WidgetStatePropertyAll<Size>(
        expanded ? Size.fromHeight(_height) : Size(0, _height),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final child = isLoading
        ? SizedBox(
            height: AppSizing.iconMd,
            width: AppSizing.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizing.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: style,
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
