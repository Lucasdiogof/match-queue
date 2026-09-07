import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppBannerTone { neutral, success, warning, danger }

class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = AppBannerTone.neutral,
    this.title,
    this.icon,
    super.key,
  });

  final String message;
  final AppBannerTone tone;
  final String? title;
  final IconData? icon;

  IconData get _icon =>
      icon ??
      switch (tone) {
        AppBannerTone.neutral => Icons.info_outline,
        AppBannerTone.success => Icons.check_circle_outline,
        AppBannerTone.warning => Icons.warning_amber_outlined,
        AppBannerTone.danger => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = switch (tone) {
      AppBannerTone.neutral => colors.textSecondary,
      AppBannerTone.success => colors.success,
      AppBannerTone.warning => colors.warning,
      AppBannerTone.danger => colors.danger,
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tone == AppBannerTone.neutral
              ? colors.surfaceElevated
              : accent.withValues(alpha: 0.10),
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: tone == AppBannerTone.neutral
                ? colors.borderSubtle
                : accent.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(_icon, size: AppSizing.iconMd, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(title!, style: context.textStyles.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                  ],
                  Text(
                    message,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
