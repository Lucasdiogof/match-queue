/// Plataforma que o usuario joga. Catalogo por CHECK no banco (mesmo padrao
/// de RivalsDivision), nao enum Postgres.
///
/// [key] e o valor persistido (PC/PS/XBOX) -- nunca muda, e o que o CHECK do
/// banco valida. [displayLabel] e so pra UI (PlayStation/Xbox leem melhor
/// que as siglas cruas) -- marcas, nao precisam de traducao por idioma.
enum Platform {
  pc('PC', 'PC'),
  ps('PS', 'PlayStation'),
  xbox('XBOX', 'Xbox');

  const Platform(this.key, this.displayLabel);

  final String key;
  final String displayLabel;

  static Platform? tryFromKey(Object? key) {
    for (final platform in Platform.values) {
      if (platform.key == key) {
        return platform;
      }
    }
    return null;
  }
}
