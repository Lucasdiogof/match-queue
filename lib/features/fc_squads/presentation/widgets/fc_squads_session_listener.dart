import 'dart:async';

import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_squads/presentation/cubit/fc_squads_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Squads seguem o Elenco selecionado: trocar de conta recarrega a lista, e
/// nunca sobra squad da conta anterior na tela (item 127).
class FcSquadsSessionListener extends StatelessWidget {
  const FcSquadsSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<FcAccountsCubit, FcAccountsState>(
        listenWhen: (previous, current) =>
            previous.selectedAccountId != current.selectedAccountId,
        listener: (context, state) => unawaited(
          context.read<FcSquadsCubit>().load(state.selectedAccountId),
        ),
        child: child,
      );
}
