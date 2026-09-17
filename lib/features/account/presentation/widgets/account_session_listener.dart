import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/account/presentation/cubit/account_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountSessionListener extends StatelessWidget {
  const AccountSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.id != current.user?.id,
    listener: (context, state) {
      final accountCubit = context.read<AccountCubit>();
      final user = state.user;
      if (state.isAuthenticated && user != null) {
        unawaited(accountCubit.load(fallbackDisplayName: user.shortName));
      } else {
        accountCubit.clear();
      }
    },
    child: child,
  );
}
