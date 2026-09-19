// Gera derivados tecnicos dos assets oficiais (logo_sem_fundo.png,
// logo_escrita.png, logo_splash.png -- marca "Match Queue" / MQ) SEM
// alterar os originais em design/brand/. Rodar da raiz do projeto com:
//   dart run design/brand/generate_derivatives.dart
//
// - assets/brand/            -> imagens exibidas em runtime pelo app (Image.asset)
// - design/brand/generated/  -> fontes usadas so em build-time pelos geradores de
//                              icon/splash (flutter_launcher_icons /
//                              flutter_native_splash); nao entram no bundle.
//
// So faz resize/pad/crop-por-alpha sobre as artes originais -- nunca recorta
// conteudo, redesenha ou distorce o desenho.
//
// Porta em Dart do antigo generate_derivatives.py (removido): este projeto
// ja depende do Dart/Flutter SDK pra tudo, entao usar Python so pra esse
// script era uma dependencia extra sem necessidade.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const String _iconArtName =
    'logo_icon.png'; // icone PRONTO: quadrado arredondado preto + marca MQ

// Fundo real da arte de icone, medido nela (nao escolhido no olho): e a cor
// que o quadrado arredondado ja tem. Preencher a volta com exatamente esse
// tom faz a borda arredondada da arte sumir dentro do canvas, que e o que
// permite tratar uma arte JA arredondada como se fosse sangria total.
const List<int> _iconArtBg = [0x13, 0x15, 0x16];

late final String _brandDir;
late final String _assetsDir;
late final String _generatedDir;

img.Image _decode(String path) {
  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    throw StateError('Nao consegui decodificar $path como PNG.');
  }
  return decoded;
}

/// Compoe `src` (RGBA) sobre um fundo solido `bgColor`, nunca um flatten
/// ingenuo (que manteria qualquer RGB "por baixo" de um pixel transparente
/// -- as margens transparentes da arte original nao tem cor de fundo
/// confiavel por baixo).
img.Image _compositeOnColor(img.Image src, List<int> bgColor) {
  final bg = img.Image(width: src.width, height: src.height, numChannels: 3);
  img.fill(bg, color: img.ColorRgb8(bgColor[0], bgColor[1], bgColor[2]));
  img.compositeImage(bg, src);
  return bg;
}

/// Mesma fonte, alpha mantido intacto -- para derivados que precisam
/// continuar transparentes (ex.: foreground do icone adaptativo Android).
img.Image _loadRgba(String name) => _decode('$_brandDir/$name');

