import 'package:fifa_queue/core/design_system/components/app_button.dart';
import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:fifa_queue/core/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                  color: colors.surfaceElevated,
                  borderRadius: AppRadii.borderLg,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Icon(
                  icon,
                  size: AppSizing.iconXl,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge,
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium,
                ),
              ],
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                AppButton.secondary(
                  label: actionLabel!,
                  onPressed: onAction,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
