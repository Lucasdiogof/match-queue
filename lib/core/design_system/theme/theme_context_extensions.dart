import 'package:fifa_queue/core/design_system/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textStyles => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppSemanticColors.dark
          : AppSemanticColors.light);

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