/// Redimensiona `im` (mantendo proporcao) ate sua largura virar
/// aproximadamente `contentFraction` de `canvasSize`, depois centraliza num
/// canvas canvasSize x canvasSize preenchido com `bgColor`. Nunca recorta ou
/// redesenha -- so escala a imagem inteira e adiciona a margem
/// correspondente. contentFraction > 1 estoura de proposito pra fora da
/// borda do canvas (sangria total) em vez de deixar margem, ja que e um
/// icone e o SO mascara/recorta de qualquer jeito.
/// Mesma ideia de [_padToSquare], mas o que sobra fica TRANSPARENTE em vez
/// de preenchido: quem pinta o fundo e o consumidor (flutter_native_splash
/// pinta a cor configurada por baixo). Com fundo transparente a arte
/// funciona sobre qualquer cor, sem a emenda que uma arte achatada cria.
/// Dissolve a borda do PLACAR da arte: o alpha vai a zero exatamente na
/// borda do quadrado arredondado e sobe ate 1 a [fadeDepth] pixels dali pra
/// dentro. A arte termina, entao, na propria textura dela, sem contorno.
///
/// Analitico, nao por desfoque de mascara. A arte chega recortada no
/// quadrado opaco, ou seja, o placar preenche o canvas inteiro e nao sobra
/// margem transparente pra uma mascara desfocada descer -- tentei assim
/// primeiro e o alpha parava em 197 na borda, deixando o contorno de pe.
/// Aqui a distancia ate a borda sai da equacao do retangulo arredondado
/// (SDF), entao a rampa comeca cravada em zero.
///
/// Resolve duas medidas, as duas de tool/inspect_icon_edge.dart e
/// tool/inspect_icon_base.dart:
///   1. o aro de brilho da borda (lum 69 contra 15 da base, ~4,5x), que
///      desenha o contorno mesmo com a cor de fundo casada;
///   2. a vinheta propria do placar, que deixa os cantos mais escuros que o
///      miolo -- por isso nenhuma cor chapada some com o retangulo.
///
/// [radiusFraction] e o raio dos cantos como fracao do lado (0.218 medido
/// nesta arte).
img.Image _dissolvePlateEdge(
  img.Image src, {
  required double radiusFraction,
  required double fadeDepth,
}) {
  final w = src.width;
  final h = src.height;
  final halfW = w / 2;
  final halfH = h / 2;
  final radius = radiusFraction * (w < h ? w : h);

  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);

      // SDF do retangulo arredondado centrado: negativo dentro.
      final qx = (x + 0.5 - halfW).abs() - halfW + radius;
      final qy = (y + 0.5 - halfH).abs() - halfH + radius;
      final outsideX = qx > 0 ? qx : 0.0;
      final outsideY = qy > 0 ? qy : 0.0;
      final maxQ = qx > qy ? qx : qy;
      final signed =
          (maxQ < 0 ? maxQ : 0.0) +
          _hypot(outsideX, outsideY) -
          radius;
      final inside = -signed;

      // smoothstep de 0 ate fadeDepth: rampa em S, sem quina no comeco nem
      // no fim, que e o que faz a transicao nao ter "linha".
      var t = inside / fadeDepth;
      if (t <= 0) {
        t = 0;
      } else if (t >= 1) {
        t = 1;
      } else {
        t = t * t * (3 - 2 * t);
      }

      final a = (p.a.toInt() * t).round().clamp(0, 255);
      out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
    }
  }
  return out;
}

double _hypot(double a, double b) {
  if (a == 0 && b == 0) return 0;
  return math.sqrt(a * a + b * b);
}

