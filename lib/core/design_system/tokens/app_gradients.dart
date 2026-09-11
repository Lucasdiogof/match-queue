import 'package:fifa_queue/core/design_system/tokens/app_colors.dart';
import 'package:flutter/widgets.dart';

/// Gradientes do produto, centralizados.
///
/// Gradiente aqui e DESTAQUE, nao fundo universal: estado ativo, hero de
/// modo competitivo, badge especial, strip fina. Se todo card tiver
/// gradiente, nenhum se destaca -- e o app vira exatamente o template
/// generico que a repaginada quer evitar.
///
/// Champions e Rivals nao tem variante clara de proposito. Sao a identidade
/// do modo, nao do tema: um card de Champions e vinho sobre quase preto no
/// claro tambem, porque e assim que ele se separa do resto da tela.
class AppGradients {
  const AppGradients._();

  /// Acento de marca: verde puxando um toque de roxo. Sutil de proposito --
  /// serve para strip/borda/realce, nao para preencher superficie grande.
  static const LinearGradient brandAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[AppColors.fcGreen, AppColors.fcPurple],
  );

  /// CTA e estado ativo de matchmaking.
  static const LinearGradient play = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.fcGreen, AppColors.fcGreenStrong],
  );

  /// Fundo tingido do tema escuro: verde profundo esvaindo para a surface.
  static const LinearGradient darkBrandSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.darkSurfaceGreen, AppColors.darkSurface],
  );

  /// Conteudo/editorial: catalogo, mecanicas, PlayStyles.
  static const LinearGradient darkContentSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.darkSurfacePurple, AppColors.darkSurface],
  );

  static const LinearGradient lightBrandSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.lightSurfaceGreen, AppColors.lightSurface],
  );

  /// Champions: vinho profundo caindo para quase preto. O dourado entra
  /// como borda/texto por cima, nunca dentro do gradiente -- e o que da a
  /// sensacao de metal sobre veludo em vez de um degrade alaranjado.
  static const LinearGradient champions = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.championsWine,
      AppColors.championsWineDark,
      Color(0xFF12100B),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Rivals: mais frio e mais sobrio que Champions, como nas referencias --
  /// carvao para preto, sem vinho nenhum.
  static const LinearGradient rivals = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.rivalsGraphite,
      AppColors.rivalsBlack,
      Color(0xFF070706),
    ],
    stops: <double>[0, 0.6, 1],
  );

  /// Brilho dourado curto, para borda superior de card competitivo.
  static const LinearGradient goldEdge = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[AppColors.goldBright, AppColors.gold, Color(0x00D8B45A)],
  );
}
