import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captura um widget marcado com [RepaintBoundary] como PNG. Usado pelos
/// cards visuais compartilhaveis -- gerado 100% no Flutter, sem backend de
/// imagem externo.
class ShareCapture {
  const ShareCapture._();

  static Future<Uint8List?> captureBoundary(
    GlobalKey key, {
    double pixelRatio = 3,
  }) async {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
