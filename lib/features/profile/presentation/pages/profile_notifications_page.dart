import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/notification_settings_section.dart';
import 'package:flutter/material.dart';

class ProfileNotificationsPage extends StatelessWidget {
  const ProfileNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppAppBar(title: context.l10n.notificationsSectionTitle),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      children: <Widget>[NotificationSettingsSection()],
    ),
  );
}
