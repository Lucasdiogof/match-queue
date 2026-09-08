import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FcAccountsSessionListener extends StatelessWidget {
  const FcAccountsSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.id != current.user?.id,
    listener: (context, state) {
      final cubit = context.read<FcAccountsCubit>();
      final user = state.user;
      if (state.isAuthenticated && user != null) {
        unawaited(cubit.load(userId: user.id));
      } else {
        cubit.clear();
      }
    },
    child: child,
  );
}
