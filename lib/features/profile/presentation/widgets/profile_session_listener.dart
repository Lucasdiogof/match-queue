import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSessionListener extends StatelessWidget {
  const ProfileSessionListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.id != current.user?.id,
    listener: (context, state) {
      final profileCubit = context.read<ProfileCubit>();
      final user = state.user;
      if (state.isAuthenticated && user != null) {
        unawaited(profileCubit.load(fallbackDisplayName: user.shortName));
      } else {
        profileCubit.clear();
      }
    },
    child: child,
  );
}
