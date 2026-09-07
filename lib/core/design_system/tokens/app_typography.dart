import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const List<String> fontFamilyFallback = <String>[
    'SF Pro Display',
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
  ];

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      double tracking = 0,
      double height = 1.25,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: tracking,
      height: height,
      color: color ?? primary,
      fontFamilyFallback: fontFamilyFallback,
    );

    return TextTheme(
      displayLarge: style(size: 44, weight: FontWeight.w700, tracking: -1.2),
      displayMedium: style(size: 36, weight: FontWeight.w700, tracking: -1),
      displaySmall: style(size: 30, weight: FontWeight.w700, tracking: -0.8),
      headlineLarge: style(size: 26, weight: FontWeight.w700, tracking: -0.6),
      headlineMedium: style(size: 22, weight: FontWeight.w700, tracking: -0.4),
      headlineSmall: style(size: 19, weight: FontWeight.w600, tracking: -0.2),
      titleLarge: style(size: 18, weight: FontWeight.w600, tracking: -0.2),
      titleMedium: style(size: 16, weight: FontWeight.w600),
      titleSmall: style(size: 14, weight: FontWeight.w600),
      bodyLarge: style(size: 16, weight: FontWeight.w400, height: 1.45),
      bodyMedium: style(
        size: 14,
        weight: FontWeight.w400,
        height: 1.45,
        color: secondary,
      ),
      bodySmall: style(
        size: 12,
        weight: FontWeight.w400,
        height: 1.4,
        color: secondary,
      ),
      labelLarge: style(size: 14, weight: FontWeight.w600, tracking: 0.2),
      labelMedium: style(size: 12, weight: FontWeight.w600, tracking: 0.4),
      labelSmall: style(
        size: 11,
        weight: FontWeight.w700,
        tracking: 0.8,
        color: secondary,
      ),
    );
  }

  static TextStyle timerDisplay(Color color) => TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1,
    color: color,
    fontFeatures: tabularFigures,
    fontFamilyFallback: fontFamilyFallback,
  );

  static TextStyle numeric(TextStyle base) =>
      base.copyWith(fontFeatures: tabularFigures);
}
