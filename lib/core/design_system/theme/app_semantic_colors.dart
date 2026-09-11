import 'package:fifa_queue/core/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.background,
    required this.backgroundRaised,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHighest,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.overlay,
    required this.accent,
    required this.accentPressed,
    required this.accentContainer,
    required this.content,
    required this.contentContainer,
    required this.competitive,
    required this.competitiveContainer,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.onAccent,
  });

  static const AppSemanticColors dark = AppSemanticColors(
    background: AppColors.darkBackground,
    backgroundRaised: AppColors.darkBackgroundRaised,
    surface: AppColors.darkSurface,
    surfaceElevated: AppColors.darkSurfaceElevated,
    surfaceHighest: AppColors.darkSurfaceHighest,
    borderSubtle: AppColors.darkBorderSubtle,
    borderStrong: AppColors.darkBorderStrong,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    overlay: AppColors.darkOverlay,
    accent: AppColors.fcGreen,
    accentPressed: AppColors.fcGreenStrong,
    accentContainer: AppColors.darkSurfaceGreen,
    content: AppColors.fcPurpleSoft,
    contentContainer: AppColors.darkSurfacePurple,
    competitive: AppColors.gold,
    competitiveContainer: AppColors.darkSurfaceGold,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    danger: AppColors.darkDanger,
    info: AppColors.darkInfo,
    onAccent: AppColors.darkBackground,
  );

  static const AppSemanticColors light = AppSemanticColors(
    background: AppColors.lightBackground,
    backgroundRaised: AppColors.lightBackgroundRaised,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceHighest: AppColors.lightSurfaceHighest,
    borderSubtle: AppColors.lightBorderSubtle,
    borderStrong: AppColors.lightBorderStrong,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    overlay: AppColors.lightOverlay,
    accent: AppColors.fcGreenDeep,
    accentPressed: AppColors.lightSuccess,
    accentContainer: AppColors.lightSurfaceGreen,
    content: AppColors.fcPurpleStrong,
    contentContainer: AppColors.lightSurfacePurple,
    competitive: AppColors.goldDeep,
    competitiveContainer: AppColors.lightSurfaceGold,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    danger: AppColors.lightDanger,
    info: AppColors.lightInfo,
    onAccent: AppColors.pureWhite,
  );

  final Color background;
  final Color backgroundRaised;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHighest;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color overlay;

  /// Acao: CTA, foco, selecao, matchmaking ativo.
  final Color accent;
  final Color accentPressed;
  final Color accentContainer;

  /// Conteudo do FC: catalogo, mecanicas, destaque editorial.
  final Color content;
  final Color contentContainer;

  /// Competitivo: ranking, premium, Champions/Rivals.
  final Color competitive;
  final Color competitiveContainer;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color onAccent;

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? backgroundRaised,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHighest,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? overlay,
    Color? accent,
    Color? accentPressed,
    Color? accentContainer,
    Color? content,
    Color? contentContainer,
    Color? competitive,
    Color? competitiveContainer,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? onAccent,
  }) => AppSemanticColors(
    background: background ?? this.background,
    backgroundRaised: backgroundRaised ?? this.backgroundRaised,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    surfaceHighest: surfaceHighest ?? this.surfaceHighest,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    overlay: overlay ?? this.overlay,
    accent: accent ?? this.accent,
    accentPressed: accentPressed ?? this.accentPressed,
    accentContainer: accentContainer ?? this.accentContainer,
    content: content ?? this.content,
    contentContainer: contentContainer ?? this.contentContainer,
    competitive: competitive ?? this.competitive,
    competitiveContainer: competitiveContainer ?? this.competitiveContainer,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    onAccent: onAccent ?? this.onAccent,
  );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppSemanticColors(
      background: mix(background, other.background),
      backgroundRaised: mix(backgroundRaised, other.backgroundRaised),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      surfaceHighest: mix(surfaceHighest, other.surfaceHighest),
      borderSubtle: mix(borderSubtle, other.borderSubtle),
      borderStrong: mix(borderStrong, other.borderStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      overlay: mix(overlay, other.overlay),
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentContainer: mix(accentContainer, other.accentContainer),
      content: mix(content, other.content),
      contentContainer: mix(contentContainer, other.contentContainer),
      competitive: mix(competitive, other.competitive),
      competitiveContainer: mix(competitiveContainer, other.competitiveContainer),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      info: mix(info, other.info),
      onAccent: mix(onAccent, other.onAccent),
    );
  }
}
