import 'dart:async';

import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/notifications/application/push_token_coordinator.dart';
import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_inbox_repository.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_unread_cubit.dart';
import 'package:fifa_queue/features/notifications/presentation/notification_router.dart';
import 'package:fifa_queue/features/notifications/presentation/widgets/enable_notifications_sheet.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_cubit.dart';
import 'package:fifa_queue/features/teams/presentation/cubit/teams_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Costura push ao ciclo de vida da sessão e da navegação, num ponto único
/// acima do app-shell:
///
/// - login/sessão restaurada → registra token e passa a acompanhar rotações;
/// - sessão encerrada sem passar pelo botão (expiração) → para de acompanhar;
/// - toque em notificação (app aberto ou frio) → [NotificationRouter];
/// - mensagem em foreground → **suprimida** de propósito: o Realtime da Etapa
///   6 já atualiza a tela e mostra o "Sua vez de buscar!". Um segundo alerta
///   aqui seria a duplicata que esta etapa evita;
/// - convite pré-permissão → aparece uma única vez, DEPOIS de o usuário já ter
///   time, nunca no login.
///
/// Com o [UnavailablePushMessagingService] (Web, ou enquanto o Firebase não
/// inicializa) os streams são vazios, `initialNotification()` é nulo e
/// `isSupported` é falso: o widget fica inteiramente inerte.
class NotificationLifecycleListener extends StatefulWidget {
  const NotificationLifecycleListener({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationLifecycleListener> createState() =>
      _NotificationLifecycleListenerState();
}

class _NotificationLifecycleListenerState
    extends State<NotificationLifecycleListener> {
  static const String _promptShownKey = 'notifications.prompt_shown';

  final PushMessagingService _messaging = getIt<PushMessagingService>();
  final PushTokenCoordinator _coordinator = getIt<PushTokenCoordinator>();
  final AppLogger _logger = getIt<AppLogger>();

  late final NotificationRouter _router = NotificationRouter(
    context.read<TeamsCubit>(),
    _logger,
    inboxRepository: getIt<NotificationInboxRepository>(),
    unreadCubit: context.read<NotificationUnreadCubit>(),
  );

  StreamSubscription<Map<String, dynamic>>? _taps;
  StreamSubscription<Map<String, dynamic>>? _foreground;
  bool _promptedThisRun = false;

  @override
  void initState() {
    super.initState();

    // Sessão já ativa no arranque (restaurada): o BlocListener não dispara
    // para o estado inicial, então tratamos aqui.
    if (context.read<AuthCubit>().state.isAuthenticated) {
      unawaited(_coordinator.onSignedIn());
      unawaited(context.read<NotificationUnreadCubit>().refresh());
    }

    _taps = _messaging.notificationTaps().listen(
      _router.handle,
      onError: (Object error, StackTrace _) =>
          _logger.warning('Erro no stream de toques de push: $error'),
    );
    _foreground = _messaging.foregroundMessages().listen(
      _onForegroundMessage,
      onError: (Object error, StackTrace _) =>
          _logger.warning('Erro no stream de push em foreground: $error'),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _messaging.initialNotification();
      if (initial != null) {
        await _router.handle(initial);
      }
    });
  }

  void _onForegroundMessage(Map<String, dynamic> data) {
    // Sem UI de propósito: o Realtime já cuida do refresh e do snackbar de
    // matchmaking. Os tipos sociais/esportivos da Etapa 15 so atualizam o
    // badge silenciosamente -- item 45, nada de snackbar + inbox + modal.
    _logger.debug('Push em foreground suprimido (Realtime cobre a tela).');
    unawaited(context.read<NotificationUnreadCubit>().refresh());
  }

  Future<void> _maybePromptForPermission() async {
    if (_promptedThisRun || !_messaging.isSupported) {
      return;
    }
    final permission = await _messaging.currentPermission();
    if (permission != PushPermissionStatus.notDetermined) {
      return;
    }
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(_promptShownKey) ?? false) {
      return;
    }
    final context = AppRoutes.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }
    _promptedThisRun = true;
    await prefs.setBool(_promptShownKey, true);
    if (!context.mounted) {
      return;
    }

    final confirmed = await showEnableNotificationsSheet(context);
    if (!confirmed) {
      return;
    }
    final result = await _messaging.requestPermission();
    if (result.canReceive) {
      await _coordinator.registerCurrentToken();
    }
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    unawaited(_foreground?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: <BlocListener<dynamic, dynamic>>[
      BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.isAuthenticated != current.isAuthenticated ||
            previous.user?.id != current.user?.id,
        listener: (context, state) {
          if (state.isAuthenticated) {
            unawaited(_coordinator.onSignedIn());
            unawaited(context.read<NotificationUnreadCubit>().refresh());
          } else {
            _promptedThisRun = false;
            unawaited(_coordinator.onSignedOut());
            // Item 94/95: badge nunca pode sobreviver a troca de sessão.
            context.read<NotificationUnreadCubit>().clear();
          }
        },
      ),
      BlocListener<TeamsCubit, TeamsState>(
        listenWhen: (previous, current) => current.hasTeams,
        listener: (context, _) => unawaited(_maybePromptForPermission()),
      ),
    ],
    child: widget.child,
  );
}
