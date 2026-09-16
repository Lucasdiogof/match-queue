import 'dart:async';

import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:fifa_queue/features/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Trocar de Conta cancela a busca ativa da Conta ANTERIOR, como se ela
/// tivesse tocado em "Cancelar" -- pedido explicito: a busca nao pode
/// continuar rodando em nome de uma Conta que nao esta mais selecionada.
///
/// De proposito FORA de MatchmakingCubit.close(): o cubit tambem e
/// descartado ao simplesmente navegar pra outra tela (o app e desenhado
/// pra busca continuar em background nesse caso -- MatchmakingSection tem
/// timer de seguranca e reage a voltar de foreground). Cancelar so faz
/// sentido quando o motivo especifico e troca de Conta, entao isto reage
/// direto a ProfilesCubit, nao ao dispose do cubit de matchmaking.
///
/// Best-effort: a Conta anterior pode nao estar buscando nada (o caso
/// comum), e cancel_match_search recusa com FQ015 nesse caso -- engolido
/// aqui, so log. Qualquer outra falha tambem so loga: isto roda em
/// background, sem UI pra mostrar erro, e nunca deve travar a troca de
/// conta em si.
class MatchmakingProfileListener extends StatelessWidget {
  const MatchmakingProfileListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // listenWhen roda sempre antes de listener pra cada transicao de
    // estado, na mesma chamada -- guardar o "previous" aqui e ler no
    // listener e seguro, nao um valor de outra transicao.
    String? previousProfileId;

    return BlocListener<ProfilesCubit, ProfilesState>(
      listenWhen: (previous, current) {
        previousProfileId = previous.selectedProfileId;
        return previous.selectedProfileId != current.selectedProfileId &&
            previous.selectedProfileId != null;
      },
      listener: (context, state) =>
          unawaited(_cancelPreviousSearch(previousProfileId)),
      child: child,
    );
  }

  Future<void> _cancelPreviousSearch(String? previousProfileId) async {
    if (previousProfileId == null) {
      return;
    }
    final logger = getIt<AppLogger>();
    try {
      await getIt<MatchmakingRepository>().cancelSearch(previousProfileId);
      logger.info(
        'busca cancelada por troca de conta (fc_account $previousProfileId)',
      );
    } on MatchmakingFailure catch (failure) {
      if (failure.reason != MatchmakingFailureReason.noActiveSearch) {
        logger.warning(
          'falha ao cancelar busca por troca de conta '
          '(fc_account $previousProfileId)',
          error: failure,
        );
      }
    } on AppFailure catch (failure) {
      logger.warning(
        'falha ao cancelar busca por troca de conta '
        '(fc_account $previousProfileId)',
        error: failure,
      );
    }
  }
}
