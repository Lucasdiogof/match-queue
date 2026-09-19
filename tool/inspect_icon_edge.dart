// Perfil da BORDA da arte de icone: caminha da borda do quadrado opaco para
// dentro e reporta, a cada anel, a cor media e a luminancia.
//
// Serve pra responder duas coisas que decidem a cor de fundo da splash:
//   1. qual tom escuro representa a base da arte (nao "preto generico");
//   2. se existe um aro de brilho na borda -- se existir, casar a cor sozinha
//      NAO elimina a emenda, porque o aro continua desenhando o contorno.
//
//   dart run tool/inspect_icon_edge.dart <arte.png> [aneis]
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('uso: dart run tool/inspect_icon_edge.dart <arte.png> [aneis]');
    exitCode = 64;
    return;
  }

  final decoded = img.decodePng(File(args.first).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('nao consegui decodificar ${args.first}');
    exitCode = 65;
    return;
  }
  final im = decoded.convert(numChannels: 4);
  final rings = args.length > 1 ? int.parse(args[1]) : 14;

  // Caixa do opaco: o quadrado arredondado, sem a sombra em volta.
  var sL = im.width, sT = im.height, sR = -1, sB = -1;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      if (im.getPixel(x, y).a > 250) {
        if (x < sL) sL = x;
        if (y < sT) sT = y;
        if (x > sR) sR = x;
        if (y > sB) sB = y;
      }
    }
  }
  if (sR < sL) {
    stderr.writeln('arte sem regiao opaca');
    exitCode = 65;
    return;
  }

  stdout.writeln('opaco: ${sR - sL + 1}x${sB - sT + 1} em ($sL,$sT)');
  stdout.writeln('');
  stdout.writeln('anel  px   cor       lum    n');

  // Cada anel e a moldura de 1px a uma distancia `d` da borda do quadrado.
  // Amostra so as quatro faixas retas (topo, base, esquerda, direita),
  // pulando os cantos arredondados, onde nao ha pixel opaco.
  for (var i = 0; i < rings; i++) {
    final d = i;
    var r = 0.0, g = 0.0, b = 0.0;
    var n = 0;

    void take(int x, int y) {
      if (x < 0 || y < 0 || x >= im.width || y >= im.height) return;
      final p = im.getPixel(x, y);
      if (p.a.toInt() <= 250) return;
      r += p.r;
      g += p.g;
      b += p.b;
      n++;
    }

    // Faixas retas: 40% centrais de cada lado, longe dos cantos.
    final xFrom = sL + ((sR - sL) * 0.30).round();
    final xTo = sL + ((sR - sL) * 0.70).round();
    final yFrom = sT + ((sB - sT) * 0.30).round();
    final yTo = sT + ((sB - sT) * 0.70).round();
    for (var x = xFrom; x <= xTo; x++) {
      take(x, sT + d);
      take(x, sB - d);
    }
    for (var y = yFrom; y <= yTo; y++) {
      take(sL + d, y);
      take(sR - d, y);
    }

    if (n == 0) continue;
    final mr = (r / n).round();
    final mg = (g / n).round();
    final mb = (b / n).round();
    final lum = 0.2126 * mr + 0.7152 * mg + 0.0722 * mb;
    final hex = '#${mr.toRadixString(16).padLeft(2, '0')}'
        '${mg.toRadixString(16).padLeft(2, '0')}'
        '${mb.toRadixString(16).padLeft(2, '0')}';
    stdout.writeln(
      '${d.toString().padLeft(4)}  ${'$mr,$mg,$mb'.padRight(4)} $hex  '
      '${lum.toStringAsFixed(1).padLeft(5)}  $n',
    );
  }
}
