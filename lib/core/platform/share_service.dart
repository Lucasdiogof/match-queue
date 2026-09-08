import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ShareService {
  Future<void> copyToClipboard(String text);

  Future<void> share(String text, {String? subject});

  /// Compartilha um PNG gerado no app (cards de perfil/escalação). Lança se
  /// a plataforma nao suportar compartilhamento de arquivo -- quem chama
  /// decide o fallback (ex.: mensagem pedindo print de tela).
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? text,
  });
}

class DeviceShareService implements ShareService {
  const DeviceShareService();

  @override
  Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  @override
  Future<void> share(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<void> shareImage(
    Uint8List bytes, {
    required String fileName,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(bytes, mimeType: 'image/png', name: fileName),
        ],
        text: text,
      ),
    );
  }
}
