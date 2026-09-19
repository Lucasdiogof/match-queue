// Tom predominante do FUNDO da arte: percorre os pixels opacos, descarta o
// desenho metalico (claro) e reporta a distribuicao do que sobra.
//
// Responde "qual escuro representa a base da arte" melhor que medir a borda:
// a borda tem vinheta e e mais escura que o miolo, entao casar o fundo da
// splash com ela deixa o miolo aparecendo como um retangulo mais claro.
//
//   dart run tool/inspect_icon_base.dart <arte.png> [lumMaxDoFundo]
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('uso: dart run tool/inspect_icon_base.dart <arte.png> [lumMax]');
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
  // Acima disso e desenho (metal/brilho), nao fundo.
  final lumMax = args.length > 1 ? double.parse(args[1]) : 60;

  final lums = <double>[];
  var r = 0.0, g = 0.0, b = 0.0;
  var n = 0;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      if (p.a.toInt() <= 250) continue;
      final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
      if (lum > lumMax) continue;
      lums.add(lum);
      r += p.r;
      g += p.g;
      b += p.b;
      n++;
    }
  }

  if (n == 0) {
    stderr.writeln('nenhum pixel de fundo abaixo de lum $lumMax');
    exitCode = 65;
    return;
  }

  lums.sort();
  double pct(double q) => lums[(lums.length * q).clamp(0, lums.length - 1).toInt()];

  String hexOf(int rr, int gg, int bb) =>
      '#${rr.toRadixString(16).padLeft(2, '0')}'
      '${gg.toRadixString(16).padLeft(2, '0')}'
      '${bb.toRadixString(16).padLeft(2, '0')}';

  final mr = (r / n).round(), mg = (g / n).round(), mb = (b / n).round();
  stdout.writeln('pixels de fundo: $n (lum <= $lumMax)');
  stdout.writeln('media  : rgb($mr, $mg, $mb) = ${hexOf(mr, mg, mb)}');
  stdout.writeln('');
  stdout.writeln('percentis de luminancia do fundo:');
  for (final q in <double>[0.05, 0.25, 0.50, 0.75, 0.95]) {
    stdout.writeln('  p${(q * 100).round().toString().padLeft(2)}  ${pct(q).toStringAsFixed(1)}');
  }

  // Cor mediana de verdade: recolhe os pixels cuja luminancia cai perto da
  // mediana e tira a media dos canais deles -- preserva o leve desvio azulado
  // da arte, que uma media global puxada pelos extremos perderia.
  final med = pct(0.50);
  var r2 = 0.0, g2 = 0.0, b2 = 0.0;
  var n2 = 0;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      if (p.a.toInt() <= 250) continue;
      final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
      if ((lum - med).abs() > 2) continue;
      r2 += p.r;
      g2 += p.g;
      b2 += p.b;
      n2++;
    }
  }
  if (n2 > 0) {
    final cr = (r2 / n2).round(), cg = (g2 / n2).round(), cb = (b2 / n2).round();
    stdout.writeln('');
    stdout.writeln(
      'tom mediano: rgb($cr, $cg, $cb) = ${hexOf(cr, cg, cb)}  (n=$n2)',
    );
  }
}
