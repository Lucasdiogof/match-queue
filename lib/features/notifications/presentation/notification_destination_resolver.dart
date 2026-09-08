import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/notifications/domain/entities/app_notification.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Resolver central para o tap num item da Central (item 96): decide o
/// destino a partir de type + params, nunca espalhado nos widgets.
class NotificationDestinationResolver {
  const NotificationDestinationResolver._();

  static Future<void> open(
    BuildContext context,
    AppNotification notification,
  ) async {
    final params = notification.params;
    final teamId = _string(params['team_id']);
    final fcAccountId = _string(params['fc_account_id']);

    if (teamId != null) {
      await context.read<TeamsCubit>().selectTeam(teamId);
      if (!context.mounted) {
        return;
      }
      await context.push(AppRoutes.teamDetailLocation(teamId));
      return;
    }

    if (fcAccountId != null) {
      await context.push(AppRoutes.fcAccountDetailLocation(fcAccountId));
      return;
    }

    await context.push(AppRoutes.home.path);
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