img.Image _padToSquareTransparent(
  img.Image imRgba,
  int canvasSize,
  double contentFraction,
) {
  final scale = (canvasSize * contentFraction) / imRgba.width;
  final resized = img.copyResize(
    imRgba,
    width: (imRgba.width * scale).round(),
    height: (imRgba.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  img.compositeImage(
    canvas,
    resized,
    dstX: (canvasSize - resized.width) ~/ 2,
    dstY: (canvasSize - resized.height) ~/ 2,
  );
  return canvas;
}

img.Image _padToSquare(
  img.Image im,
  int canvasSize,
  double contentFraction,
  List<int> bgColor,
) {
  final scale = (canvasSize * contentFraction) / im.width;
  final newW = (im.width * scale).round();
  final newH = (im.height * scale).round();
  final resized = img.copyResize(
    im,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 3,
  );
  img.fill(canvas, color: img.ColorRgb8(bgColor[0], bgColor[1], bgColor[2]));
  final offsetX = (canvasSize - newW) ~/ 2;
  final offsetY = (canvasSize - newH) ~/ 2;
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);
  return canvas;
}


/// Recorta pro bounding box do conteudo visivel (alpha > limiar) + padding,
/// sem alterar nenhum pixel.
/// Recorta ao retangulo OPACO -- diferente de [_cropToAlphaBbox], que inclui
/// tudo que tem qualquer alpha. A arte de icone vem com sombra projetada em
/// volta do quadrado; manter a sombra deixaria uma auréola escura dentro do
/// icone depois que a plataforma aplicar a propria mascara.
img.Image _cropToOpaqueBbox(img.Image imRgba) {
  var minX = imRgba.width, minY = imRgba.height, maxX = -1, maxY = -1;
  for (var y = 0; y < imRgba.height; y++) {
    for (var x = 0; x < imRgba.width; x++) {
      if (imRgba.getPixel(x, y).a > 250) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX) return imRgba;
  return img.copyCrop(
    imRgba,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}


void _savePng(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
}

void main() {
  final scriptPath = File.fromUri(Platform.script).absolute.path;
  _brandDir = File(scriptPath).parent.path;
  final designDir = Directory(_brandDir).parent.path;
  final projectRoot = Directory(designDir).parent.path;
  _assetsDir = '$projectRoot/assets/brand';
  _generatedDir = '$_brandDir/generated';

  Directory(_assetsDir).createSync(recursive: true);
  Directory(_generatedDir).createSync(recursive: true);

  // logo_icon.png ja E um icone pronto: quadrado arredondado, fundo preto
  // texturizado, marca MQ e sombra projetada em volta. O recorte pelo opaco
  // joga a sombra fora e deixa so o quadrado -- e ele alimenta TODOS os
  // derivados de icone (runtime e build-time) daqui pra baixo.
  final iconArtRgba = _cropToOpaqueBbox(_loadRgba(_iconArtName));

  // ---- Runtime assets (bundled via pubspec assets:) ----

  // Marca usada inline pelo BrandMark (nav rail, splash widget, telas de
  // auth). TRANSPARENCIA PRESERVADA de proposito: a arte ja tem cantos
  // arredondados proprios, entao os cantos precisam ficar vazados pra ela
  // assentar em qualquer superficie. A arte anterior era um simbolo com
  // alpha achatado sobre BRANCO, e por isso o BrandMark precisava embrulhar
  // tudo num ClipRRect com borda -- sem isso aparecia um quadrado branco cru
  // sobre fundo escuro. Com o badge novo esse embrulho vira um segundo
  // arredondamento por cima do da arte, entao ele saiu de la.
  //
  // 512 basta pra qualquer uso ate ~170dp numa tela 3x.
  _savePng(
    '$_assetsDir/icon.png',
    img.copyResize(
      iconArtRgba,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    ),
  );

  // Sem wordmark.png: a arte "MATCH QUEUE" cromada verde saiu do app junto
  // com o rebrand do icone, e nao ha versao nova dela. As telas de auth usam
  // MatchQueueWordmark (desenhado em codigo); splash, onboarding e o rail de
  // navegacao passaram a mostrar so o badge. logo_escrita.png continua em
  // design/brand/ como arte historica, mas nao vira asset do bundle.

  // Sem splash.png separado: BrandAssets.splashMark e null de proposito (ver
  // seu doc comment) -- SplashPage compoe icon + wordmark ao vivo a partir
  // de assets/brand/icon.png e assets/brand/wordmark.png.

  // ---- Build-time-only sources (flutter_launcher_icons / flutter_native_splash) ----

  // Fonte geral do icone do app (iOS + Android legado + favicon/PWA web).
  //
  // iOS aplica a propria mascara arredondada e ESPERA uma arte de sangria
  // total, sem transparencia. A arte ja vem arredondada, entao o recorte
  // acima joga fora a sombra e deixa o quadrado encostando nas 4 bordas do
  // canvas: os cantos do canvas caem dentro do raio da arte, onde ela e
  // transparente, e sao preenchidos com _iconArtBg -- a mesma cor do fundo
  // dela.
  //
  // Sem sangria (1.0), de proposito. O arredondamento da arte mede 21,8% do
  // lado e a mascara do iOS usa ~22,4% (medido com
  // tool/inspect_icon_art.dart): a mascara corta POR FORA do aro da arte,
  // entao ele desaparece sozinho -- nao ha arco duplo pra esconder. Sangrar
  // aqui so recortava a arte fora de centro, porque o quadrado opaco nao e
  // exatamente quadrado (1123x1111) e a escala de _padToSquare e pela
  // largura.
  final iconGeneralSource = _compositeOnColor(iconArtRgba, _iconArtBg);
  final iconGeneral = _padToSquare(iconGeneralSource, 1024, 1.0, _iconArtBg);
  _savePng('$_generatedDir/icon_general_1024.png', iconGeneral);

  // Foreground do icone adaptativo Android.
  //
  // OPACO de sangria total, nao transparente: a arte nova nao e uma marca
  // solta sobre fundo, e um icone inteiro. Separar a marca do fundo exigiria
  // recortar o metal do preto, e o metal tem sombra escura propria no bisel
  // -- qualquer recorte por luminancia comeria parte do desenho. Preenchendo
  // a volta com _iconArtBg, a camada de baixo (adaptive_icon_background)
  // nunca aparece e o launcher recorta a forma dele de um quadrado cheio,
  // sem borda.
  //
  // A "safe zone" garantida do Android e um CIRCULO de 66dp inscrito no
  // canvas de 108dp -- 61,1% do lado. O que precisa caber nesse circulo e a
  // DIAGONAL da caixa da marca, nao a largura dela: o MQ e uma caixa larga
  // e baixa, e sao as pontas (o bico do M, a perna do Q) que encostam no
  // corte primeiro. Medido com tool/inspect_icon_art.dart (densidade de
  // pixels claros, ignorando 8% de borda pra nao contar o aro de brilho da
  // arte): a marca e 76,3% x 43,3% do quadrado opaco, diagonal 87,7%.
  //
  //   0,611 / 0,877 = 0,70
  //
  // Por isso 0.70 e nao um numero redondo escolhido no olho. Conferido com
  // tool/preview_adaptive_icon.dart, que recorta o circulo de verdade --
  // em 0.85 as pontas do M cruzavam a linha.
  final iconAdaptiveFg = _padToSquare(
    _compositeOnColor(iconArtRgba, _iconArtBg),
    1024,
    0.70,
    _iconArtBg,
  );
  _savePng('$_generatedDir/icon_adaptive_fg_1024.png', iconAdaptiveFg);

  // ---- Splash (nativa e a primeira tela Flutter) ----
  //
  // A MESMA arte do icone, so que com a borda dissolvida: na splash o badge
  // aparece sobre uma cor chapada, e o aro de brilho da arte desenhava um
  // quadrado visivel "colado" no fundo. Ver _featherEdges pro numero medido.
  //
  // 135px de queda num placar de 1123px de lado: dissolve os 12% externos.
  // Cobre com folga o aro (~6px) e a vinheta dos cantos, que e o que fazia o
  // retangulo aparecer mesmo com a cor casada.
  //
  // O teto e 133px, a distancia entre a borda do placar e a marca (ela ocupa
  // 76,3% da largura, medido). Em 135 a marca comeca com alpha 99,9%: a
  // queda morre antes de encostar no desenho. Em 190 ela chegaria a 78% e
  // estaria apagando a ponta do M -- por isso o numero nao e arbitrario.
  final splashMarkArt = _dissolvePlateEdge(
    iconArtRgba,
    radiusFraction: 0.218,
    fadeDepth: 135,
  );

  // Asset de runtime: a SplashPage do Flutter desenha ESTE arquivo, nao o
  // assets/brand/icon.png. Os dois tem que ser diferentes de proposito -- o
  // icone precisa da borda nitida (e o que o launcher mascara), a splash
  // precisa dela dissolvida.
  _savePng(
    '$_assetsDir/splash_mark.png',
    img.copyResize(
      splashMarkArt,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    ),
  );

  // Fonte da splash nativa. 0.70 no lugar de 0.62: a marca ficava pequena
  // demais pro espaco, com muita area vazia em volta. O canvas de 1024 e
  // renderizado a 256dp em toda densidade, entao 0.70 poe o badge a ~179dp
  // -- o mesmo alvo que a SplashPage do Flutter mira, pra nao haver salto de
  // tamanho quando o Flutter assume.
  final splashSource = _padToSquareTransparent(splashMarkArt, 1024, 0.70);
  _savePng('$_generatedDir/splash_source_1024.png', splashSource);

  stdout.writeln('Generated:');
  for (final f
      in Directory(_assetsDir).listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path))) {
    stdout.writeln(' assets/brand/${f.uri.pathSegments.last}');
  }
  for (final f
      in Directory(_generatedDir).listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path))) {
    stdout.writeln(' design/brand/generated/${f.uri.pathSegments.last}');
  }
}
