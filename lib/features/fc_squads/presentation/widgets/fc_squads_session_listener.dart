import 'dart:async';

import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// O squad e da conta autenticada, entao ele so precisa (re)carregar quando
/// a propria sessao muda: entrou (conta virou nao-nula) ou saiu (virou
/// nula, e a lista da conta anterior tem que sumir da tela em vez de
/// continuar visivel pro proximo login).
class FcSquadsSessionListener extends StatelessWidget {
  const FcSquadsSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<AccountCubit, AccountState>(
        listenWhen: (previous, current) =>
            previous.account?.id != current.account?.id,
        listener: (context, state) =>
            unawaited(context.read<FcSquadsCubit>().load()),
        child: child,
      );
}
