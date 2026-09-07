import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({this.spacing = AppSpacing.lg, this.indent = 0, super.key});

  final double spacing;
  final double indent;

  @override
  Widget build(BuildContext context) => Divider(
    color: context.colors.borderSubtle,
    thickness: AppSizing.borderWidth,
    height: spacing,
    indent: indent,
    endIndent: indent,
  );
}

class AppVerticalDivider extends StatelessWidget {
  const AppVerticalDivider({this.spacing = AppSpacing.lg, super.key});

  final double spacing;

  @override
  Widget build(BuildContext context) => VerticalDivider(
    color: context.colors.borderSubtle,
    thickness: AppSizing.borderWidth,
    width: spacing,
  );
}
