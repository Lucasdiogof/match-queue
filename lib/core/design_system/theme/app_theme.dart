import 'package:fifa_queue/core/design_system/theme/app_semantic_colors.dart';
import 'package:fifa_queue/core/design_system/tokens/app_colors.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: AppSemanticColors.dark,
    statusBarStyle: SystemUiOverlayStyle.light,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: AppSemanticColors.light,
    statusBarStyle: SystemUiOverlayStyle.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppSemanticColors colors,
    required SystemUiOverlayStyle statusBarStyle,
  }) {
    // O acento era literalmente branco no escuro e preto no claro -- por isso
    // o app inteiro lia como cinza. Agora vem do token de acao, e desce
    // sozinho para CTA, foco de input, progresso e acao de snackbar.
    final accent = colors.accent;
    final onAccent = colors.onAccent;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: colors.accentContainer,
      onPrimaryContainer: colors.accent,
      secondary: colors.content,
      onSecondary: onAccent,
      secondaryContainer: colors.contentContainer,
      onSecondaryContainer: colors.content,
      tertiary: colors.competitive,
      onTertiary: onAccent,
      error: colors.danger,
      onError: onAccent,
      errorContainer: colors.surfaceElevated,
      onErrorContainer: colors.danger,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surfaceElevated,
      surfaceContainerHigh: colors.surfaceElevated,
      surfaceContainerHighest: colors.surfaceHighest,
      outline: colors.borderStrong,
      outlineVariant: colors.borderSubtle,
      shadow: AppColors.pureBlack,
      scrim: colors.overlay,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.background,
    );

    final textTheme = AppTypography.textTheme(
      colors.textPrimary,
      colors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: statusBarStyle,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderLg,
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: AppSizing.borderWidth,
        space: AppSpacing.lg,
      ),
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: AppSizing.iconLg,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          overlayColor: colors.accentPressed,
          disabledBackgroundColor: colors.surfaceHighest,
          disabledForegroundColor: colors.textTertiary,
          minimumSize: const Size.fromHeight(AppSizing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textTertiary,
          side: BorderSide(color: colors.borderStrong),
          minimumSize: const Size.fromHeight(AppSizing.buttonHeightMedium),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: accent,
            width: AppSizing.borderWidthStrong,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderMd,
          borderSide: BorderSide(
            color: colors.danger,
            width: AppSizing.borderWidthStrong,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surface,
        modalBarrierColor: colors.overlay,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderLg,
          side: BorderSide(color: colors.borderSubtle),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.accentContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadii.borderPill,
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? textTheme.labelMedium?.copyWith(color: colors.textPrimary)
              : textTheme.labelMedium?.copyWith(color: colors.textTertiary),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizing.iconLg,
            color: states.contains(WidgetState.selected)
                ? colors.textPrimary
                : colors.textTertiary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accentContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadii.borderPill,
        ),
        selectedIconTheme: IconThemeData(
          color: colors.textPrimary,
          size: AppSizing.iconLg,
        ),
        unselectedIconTheme: IconThemeData(
          color: colors.textTertiary,
          size: AppSizing.iconLg,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.textPrimary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.textTertiary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        actionTextColor: accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: colors.surfaceHighest,
        circularTrackColor: colors.surfaceHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceHighest,
          borderRadius: AppRadii.borderSm,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
