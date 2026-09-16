import 'dart:async';

import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
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
      BlocListener<ProfilesCubit, ProfilesState>(
        listenWhen: (previous, current) =>
            previous.selectedProfileId != current.selectedProfileId,
        listener: (context, state) => unawaited(
          context.read<FcSquadsCubit>().load(state.selectedProfileId),
        ),
        child: child,
      );
}
