// Simula o que o launcher do Android realmente MOSTRA de um foreground
// adaptativo: o canvas tem 108dp, a mascara revela so os 72dp centrais
// (66,7%), e a "safe zone" garantida e o circulo de 66dp inscrito.
//
// Existe porque olhar o PNG inteiro engana: um aro nas bordas da arte
// aparece no arquivo e nunca aparece na tela inicial.
//
//   dart run tool/preview_adaptive_icon.dart <foreground.png> [saida.png]
import 'dart:io';

import 'package:image/image.dart' as img;

/// Fracao do canvas de 108dp que a mascara deixa ver (72/108).
const double _visibleFraction = 72 / 108;

/// Fracao do canvas que a safe zone circular ocupa (66/108).
const double _safeFraction = 66 / 108;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'uso: dart run tool/preview_adaptive_icon.dart <foreground.png> [saida.png]',
    );
    exitCode = 64;
    return;
  }

  final decoded = img.decodePng(File(args.first).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('nao consegui decodificar ${args.first}');
    exitCode = 65;
    return;
  }
  final src = decoded.convert(numChannels: 4);
  final out = args.length > 1 ? args[1] : 'adaptive_preview.png';

  final side = (src.width * _visibleFraction).round();
  final offset = (src.width - side) ~/ 2;
  final cropped = img.copyCrop(
    src,
    x: offset,
    y: offset,
    width: side,
    height: side,
  );

  // Recorta em circulo -- a forma mais agressiva que um launcher usa, e
  // portanto a que expoe qualquer conteudo perto demais da borda.
  final masked = img.Image(width: side, height: side, numChannels: 4);
  final center = side / 2;
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      final dx = x - center + 0.5;
      final dy = y - center + 0.5;
      if (dx * dx + dy * dy <= center * center) {
        masked.setPixel(x, y, cropped.getPixel(x, y));
      }
    }
  }

  // Anel marcando a safe zone, so no preview -- se a marca cruzar essa
  // linha, algum launcher vai corta-la.
  final safeRadius = src.width * _safeFraction / 2;
  img.drawCircle(
    masked,
    x: center.round(),
    y: center.round(),
    radius: safeRadius.round(),
    color: img.ColorRgba8(255, 0, 0, 180),
  );

  File(out).writeAsBytesSync(img.encodePng(masked));
  stdout.writeln('preview: $out (${side}x$side, circulo vermelho = safe zone)');
}
