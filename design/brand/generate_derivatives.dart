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

const List<int> _white = [255, 255, 255];

// Mesmo tom de fundo escuro do proprio app (AppColors.darkBackground) -- nao
// um verde generico: e o pixel real que o app pinta atras de tudo no tema
// escuro, entao a moldura do icone bate com a marca de verdade em vez de so
// "parecer verde".
const List<int> _iconDarkBg = [0x08, 0x0A, 0x09];

const String _logoName =
    'logo_sem_fundo.png'; // squircle badge "MQ", transparente
const String _escritoName =
    'logo_escrita.png'; // wordmark "MATCH QUEUE", ja transparente
const String _splashName =
    'logo_splash.png'; // splash pronta, ja achatada em fundo preto solido

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

/// RGBA source alpha-composited sobre bgColor, nunca um flatten ingenuo (que
/// manteria qualquer RGB "por baixo" de um pixel transparente -- as margens
/// transparentes da arte original nao tem cor de fundo confiavel por baixo).
img.Image _loadOn(String name, List<int> bgColor) {
  final src = _decode('$_brandDir/$name');
  final bg = img.Image(width: src.width, height: src.height, numChannels: 3);
  img.fill(bg, color: img.ColorRgb8(bgColor[0], bgColor[1], bgColor[2]));
  img.compositeImage(bg, src);
  return bg;
}

/// Variante com fundo branco -- para o uso "white-card" do BrandMark (ver
/// doc comment do proprio BrandMark).
img.Image _load(String name) => _loadOn(name, _white);

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

/// Mesmo resize-e-centraliza de [_padToSquare], mas sobre um canvas
/// totalmente transparente -- para splash nativa, que pinta a propria cor de
/// fundo por baixo (color/color_dark no pubspec.yaml) e mostraria uma borda
/// visivel em volta de qualquer preenchimento solido que a gente adicionasse.
img.Image _padToSquareTransparent(
  img.Image imRgba,
  int canvasSize,
  double contentFraction,
) {
  final scale = (canvasSize * contentFraction) / imRgba.width;
  final newW = (imRgba.width * scale).round();
  final newH = (imRgba.height * scale).round();
  final resized = img.copyResize(
    imRgba,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.cubic,
  );
  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  final offsetX = (canvasSize - newW) ~/ 2;
  final offsetY = (canvasSize - newH) ~/ 2;
  img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);
  return canvas;
}

