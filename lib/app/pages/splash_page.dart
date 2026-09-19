import 'package:fifa_queue/core/design_system/branding/brand_assets.dart';
import 'package:fifa_queue/core/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Primeira tela que o Flutter desenha, imediatamente depois da splash
/// nativa. Presa a [AppColors.splashBackground], nunca a ThemeMode: se
/// seguisse o tema, quem estivesse em claro veria a splash nativa escura
/// virar branca de repente assim que o Flutter assume -- exatamente o flash
/// que a splash nativa existe pra evitar.
///
/// A arte aqui e a MESMA do `image` do flutter_native_splash, no mesmo
/// tamanho relativo (ver [_markFraction]), entao a troca de uma pela outra
/// nao muda nem cor nem escala: visualmente e um quadro so.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  /// Fracao do lado MENOR da tela ocupada pela marca. Espelha o 0.70 que a
  /// splash nativa usa sobre um canvas renderizado a 256dp, ou seja ~179dp
  /// num celular comum -- e o que faz a passagem da nativa pra esta nao ter
  /// salto de tamanho.
  static const double _markFraction = 0.44;

  /// Limites pra fracao nao virar marca minuscula num celular pequeno nem
  /// marca gigante num tablet.
  static const double _markMin = 150;
  static const double _markMax = 220;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest = size.width < size.height ? size.width : size.height;
    final side = (shortest * _markFraction).clamp(_markMin, _markMax);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Barras na cor da propria tela, com icones claros: sem isso o Android
      // pinta a navigation bar com o padrao do sistema e aparece uma faixa de
      // outro tom embaixo da splash.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: AppColors.splashBackground,
        child: Center(
          child: Image.asset(
            BrandAssets.splashMark,
            width: side,
            height: side,
            // A arte ja termina dissolvida na cor de fundo; filtrar com
            // qualidade alta evita serrilhado no degrade quando ela e
            // reduzida do PNG de 512 pro tamanho real.
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
