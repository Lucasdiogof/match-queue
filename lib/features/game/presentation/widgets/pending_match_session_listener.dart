import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/game/presentation/cubit/pending_match_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingMatchSessionListener extends StatelessWidget {
  const PendingMatchSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.id != current.user?.id,
    listener: (context, state) {
      final cubit = context.read<PendingMatchCubit>();
      if (state.isAuthenticated) {
        unawaited(cubit.load());
      } else {
        cubit.clear();
      }
    },
    child: child,
  );
}
