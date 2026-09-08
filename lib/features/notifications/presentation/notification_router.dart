// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_unread_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:go_router/go_router.dart';

/// Traduz o toque numa notificação (push ou item da Central) em navegação.
/// Resolver central (item 96): nenhum widget faz esse switch na mão. Recebe
/// so ids do payload -- o estado real de cada tela e SEMPRE relido do
/// backend, nunca confiado ao payload (uma notificação pode chegar já
/// obsoleta).
class NotificationRouter {
  const NotificationRouter(
    this._teamsCubit,
    this._logger, {
    NotificationInboxRepository? inboxRepository,
    NotificationUnreadCubit? unreadCubit,
  }) : _inboxRepository = inboxRepository,
       _unreadCubit = unreadCubit;

  final TeamsCubit _teamsCubit;
  final AppLogger _logger;
  final NotificationInboxRepository? _inboxRepository;
  final NotificationUnreadCubit? _unreadCubit;

  static const String keyType = 'type';
  static const String keyTeamId = 'team_id';
  static const String keyFcAccountId = 'fc_account_id';
  static const String keyNotificationId = 'notification_id';

  static const Set<String> _teamScopedTypes = <String>{
    'TEAM_MEMBER_JOINED',
    'TEAM_LEADER_CHANGED',
    'TEAM_TOP_SCORER_CHANGED',
    'TEAM_TOP_ASSIST_CHANGED',
    'WEEKEND_LEAGUE_FINISHED',
    'RIVALS_DIVISION_CHANGED',
  };

  Future<void> handle(Map<String, dynamic> data) async {
    final notificationId = _string(data[keyNotificationId]);
    if (notificationId != null && _inboxRepository != null) {
      unawaited(_inboxRepository.markRead(notificationId));
      _unreadCubit?.decrementBy(1);
    }

    final teamId = _string(data[keyTeamId]);
    if (teamId != null) {
      await _teamsCubit.selectTeam(teamId);
    }

    final context = AppRoutes.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _logger.warning('Push tap sem navigator ativo; navegação ignorada.');
      return;
    }

    final type = _string(data[keyType]);
    final fcAccountId = _string(data[keyFcAccountId]);

    if (type != null && _teamScopedTypes.contains(type) && teamId != null) {
      context.go(AppRoutes.teamDetailLocation(teamId));
      return;
    }
    if (type == 'RIVALS_DIVISION_CHANGED' && fcAccountId != null) {
      context.go(AppRoutes.fcAccountDetailLocation(fcAccountId));
      return;
    }

    context.go(AppRoutes.home.path);
  }

  static String? _string(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
