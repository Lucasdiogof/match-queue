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

  // Fonte da splash nativa: a MESMA arte do icone, com a transparencia
  // dela preservada (sem _compositeOnColor). E o que permite a splash usar
  // uma cor de fundo qualquer sem emenda -- flutter_native_splash pinta a
  // cor por baixo e o badge assenta em cima.
  //
  // Antes daqui saia logo_splash.png, arte achatada sobre #000000 puro. Com
  // fundo achatado a cor da splash e obrigada a ser exatamente o preto da
  // arte, senao aparece um quadrado visivel em volta dela -- e essa arte
  // ainda era a marca verde antiga, de antes do rebrand do icone.
  //
  // 0.62 deixa o badge ocupando pouco mais da metade da largura: numa tela
  // de celular a splash e retrato, entao a largura e o lado curto e o badge
  // precisa caber nela com folga.
  final splashSource = _padToSquareTransparent(iconArtRgba, 1024, 0.62);
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
