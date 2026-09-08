import 'dart:async';

import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handler de background: precisa ser funcao top-level, e o Firebase o roda
/// num isolate proprio, sem acesso a arvore de widgets nem ao DI do app.
///
/// Fica deliberadamente vazio: o sistema ja exibe a notificacao sozinho
/// quando o payload traz bloco `notification`. Tentar decidir alguma coisa
/// aqui seria justamente o erro que esta etapa evita -- o estado vem do
/// backend quando o app abre, nunca de um isolate de background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  bool get isSupported => true;

  @override
  DevicePlatform get platform {
    if (kIsWeb) {
      return DevicePlatform.web;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? DevicePlatform.ios
        : DevicePlatform.android;
  }

  @override
  Future<PushPermissionStatus> currentPermission() async =>
      _map(await _messaging.getNotificationSettings());

  /// Vale tanto para o dialogo do iOS quanto para o POST_NOTIFICATIONS do
  /// Android 13+: o plugin encaminha para o mecanismo certo de cada
  /// plataforma. Em versoes antigas do Android o retorno ja vem concedido.
  @override
  Future<PushPermissionStatus> requestPermission() async =>
      _map(await _messaging.requestPermission());

  /// Token so faz sentido depois da permissao; no iOS pedir antes retorna
  /// null porque o APNs ainda nao entregou o seu.
  @override
  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken();
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> tokenRefreshes() => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> foregroundMessages() =>
      FirebaseMessaging.onMessage.map((message) => message.data);

  @override
  Stream<Map<String, dynamic>> notificationTaps() =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);

  @override
  Future<Map<String, dynamic>?> initialNotification() async =>
      (await _messaging.getInitialMessage())?.data;

  PushPermissionStatus _map(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => PushPermissionStatus.granted,
        AuthorizationStatus.provisional => PushPermissionStatus.provisional,
        AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
        // denied e deniedPermanently viram o mesmo estado para o app: em
        // ambos nao adianta reabrir o dialogo do sistema, o caminho e os
        // ajustes do aparelho.
        _ => PushPermissionStatus.denied,
      };
}
