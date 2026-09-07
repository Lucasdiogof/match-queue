import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/shared/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(
      title: context.l10n.teamTitle,
      subtitle: context.l10n.teamSubtitle,
    ),
    body: ComingSoonView(
      title: context.l10n.teamTitle,
      description: context.l10n.teamSubtitle,
      icon: Icons.groups_outlined,
    ),
  );
}
