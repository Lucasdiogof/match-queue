import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.onBack,
    this.backTooltip,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer;
  final VoidCallback? onBack;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: <Widget>[
          if (onBack != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                  0,
                ),
                child: AppIconButton(
                  icon: Icons.arrow_back,
                  tooltip: backTooltip ?? '',
                  onPressed: onBack,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppContentContainer.form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const BrandWordmark(height: 76),
                      const SizedBox(height: AppSpacing.xl),
                      Text(title, style: context.textStyles.headlineMedium),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        Text(subtitle!, style: context.textStyles.bodyMedium),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppContentContainer.form(child: footer!),
            ),
        ],
      ),
    ),
  );
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    required this.question,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Flexible(
        child: Text(
          question,
          textAlign: TextAlign.end,
          style: context.textStyles.bodySmall,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      AppButton.ghost(
        label: actionLabel,
        size: AppButtonSize.small,
        onPressed: onAction,
      ),
    ],
  );
}