/// Recorta pro bounding box do conteudo visivel (alpha > limiar) + padding,
/// sem alterar nenhum pixel.
img.Image _cropToAlphaBbox(img.Image imRgba, {int padding = 15}) {
  int minX = imRgba.width, minY = imRgba.height, maxX = 0, maxY = 0;
  var found = false;
  for (var y = 0; y < imRgba.height; y++) {
    for (var x = 0; x < imRgba.width; x++) {
      if (imRgba.getPixel(x, y).a > 20) {
        found = true;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (!found) return imRgba;
  final x0 = (minX - padding).clamp(0, imRgba.width);
  final y0 = (minY - padding).clamp(0, imRgba.height);
  final x1 = (maxX + padding + 1).clamp(0, imRgba.width);
  final y1 = (maxY + padding + 1).clamp(0, imRgba.height);
  return img.copyCrop(imRgba, x: x0, y: y0, width: x1 - x0, height: y1 - y0);
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

  final escritoRgba = _loadRgba(_escritoName);
  final logo = _load(_logoName);
  final logoRgba = _loadRgba(_logoName);

  // ---- Runtime assets (bundled via pubspec assets:) ----

  // Icon mark usado inline pelo BrandMark (nav rail, splash widget, forms de
  // auth). logo_sem_fundo.png e um badge squircle com uma margem
  // transparente pequena em volta; _load() compoe isso sobre branco pro uso
  // "white-card" (ver doc comment do proprio BrandMark). Reduzir pra 512 e
  // mais que suficiente pra qualquer uso ate ~170dp numa tela 3x.
  _savePng(
    '$_assetsDir/icon.png',
    img.copyResize(
      logo,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    ),
  );

  // Wordmark: logo_escrita.png ja chega com transparencia real -- so falta
  // recortar a margem transparente sobrando e reduzir pro tamanho de uso
  // real. O maior uso no app e BrandWordmark(height: 76) -- a ~228px em 3x
  // DPR; reduzir pra ~3x esse uso aqui (build-time) evita que o Flutter
  // reamostre por um fator grande a cada frame e esborre os tracos finos.
  final escritoCropped = _cropToAlphaBbox(escritoRgba);
  const targetH = 260;
  final wordmarkScale = targetH / escritoCropped.height;
  final wordmark = img.copyResize(
    escritoCropped,
    width: (escritoCropped.width * wordmarkScale).round(),
    height: targetH,
    interpolation: img.Interpolation.cubic,
  );
  _savePng('$_assetsDir/wordmark.png', wordmark);

  // Sem splash.png separado: BrandAssets.splashMark e null de proposito (ver
  // seu doc comment) -- SplashPage compoe icon + wordmark ao vivo a partir
  // de assets/brand/icon.png e assets/brand/wordmark.png.

  // ---- Build-time-only sources (flutter_launcher_icons / flutter_native_splash) ----

  // Fonte geral do icone do app (iOS + Android legado + favicon/PWA web).
  // iOS mascara/arredonda isso sozinho (nunca arredondar aqui) e nao mostra
  // nenhuma cor de fundo fora da mascara, entao uma margem solida atras do
  // badge apareceria como uma borda indesejada -- a margem propria de
  // logo_sem_fundo.png e cortada estourando levemente pra fora da borda do
  // canvas (sangria total) em vez de mantida como padding visivel.
  final iconGeneralSource = _loadOn(_logoName, _iconDarkBg);
  final iconGeneral = _padToSquare(iconGeneralSource, 1024, 1.08, _iconDarkBg);
  _savePng('$_generatedDir/icon_general_1024.png', iconGeneral);

  // Foreground do icone adaptativo Android: TRANSPARENTE fora do desenho (o
  // fundo escuro vem de adaptive_icon_background no pubspec.yaml, uma camada
  // separada que o Android compoe atras desta -- preencher aqui seria um
  // segundo fundo redundante). adaptive_icon_foreground_inset e 0 no
  // pubspec.yaml, entao esse contentFraction e o UNICO controle de tamanho.
  // A "safe zone" garantida do Android e um CIRCULO de 66dp inscrito no
  // canvas de 108dp (~61% do lado, nao 66% -- um bounding box quadrado de
  // 66% de lado tem cantos que estouram esse circulo). logo_sem_fundo.png e
  // um anel que quase toca a propria borda do bounding box nos 4 pontos
  // cardeais, entao com contentFraction 0.66 esse anel ficava colado bem em
  // cima da linha de corte do launcher -- lia como um risco/halo feio
  // grudado na borda do icone em vez de um anel limpo. 0.55 dava folga real
  // mas o anel ficava pequeno demais pra ler em 48dp (tamanho real na tela
  // inicial); 0.62 e o meio-termo aceito -- ainda mais legivel que 0.55, com
  // menos folga do que isso mas sem colar na borda como o 0.66 original.
  // Resolve o tamanho, nao a legibilidade do traco fino em si -- isso exige
  // arte nova (ver historico do rebrand).
  final iconAdaptiveFg = _padToSquareTransparent(logoRgba, 1024, 0.62);
  _savePng('$_generatedDir/icon_adaptive_fg_1024.png', iconAdaptiveFg);

  // Fonte da splash nativa: logo_splash.png e uma arte pronta, ja achatada
  // sobre fundo preto solido (ao contrario do resto -- nao e derivada do
  // badge transparente aqui). Por isso NAO usa _padToSquareTransparent (que
  // exige fundo transparente pro flutter_native_splash pintar por baixo): so
  // redimensiona pro tamanho final. flutter_native_splash.color/color_dark
  // no pubspec.yaml precisam bater com o preto solido desta arte
  // (#000000), senao aparece uma borda visivel entre a imagem e o fundo da
  // splash nativa.
  final splashSource = _decode('$_brandDir/$_splashName');
  final splashResized = img.copyResize(
    splashSource,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.cubic,
  );
  _savePng('$_generatedDir/splash_source_1024.png', splashResized);

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
