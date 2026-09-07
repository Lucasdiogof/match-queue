import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/invitations/presentation/cubit/pending_invite_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PendingInviteListener extends StatelessWidget {
  const PendingInviteListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        !previous.isAuthenticated &&
        current.isAuthenticated &&
        !current.isPasswordRecovery,
    listener: (context, state) {
      final invite = context.read<PendingInviteCubit>().state;
      if (invite == null) {
        return;
      }
      // O redirect do GoRouter para a rota autenticada (ex.: /signup ->
      // /app/home) roda de forma sincrona assim que o AuthCubit emite, antes
      // deste listener disparar. Nesse momento o BuildContext do
      // BlocListener pode ficar momentaneamente fora da arvore do Router
      // ("No GoRouter found in context"), entao navegamos pela navigatorKey
      // raiz -- estavel e sempre dentro da arvore do Router -- em vez de
      // GoRouter.of(context).
      final rootContext = AppRoutes.rootNavigatorKey.currentContext;
      if (rootContext == null) {
        return;
      }
      GoRouter.of(rootContext).go(AppRoutes.joinTeamLocation(invite.code));
    },
    child: child,
  );
}
