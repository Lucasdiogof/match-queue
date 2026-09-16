import 'dart:async';

import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_cubit.dart';
import 'package:fifa_queue/features/profiles/presentation/cubit/profiles_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Times seguem a Conta selecionada: trocar de conta recarrega "Meus
/// Times", e nunca sobra time da conta anterior na tela (mesmo motivo de
/// FcSquadsSessionListener). Login/logout tambem passam por aqui de graca:
/// ProfilesCubit zera selectedProfileId no logout, o que ja aciona
/// load(null) e limpa o estado.
class TeamsAccountListener extends StatelessWidget {
  const TeamsAccountListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<ProfilesCubit, ProfilesState>(
        listenWhen: (previous, current) =>
            previous.selectedProfileId != current.selectedProfileId,
        listener: (context, state) => unawaited(
          context.read<TeamsCubit>().load(profileId: state.selectedProfileId),
        ),
        child: child,
      );
}
