// Os campos abaixo sao String? de proposito, nao String -- BrandMark e
// BrandWordmark tem um fallback (monograma/texto) para quando um asset
// nao existe, e o objetivo e continuar suportando isso (outro flavor,
// white-label futuro etc.), mesmo com os quatro preenchidos hoje.
// ignore_for_file: unnecessary_nullable_for_final_variable_declarations
class BrandAssets {
  const BrandAssets._();

  static const String productName = 'FIFA Queue';
  static const String monogram = 'FQ';

  /// Marca do controle -- usada dentro do app (nav, splash widget, auth
  /// forms) pelo BrandMark. Mesma arte do app icon nativo, so que num
  /// tamanho leve para exibicao em runtime (ver assets/brand/icon.png).
  static const String? logo = 'assets/brand/icon.png';

  /// Wordmark "FIFA QUEUE" isolado, sem o controle.
  static const String? wordmark = 'assets/brand/wordmark.png';

  /// Mesma arte do [logo]; existe como campo separado para o dia em que o
  /// icone do app precisar divergir da marca usada dentro do app.
  static const String? appIcon = 'assets/brand/icon.png';

  /// Lockup controle + wordmark, usado pela SplashPage (a splash do proprio
  /// Flutter, nao a nativa -- essa vive em android/ e ios/, geradas via
  /// flutter_native_splash a partir de design/brand/generated/).
  static const String? splashMark = 'assets/brand/splash.png';

  static bool get hasLogo => logo != null;

  static bool get hasWordmark => wordmark != null;

  static bool get hasSplashMark => splashMark != null;
}
