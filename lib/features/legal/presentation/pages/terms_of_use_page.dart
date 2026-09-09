import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/legal/legal_content_resolver.dart';
import 'package:fifa_queue/features/legal/presentation/widgets/legal_document_view.dart';
import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final document = resolveTermsOfUse(Localizations.localeOf(context));

    return AppScaffold(
      appBar: AppAppBar(title: l10n.termsOfUseTitle),
      body: LegalDocumentView(
        document: document,
        updatedAtLabel: l10n.legalUpdatedAt(
          l10n.historyEntryDate(DateTime.parse(document.updatedAt)),
        ),
      ),
    );
  }
}
