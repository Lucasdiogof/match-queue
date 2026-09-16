import 'dart:async';

import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Times seguem a Conta selecionada: trocar de conta recarrega "Meus
/// Times", e nunca sobra time da conta anterior na tela (mesmo motivo de
/// FcSquadsSessionListener). Login/logout tambem passam por aqui de graca:
/// FcAccountsCubit zera selectedAccountId no logout, o que ja aciona
/// load(null) e limpa o estado.
class TeamsAccountListener extends StatelessWidget {
  const TeamsAccountListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<FcAccountsCubit, FcAccountsState>(
        listenWhen: (previous, current) =>
            previous.selectedAccountId != current.selectedAccountId,
        listener: (context, state) => unawaited(
          context.read<TeamsCubit>().load(fcAccountId: state.selectedAccountId),
        ),
        child: child,
      );
}
