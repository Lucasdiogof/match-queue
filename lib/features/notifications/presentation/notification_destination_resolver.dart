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

    // Pedido/convite recebido: a acao mora na tab Solicitacoes, nao no
    // detalhe do time (que nem existe ainda pra quem so recebeu convite).
    // Confere o TYPE tambem, nao so deep_link_type -- notificacoes antigas,
    // gravadas antes do deep_link_type='requests' existir, caiam no ramo de
    // team_id abaixo e tentavam abrir o detalhe do time que o admin ja
    // estava vendo, duplicando a rota (crash de chave repetida no
    // Navigator).
    const requestTypes = <String>{
      'TEAM_JOIN_REQUEST_RECEIVED',
      'TEAM_JOIN_REQUEST_APPROVED',
      'TEAM_JOIN_REQUEST_REJECTED',
    };
    if (notification.deepLinkType == 'requests' ||
        requestTypes.contains(notification.type)) {
      await _pushIfNotCurrent(context, AppRoutes.requests.path);
      return;
    }

    if (teamId != null) {
      await context.read<TeamsCubit>().selectTeam(teamId);
      if (!context.mounted) {
        return;
      }
      await _pushIfNotCurrent(context, AppRoutes.teamDetailLocation(teamId));
      return;
    }

    if (fcAccountId != null) {
      await _pushIfNotCurrent(
        context,
        AppRoutes.fcAccountDetailLocation(fcAccountId),
      );
      return;
    }

    await _pushIfNotCurrent(context, AppRoutes.central.path);
  }

  /// go_router lanca um assert de chave duplicada se a mesma rota que ja
  /// esta no topo da pilha for empurrada de novo (aconteceu com uma
  /// notificacao de pedido de time: o admin ja estava no detalhe daquele
  /// time quando tocou nela). Tocar numa notificacao cujo destino ja e a
  /// tela aberta agora so fecha a Central em vez de crashar.
  static Future<void> _pushIfNotCurrent(
    BuildContext context,
    String location,
  ) async {
    final current = GoRouterState.of(context).uri.toString();
    if (current == location) {
      return;
    }
    await context.push(location);
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
