import 'package:fifa_queue/features/notifications/domain/entities/push_permission_status.dart';

/// Abstracao do provedor de push. O Domain nunca ve tipo do Firebase.
///
/// Uma coisa obtem o token do aparelho (isto aqui); outra registra o token
/// no backend (NotificationRepository). Sao responsabilidades separadas de
/// proposito: trocar de provedor nao deveria mexer no schema, e mudar o
/// schema nao deveria mexer no SDK.
abstract interface class PushMessagingService {
  bool get isSupported;

  Future<PushPermissionStatus> currentPermission();

  Future<PushPermissionStatus> requestPermission();

  Future<String?> currentToken();

  /// Tokens rotacionam sozinhos; o backend precisa acompanhar.
  Stream<String> tokenRefreshes();

  /// Mensagens recebidas com o app aberto. Em foreground a UI ja e
  /// atualizada pelo Realtime, entao quem escuta isto trata como sinal de
  /// releitura -- nunca como fonte de estado.
  Stream<Map<String, dynamic>> foregroundMessages();

  /// Toques em notificacao que abriram ou trouxeram o app para frente.
  Stream<Map<String, dynamic>> notificationTaps();

  /// Notificacao que abriu o app a partir do estado terminado, se houver.
  Future<Map<String, dynamic>?> initialNotification();

  DevicePlatform get platform;
}
