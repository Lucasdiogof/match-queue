import 'dart:async';

import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ao voltar do segundo plano, renova a sessao se o token venceu enquanto o
/// app ficou parado -- evita o primeiro toque depois de um tempo falhar.
class SessionRefreshListener extends StatefulWidget {
  const SessionRefreshListener({required this.child, super.key});

  final Widget child;

  @override
  State<SessionRefreshListener> createState() => _SessionRefreshListenerState();
}

class _SessionRefreshListenerState extends State<SessionRefreshListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<AuthCubit>().refreshSessionIfNeeded());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
