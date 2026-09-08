import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/teams/domain/entities/team_member_status.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class TeamStatusBadge extends StatelessWidget {
  const TeamStatusBadge({required this.member, super.key});

  final TeamMemberStatus member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    switch (member.status) {
      case PlayerOperationalStatus.inMatch:
        return AppBadge(label: l10n.teamStatusInMatch, tone: AppBadgeTone.danger);
      case PlayerOperationalStatus.searching:
        return AppBadge(label: l10n.teamStatusSearching, tone: AppBadgeTone.info);
      case PlayerOperationalStatus.queued:
        final position = member.queuePosition;
        return AppBadge(
          label: position == null
              ? l10n.teamStatusQueued
              : l10n.teamStatusQueuedWithPosition(position),
          tone: AppBadgeTone.neutral,
        );
      case PlayerOperationalStatus.recentlyActive:
        return AppBadge(
          label: _recentlyActiveLabel(l10n, member.lastActiveAt),
          tone: AppBadgeTone.success,
        );
      case PlayerOperationalStatus.offline:
        return Text(
          l10n.teamStatusOffline,
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        );
    }
  }

  String _recentlyActiveLabel(AppLocalizations l10n, DateTime? lastActiveAt) {
    if (lastActiveAt == null) {
      return l10n.teamStatusActiveNow;
    }
    final minutes = DateTime.now().difference(lastActiveAt).inMinutes;
    if (minutes <= 2) {
      return l10n.teamStatusActiveNow;
    }
    return l10n.teamStatusActiveMinutesAgo(minutes);
  }
}
