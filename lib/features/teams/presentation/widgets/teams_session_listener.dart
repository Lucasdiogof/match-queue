import 'dart:async';

import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Meus Times" sao da conta autenticada, entao so precisam (re)carregar
/// quando a sessao muda: entrou (conta virou nao-nula) ou saiu (virou nula,
/// e a lista tem que sumir em vez de sobrar pro proximo login).
class TeamsSessionListener extends StatelessWidget {
  const TeamsSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<AccountCubit, AccountState>(
        listenWhen: (previous, current) =>
            previous.account?.id != current.account?.id,
        listener: (context, state) => unawaited(
          context.read<TeamsCubit>().load(userId: state.account?.id),
        ),
        child: child,
      );
}
