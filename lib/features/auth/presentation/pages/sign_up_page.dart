import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/shared/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    maxContentWidth: AppBreakpoints.maxFormWidth,
    appBar: AppAppBar(
      title: context.l10n.authSignUp,
      leading: AppIconButton(
        icon: Icons.arrow_back,
        tooltip: context.l10n.actionBack,
        onPressed: () => context.go(AppRoutes.login.path),
      ),
    ),
    body: ComingSoonView(
      title: context.l10n.authSignUp,
      description: context.l10n.authWelcomeMessage,
      icon: Icons.person_add_alt,
    ),
  );
}
