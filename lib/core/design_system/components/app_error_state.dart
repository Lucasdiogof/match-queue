import 'package:fifa_queue/core/design_system/components/app_button.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.danger.withValues(alpha: 0.12),
                  borderRadius: AppRadii.borderLg,
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: AppSizing.iconXl,
                  color: colors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium,
              ),
              if (retryLabel != null && onRetry != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                AppButton.secondary(
                  label: retryLabel!,
                  onPressed: onRetry,
                  expanded: false,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
