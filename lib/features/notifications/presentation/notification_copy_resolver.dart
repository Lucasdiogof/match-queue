import 'package:fifa_queue/features/fc_accounts/domain/entities/rivals_division.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/notifications/domain/entities/notification_category.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Titulo/corpo nunca vem pronto do backend (item 70): title_key + params
/// sao resolvidos aqui, o mesmo padrao de l10n usado no resto do app. Um
/// title_key sem case aqui cai no fallback generico -- nunca quebra a lista.
class NotificationCopyResolver {
  const NotificationCopyResolver._();

  static String textFor(AppLocalizations l10n, AppNotification notification) {
    final params = notification.params;
    return switch (notification.titleKey) {
      'notification_team_member_joined' => l10n.notificationTeamMemberJoined(
        _s(params, 'display_name'),
        _s(params, 'team_name'),
      ),
      'notification_team_leader_changed' => l10n.notificationTeamLeaderChanged(
        _s(params, 'leader_display_name'),
      ),
      'notification_you_are_team_leader' => l10n.notificationYouAreTeamLeader,
      'notification_team_top_scorer_changed' =>
        l10n.notificationTeamTopScorerChanged(
          _s(params, 'player_name'),
          _s(params, 'display_name'),
        ),
      'notification_team_top_assist_changed' =>
        l10n.notificationTeamTopAssistChanged(
          _s(params, 'player_name'),
          _s(params, 'display_name'),
        ),
      'notification_weekend_league_finished' =>
        l10n.notificationWeekendLeagueFinished(
          _s(params, 'display_name'),
          _i(params, 'wins'),
          _i(params, 'losses'),
        ),
      'notification_rivals_division_changed' =>
        l10n.notificationRivalsDivisionChanged(
          _s(params, 'display_name'),
          _divisionLabel(l10n, params['division']),
        ),
      _ => notification.titleKey,
    };
  }

  static IconData iconFor(NotificationCategory? category) => switch (category) {
    NotificationCategory.matchmaking => Icons.sports_esports_outlined,
    NotificationCategory.teams => Icons.groups_outlined,
    NotificationCategory.weekendLeague => Icons.emoji_events_outlined,
    NotificationCategory.rivals => Icons.shield_outlined,
    NotificationCategory.rankings => Icons.leaderboard_outlined,
    null => Icons.notifications_outlined,
  };

  static String _s(Map<String, dynamic> params, String key) {
    final value = params[key];
    return value is String && value.isNotEmpty ? value : '';
  }

  static int _i(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _divisionLabel(AppLocalizations l10n, Object? key) {
    final division = RivalsDivision.tryFromKey(key);
    return division == null ? '$key' : division.label(l10n);
  }
}
