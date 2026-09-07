import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppCardVariant { surface, elevated, outlined }

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.variant = AppCardVariant.surface,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = switch (variant) {
      AppCardVariant.surface => colors.surface,
      AppCardVariant.elevated => colors.surfaceElevated,
      AppCardVariant.outlined => Colors.transparent,
    };

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderLg,
        side: BorderSide(color: borderColor ?? colors.borderSubtle),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
