import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamsSessionListener extends StatelessWidget {
  const TeamsSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.id != current.user?.id,
    listener: (context, state) {
      final teamsCubit = context.read<TeamsCubit>();
      final user = state.user;
      if (state.isAuthenticated && user != null) {
        unawaited(teamsCubit.load(userId: user.id));
      } else {
        teamsCubit.clear();
      }
    },
    child: child,
  );
}
