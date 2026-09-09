import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/legal/domain/legal_document.dart';
import 'package:flutter/material.dart';

/// Corpo compartilhado por Privacidade e Termos -- só o título da página e
/// o conteúdo mudam entre as duas.
class LegalDocumentView extends StatelessWidget {
  const LegalDocumentView({
    required this.document,
    required this.updatedAtLabel,
    super.key,
  });

  final LegalDocument document;

  /// Já formatado pela página chamadora (ex.: "Atualizado em 08/09/2026"),
  /// para não duplicar lógica de data aqui.
  final String updatedAtLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text(
          updatedAtLabel,
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppBanner(
          tone: AppBannerTone.neutral,
          message: document.nonAffiliationDisclaimer,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final section in document.sections)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(section.title, style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  section.body,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
