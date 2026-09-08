import 'dart:async';

import 'package:fifa_queue/core/logging/app_logger.dart';
import 'package:fifa_queue/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';

/// Costura o token do aparelho (vem do [PushMessagingService]) ao backend
/// (vai pelo [NotificationRepository]). Vive fora de qualquer tela porque o
/// ciclo do token não segue o ciclo de widget: ele nasce no login, rotaciona
/// sozinho e precisa morrer no backend ANTES do signOut — depois não há mais
/// sessão para a RPC autorizar.
///
/// Tudo aqui é best-effort: push é conveniência, nunca pode derrubar login,
/// logout ou navegação. Enquanto o Firebase real não existe, o serviço é o
/// [UnavailablePushMessagingService] e todo método vira no-op naturalmente.
class PushTokenCoordinator {
  PushTokenCoordinator(this._messaging, this._repository, this._logger);

  final PushMessagingService _messaging;
  final NotificationRepository _repository;
  final AppLogger _logger;

  StreamSubscription<String>? _tokenRefreshes;

  /// Chamar quando a sessão fica ativa. Só registra se houver permissão e
  /// token; começa a acompanhar rotações de token.
  Future<void> onSignedIn() async {
    if (!_messaging.isSupported) {
      return;
    }
    await registerCurrentToken();
    _tokenRefreshes ??= _messaging.tokenRefreshes().listen(
      _registerToken,
      onError: (Object error, StackTrace stackTrace) =>
          _logger.warning('Falha ao observar refresh de token FCM: $error'),
    );
  }

  /// Registra o token atual, se a permissão permitir. Chamado no login e logo
  /// após o usuário conceder a permissão.
  Future<void> registerCurrentToken() async {
    if (!_messaging.isSupported) {
      return;
    }
    final permission = await _messaging.currentPermission();
    if (!permission.canReceive) {
      return;
    }
    final token = await _messaging.currentToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _repository.registerDevice(
        token: token,
        platform: _messaging.platform,
      );
    } on Object catch (error) {
      _logger.warning('Falha ao registrar device de push: $error');
    }
  }

  /// Chamar ANTES do signOut, com a sessão ainda válida: a RPC de baixa
  /// depende de auth.uid(). Também para de acompanhar rotações.
  Future<void> deactivateForSignOut() async {
    await _stopTokenRefreshSync();
    if (!_messaging.isSupported) {
      return;
    }
    final token = await _messaging.currentToken();
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _repository.deactivateDevice(token);
    } on Object catch (error) {
      _logger.warning('Falha ao desativar device de push no logout: $error');
    }
  }

  /// Rede de segurança para quando a sessão cai sem passar pelo botão de sair
  /// (expiração, refresh token perdido): aí não dá para bater na RPC de baixa,
  /// mas ao menos paramos de acompanhar rotações do token do dono anterior.
  Future<void> onSignedOut() => _stopTokenRefreshSync();

  Future<void> _stopTokenRefreshSync() async {
    await _tokenRefreshes?.cancel();
    _tokenRefreshes = null;
  }
}
