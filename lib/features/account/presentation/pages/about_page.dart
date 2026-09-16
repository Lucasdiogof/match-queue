import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/legal/legal_content_resolver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final disclaimer = resolvePrivacyPolicy(
      Localizations.localeOf(context),
    ).nonAffiliationDisclaimer;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.aboutTitle),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          Text(BrandAssets.productName, style: context.textStyles.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.aboutDescription,
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppBanner(tone: AppBannerTone.neutral, message: disclaimer),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _LinkRow(
                  label: l10n.privacyPolicyTitle,
                  onTap: () => context.push(AppRoutes.privacyPolicy.path),
                ),
                const AppDivider(),
                _LinkRow(
                  label: l10n.termsOfUseTitle,
                  onTap: () => context.push(AppRoutes.termsOfUse.path),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: context.textStyles.bodyLarge)),
          Icon(Icons.chevron_right, color: context.colors.textTertiary),
        ],
      ),
    ),
  );
}
