import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    maxContentWidth: AppBreakpoints.maxFormWidth,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const BrandLockup(markSize: BrandMarkSize.large, axis: Axis.vertical),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.appTagline,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: context.l10n.actionContinue,
            onPressed: () => context.go(AppRoutes.login.path),
          ),
        ],
      ),
    ),
  );
}
