import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';
import 'package:fifa_queue/features/notifications/domain/services/push_messaging_service.dart';

/// Usado enquanto nao existe projeto Firebase vinculado (e no modo local de
/// desenvolvimento). Nao finge permissao concedida nem token: diz que a
/// plataforma nao suporta push, e a UI mostra isso honestamente em vez de
/// oferecer um botao que nao faz nada.
class UnavailablePushMessagingService implements PushMessagingService {
  const UnavailablePushMessagingService(this.platform);

  @override
  final DevicePlatform platform;

  @override
  bool get isSupported => false;

  @override
  Future<PushPermissionStatus> currentPermission() async =>
      PushPermissionStatus.unsupported;

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.unsupported;

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> tokenRefreshes() => const Stream<String>.empty();

  @override
  Stream<Map<String, dynamic>> foregroundMessages() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Stream<Map<String, dynamic>> notificationTaps() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> initialNotification() async => null;
}
