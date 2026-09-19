// Os campos abaixo sao String? de proposito, nao String -- BrandMark tem um
// fallback (monograma) para quando o asset nao existe, e o objetivo e
// continuar suportando isso (outro flavor, white-label futuro etc.).
// ignore_for_file: unnecessary_nullable_for_final_variable_declarations
class BrandAssets {
  const BrandAssets._();

  static const String productName = 'Match Queue';
  static const String monogram = 'MQ';

  /// Badge "MQ" -- usado dentro do app (nav, splash widget, onboarding)
  /// pelo BrandMark. Mesma arte do icone nativo, so que num tamanho leve
  /// para exibicao em runtime (ver assets/brand/icon.png).
  static const String? logo = 'assets/brand/icon.png';

  /// Mesma arte do [logo]; existe como campo separado para o dia em que o
  /// icone do app precisar divergir da marca usada dentro do app.
  static const String? appIcon = 'assets/brand/icon.png';

  /// Variante da marca para a SPLASH: a mesma arte, com a borda do placar
  /// dissolvida (ver _dissolvePlateEdge em design/brand/generate_derivatives).
  /// Diferente de [logo] de proposito -- o icone precisa da borda nitida,
  /// que e o que o launcher mascara; a splash precisa dela dissolvida, senao
  /// o placar aparece como um quadrado colado sobre a cor de fundo.
  ///
  /// String, nao String?: a splash nao tem fallback de monograma que preste.
  static const String splashMark = 'assets/brand/splash_mark.png';

  static bool get hasLogo => logo != null;
}
