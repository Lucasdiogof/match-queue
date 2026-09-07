import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_role.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';

extension TeamRoleL10n on TeamRole {
  String label(AppLocalizations l10n) => switch (this) {
    TeamRole.owner => l10n.teamRoleOwner,
    TeamRole.admin => l10n.teamRoleAdmin,
    TeamRole.player => l10n.teamRolePlayer,
  };

  AppBadgeTone get badgeTone => switch (this) {
    TeamRole.owner => AppBadgeTone.info,
    TeamRole.admin => AppBadgeTone.neutral,
    TeamRole.player => AppBadgeTone.neutral,
  };
}
