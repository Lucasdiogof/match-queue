import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ShareService {
  Future<void> copyToClipboard(String text);

  Future<void> share(String text, {String? subject});
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
}
