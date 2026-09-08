import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:go_router/go_router.dart';

/// Traduz o toque numa notificação em navegação. Recebe apenas `team_id` do
/// payload para escolher o time certo e abre a Home; o estado da fila é
/// SEMPRE relido do backend pela tela (o `MatchmakingCubit` recria e chama
/// `start()` ao trocar de time). O payload nunca é fonte da verdade: uma
/// notificação de "sua vez" pode chegar já obsoleta, e confiar nela mostraria
/// SEARCHING falso.
class NotificationRouter {
  const NotificationRouter(this._teamsCubit, this._logger);

  final TeamsCubit _teamsCubit;
  final AppLogger _logger;

  static const String keyTeamId = 'team_id';

  Future<void> handle(Map<String, dynamic> data) async {
    final teamId = _string(data[keyTeamId]);
    if (teamId != null) {
      // selectTeam é no-op se o time não pertence ao usuário ou já é o ativo;
      // em ambos os casos ainda faz sentido levar para a Home.
      await _teamsCubit.selectTeam(teamId);
    }

    final context = AppRoutes.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _logger.warning('Push tap sem navigator ativo; navegação ignorada.');
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
