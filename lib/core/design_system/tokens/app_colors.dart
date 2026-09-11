import 'package:flutter/widgets.dart';

/// Paleta crua do FIFA Queue.
///
/// Regra de leitura, porque a cor aqui carrega SIGNIFICADO e nao decoracao:
///
///   verde   -> acao, atividade, matchmaking, selecao, status positivo
///   roxo    -> conteudo do FC (catalogo, mecanicas), destaque editorial
///   dourado -> competitivo, ranking, premium
///   vinho   -> exclusivo de Champions; NUNCA erro/danger
///
/// Champions e Rivals sao accents CONTEXTUAIS: vivem nos cards do proprio
/// modo e nao tem versao clara/escura, por isso ficam fora do
/// [AppSemanticColors] -- eles nao variam com o tema.
///
/// Os neutros escuros levam um leve desvio para o verde (o azul e sempre o
/// canal mais baixo). Isso e o que tira o app do cinza morto sem pintar
/// nada: a atmosfera vem das superficies, a cor vem so do acento.
class AppColors {
  const AppColors._();

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // ---------------------------------------------------------------- marca

  static const Color fcGreen = Color(0xFF39E27D);
  static const Color fcGreenStrong = Color(0xFF19C967);
  static const Color fcGreenSoft = Color(0xFF8EF0B5);

  /// Verde do CTA no tema claro. Escurecido de #118948 para #0F8043 porque
  /// com branco por cima aquele dava 4.47:1 -- reprovava AA por 0.03.
  static const Color fcGreenDeep = Color(0xFF0F8043);

  static const Color fcPurple = Color(0xFF7C4DFF);
  static const Color fcPurpleStrong = Color(0xFF6237E8);
  static const Color fcPurpleSoft = Color(0xFFB7A0FF);


  // --------------------------------------------------------- competitivo

  static const Color gold = Color(0xFFD8B45A);
  static const Color goldBright = Color(0xFFF1D27A);

  /// Dourado para tema claro: #9E7628 dava 4.14:1 sobre branco.
  static const Color goldDeep = Color(0xFF8F6A24);

  static const Color championsWine = Color(0xFF65151D);
  static const Color championsWineDark = Color(0xFF310B10);
  static const Color championsGold = Color(0xFFDDBA58);

  static const Color rivalsBlack = Color(0xFF11100D);
  static const Color rivalsGraphite = Color(0xFF252319);
  static const Color rivalsGold = Color(0xFFC9A447);

  // ---------------------------------------------------------------- dark

  static const Color darkBackground = Color(0xFF080A09);
  static const Color darkBackgroundRaised = Color(0xFF0C0F0D);

  static const Color darkSurface = Color(0xFF111411);
  static const Color darkSurfaceElevated = Color(0xFF171B18);
  static const Color darkSurfaceHighest = Color(0xFF202521);

  /// Superficies tingidas: containers de acento, sem virar card colorido.
  static const Color darkSurfaceGreen = Color(0xFF102A1C);
  static const Color darkSurfacePurple = Color(0xFF1B1633);
  static const Color darkSurfaceGold = Color(0xFF2A2213);

  static const Color darkBorderSubtle = Color(0xFF252B27);
  static const Color darkBorderStrong = Color(0xFF3A433D);

  static const Color darkTextPrimary = Color(0xFFF7F9F7);
  static const Color darkTextSecondary = Color(0xFFADB5AF);
  static const Color darkTextTertiary = Color(0xFF747D76);

  static const Color darkOverlay = Color(0xC9000000);

  // --------------------------------------------------------------- light

  static const Color lightBackground = Color(0xFFF4F6F4);
  static const Color lightBackgroundRaised = Color(0xFFF8FAF8);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFBFCFB);
  static const Color lightSurfaceHighest = Color(0xFFE9EDEA);

  static const Color lightSurfaceGreen = Color(0xFFE6F6ED);
  static const Color lightSurfacePurple = Color(0xFFEFEBFF);
  static const Color lightSurfaceGold = Color(0xFFF7F0DE);

  static const Color lightBorderSubtle = Color(0xFFDDE3DE);
  static const Color lightBorderStrong = Color(0xFFC4CCC6);

  static const Color lightTextPrimary = Color(0xFF101411);
  static const Color lightTextSecondary = Color(0xFF58615A);
  static const Color lightTextTertiary = Color(0xFF858E87);

  static const Color lightOverlay = Color(0x66000000);

  // ------------------------------------------------------------ semantica

  static const Color darkSuccess = Color(0xFF43DC83);
  static const Color darkWarning = Color(0xFFF0C45B);
  static const Color darkDanger = Color(0xFFFF6464);
  static const Color darkInfo = Color(0xFF9DABFF);

  static const Color lightSuccess = Color(0xFF118948);
  static const Color lightWarning = Color(0xFF9B6A00);
  static const Color lightDanger = Color(0xFFC72D37);
  static const Color lightInfo = Color(0xFF4B55B8);
}
