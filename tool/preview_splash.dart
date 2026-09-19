// Compoe a arte da splash sobre a cor de fundo escolhida, no enquadramento
// de um celular retrato, pra conferir se a emenda entre arte e fundo some de
// verdade. Olhar o PNG solto engana: o visualizador pinta preto puro atras,
// que nao e a cor que o app usa.
//
//   dart run tool/preview_splash.dart <arte.png> <#RRGGBB> [saida.png]
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'uso: dart run tool/preview_splash.dart <arte.png> <#RRGGBB> [saida.png]',
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
  final art = decoded.convert(numChannels: 4);

  final hex = args[1].replaceAll('#', '');
  final r = int.parse(hex.substring(0, 2), radix: 16);
  final g = int.parse(hex.substring(2, 4), radix: 16);
  final b = int.parse(hex.substring(4, 6), radix: 16);
  final out = args.length > 2 ? args[2] : 'splash_preview.png';

  // Proporcao de celular comum (9:19.5), na largura do canvas da arte.
  const width = 720;
  final height = (width * 19.5 / 9).round();
  final canvas = img.Image(width: width, height: height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(r, g, b));

  // A arte ocupa a mesma fracao da largura que a splash nativa usa.
  final side = (width * 0.70).round();
  final resized = img.copyResize(
    art,
    width: side,
    height: side,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    canvas,
    resized,
    dstX: (width - side) ~/ 2,
    dstY: (height - side) ~/ 2,
  );

  File(out).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('preview: $out (${width}x$height sobre #$hex)');
}
