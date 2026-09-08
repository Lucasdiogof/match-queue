import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/public_profile/presentation/widgets/sharing_settings_section.dart';
import 'package:flutter/material.dart';

class PublicProfileSettingsPage extends StatelessWidget {
  const PublicProfileSettingsPage({
    this.preselectFcAccountId,
    this.preselectShowSquad = false,
    super.key,
  });

  final String? preselectFcAccountId;
  final bool preselectShowSquad;

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.publicProfileSectionTitle),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[
        SharingSettingsSection(
          preselectFcAccountId: preselectFcAccountId,
          preselectShowSquad: preselectShowSquad,
        ),
      ],
    ),
  );
}
