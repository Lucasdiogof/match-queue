import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/shared/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(
      title: context.l10n.homeTitle,
      subtitle: context.l10n.homeSubtitle,
    ),
    body: ComingSoonView(
      title: context.l10n.homeTitle,
      description: context.l10n.homeSubtitle,
      icon: Icons.search,
    ),
  );
}
