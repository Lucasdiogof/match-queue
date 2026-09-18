// Mede a arte de icone antes de decidir como gera-la por plataforma:
// caixa do conteudo opaco, cor de fundo real da arte e caixa da marca
// clara (o "MQ"). Diagnostico, nao gerador -- roda com:
//   dart run tool/inspect_icon_art.dart <caminho.png>
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('uso: dart run tool/inspect_icon_art.dart <caminho.png>');
    exitCode = 64;
    return;
  }

  final path = args.first;
  // Limiar de luminancia que separa a MARCA metalica do fundo escuro.
  // Ajustavel porque a arte tem um brilho especular na borda do quadrado
  // que, num limiar baixo, e contado como marca e estraga a medida.
  final lumThreshold = args.length > 1 ? int.parse(args[1]) : 170;
  final decoded = img.decodePng(File(path).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('nao consegui decodificar $path');
    exitCode = 65;
    return;
  }
  final im = decoded.convert(numChannels: 4);
  stdout.writeln('arquivo : $path');
  stdout.writeln('tamanho : ${im.width}x${im.height}');

  // 1. Caixa do que e visivel (alpha > 8) -- a sombra da arte conta aqui.
  var oL = im.width, oT = im.height, oR = -1, oB = -1;
  // 2. Caixa do que e OPACO (alpha > 250) -- o quadrado arredondado em si,
  //    sem a sombra suave em volta.
  var sL = im.width, sT = im.height, sR = -1, sB = -1;
  // 3. Caixa dos pixels CLAROS -- a marca metalica sobre o fundo escuro.
  var mL = im.width, mT = im.height, mR = -1, mB = -1;

  var bgR = 0.0, bgG = 0.0, bgB = 0.0;
  var bgCount = 0;

  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      final a = p.a.toInt();
      if (a > 8) {
        if (x < oL) oL = x;
        if (y < oT) oT = y;
        if (x > oR) oR = x;
        if (y > oB) oB = y;
      }
      if (a > 250) {
        if (x < sL) sL = x;
        if (y < sT) sT = y;
        if (x > sR) sR = x;
        if (y > sB) sB = y;

        final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
        if (lum > lumThreshold) {
          if (x < mL) mL = x;
          if (y < mT) mT = y;
          if (x > mR) mR = x;
          if (y > mB) mB = y;
        }
      }
    }
  }

  // Cor de fundo: media dos pixels opacos escuros perto do centro-topo, onde
  // a arte nao tem marca -- evita puxar a media pro cinza do metal.
  for (var y = (im.height * 0.06).round(); y < (im.height * 0.18).round(); y++) {
    for (var x = (im.width * 0.35).round(); x < (im.width * 0.65).round(); x++) {
      final p = im.getPixel(x, y);
      if (p.a.toInt() > 250) {
        bgR += p.r;
        bgG += p.g;
        bgB += p.b;
        bgCount++;
      }
    }
  }

  String box(int l, int t, int r, int b) {
    if (r < l) return '(vazia)';
    final w = r - l + 1;
    final h = b - t + 1;
    final fw = (w / im.width * 100).toStringAsFixed(1);
    final fh = (h / im.height * 100).toStringAsFixed(1);
    return '${w}x$h em ($l,$t) -- $fw% x $fh% do canvas';
  }

  // A caixa "marca" acima pega qualquer pixel claro isolado -- inclusive o
  // brilho especular fino na borda do quadrado, que nao e marca. Medida por
  // DENSIDADE: so conta linha/coluna cuja quantidade de pixels claros passa
  // de 5% do pico. Um traco de 2px de brilho nao sobrevive a isso; o traco
  // grosso do M e do Q sobrevive.
  // So o miolo do quadrado opaco: o aro de brilho na borda da arte e claro
  // o bastante pra passar em qualquer limiar, e contamina a medida da marca
  // se entrar na conta. 8% de margem tira o aro sem chegar perto do MQ.
  final insetX = ((sR - sL + 1) * 0.08).round();
  final insetY = ((sB - sT + 1) * 0.08).round();
  final inL = sL + insetX, inR = sR - insetX;
  final inT = sT + insetY, inB = sB - insetY;

  final colCount = List<int>.filled(im.width, 0);
  final rowCount = List<int>.filled(im.height, 0);
  for (var y = inT; y <= inB; y++) {
    for (var x = inL; x <= inR; x++) {
      final p = im.getPixel(x, y);
      if (p.a.toInt() <= 250) continue;
      final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
      if (lum > lumThreshold) {
        colCount[x]++;
        rowCount[y]++;
      }
    }
  }
  int peak(List<int> v) => v.fold(0, (a, b) => a > b ? a : b);
  final colCut = peak(colCount) * 0.05;
  final rowCut = peak(rowCount) * 0.05;
  var dL = -1, dR = -1, dT = -1, dB = -1;
  for (var x = 0; x < im.width; x++) {
    if (colCount[x] > colCut) {
      if (dL < 0) dL = x;
      dR = x;
    }
  }
  for (var y = 0; y < im.height; y++) {
    if (rowCount[y] > rowCut) {
      if (dT < 0) dT = y;
      dB = y;
    }
  }

  stdout.writeln('visivel : ${box(oL, oT, oR, oB)}');
  stdout.writeln('densa   : ${box(dL, dT, dR, dB)}');
  stdout.writeln('opaco   : ${box(sL, sT, sR, sB)}');
  stdout.writeln('marca   : ${box(mL, mT, mR, mB)}');

  // Raio do arredondamento da arte: na primeira linha totalmente opaca, o
  // trecho opaco vai de x=r ate x=w-r. Comparar esse r com o da mascara do
  // iOS (~22,4% do lado) diz se a plataforma ja corta o aro da arte sozinha
  // -- se cortar, nao e preciso sangrar nada.
  if (sR >= sL) {
    final topY = sT;
    var runL = -1;
    for (var x = sL; x <= sR; x++) {
      if (im.getPixel(x, topY).a.toInt() > 250) {
        if (runL < 0) {
          runL = x;
          break;
        }
      }
    }
    if (runL >= 0) {
      final side = sR - sL + 1;
      final r = runL - sL;
      stdout.writeln(
        'raio    : ~${r}px de $side = ${(r / side * 100).toStringAsFixed(1)}% '
        '(mascara do iOS: ~22.4%)',
      );
    }
  }

  // Cor dos 4 cantos: e ela que encosta na cor de fundo configurada na
  // splash nativa. Se as duas nao baterem, aparece uma emenda visivel.
  for (final canto in <List<Object>>[
    <Object>['sup-esq', 4, 4],
    <Object>['sup-dir', im.width - 5, 4],
    <Object>['inf-esq', 4, im.height - 5],
    <Object>['inf-dir', im.width - 5, im.height - 5],
  ]) {
    final p = im.getPixel(canto[1] as int, canto[2] as int);
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    final hex = '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    stdout.writeln('canto ${canto[0]}: $hex (alpha ${p.a.toInt()})');
  }

  if (bgCount > 0) {
    final r = (bgR / bgCount).round();
    final g = (bgG / bgCount).round();
    final b = (bgB / bgCount).round();
    final hex = '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    stdout.writeln('fundo   : rgb($r, $g, $b) = $hex');
  }

  // Quanto a marca ocupa do quadrado opaco -- e esse numero que decide o
  // contentFraction seguro pro icone adaptativo do Android.
  if (mR >= mL && sR >= sL) {
    final markW = (mR - mL + 1) / (sR - sL + 1);
    final markH = (mB - mT + 1) / (sB - sT + 1);
    stdout.writeln(
      'marca/quadrado: ${(markW * 100).toStringAsFixed(1)}% larg, '
      '${(markH * 100).toStringAsFixed(1)}% alt',
    );
  }
}
