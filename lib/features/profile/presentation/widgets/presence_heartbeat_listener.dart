import 'dart:async';

import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Heartbeat de "estive ativo por aqui recentemente" -- nunca presença em
/// tempo real. Escreve no foreground e a cada tick espaçado enquanto
/// autenticado, nunca a cada segundo. Best-effort: falha de rede aqui nunca
/// aparece pro usuário, é só um timestamp secundário.
class PresenceHeartbeatListener extends StatefulWidget {
  const PresenceHeartbeatListener({required this.child, super.key});

  final Widget child;

  @override
  State<PresenceHeartbeatListener> createState() =>
      _PresenceHeartbeatListenerState();
}

class _PresenceHeartbeatListenerState extends State<PresenceHeartbeatListener>
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(seconds: 75);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_interval, (_) => _touch());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_touch());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _touch() async {
    if (!context.mounted || !context.read<AuthCubit>().state.isAuthenticated) {
      return;
    }
    try {
      await getIt<ProfileRepository>().touchActivity();
    } on Object {
      // best-effort de proposito -- ver doc da classe.
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listenWhen: (previous, current) =>
        !previous.isAuthenticated && current.isAuthenticated,
    listener: (context, _) => unawaited(_touch()),
    child: widget.child,
  );
}
