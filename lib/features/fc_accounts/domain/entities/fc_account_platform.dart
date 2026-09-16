/// Plataforma que o usuario joga com este elenco. Catalogo por CHECK no
/// banco (mesmo padrao de RivalsDivision), nao enum Postgres.
///
/// [key] e o valor persistido (PC/PS/XBOX) -- nunca muda, e o que o CHECK
/// do banco valida. [displayLabel] e so pra UI (PlayStation/Xbox leem melhor
/// que as siglas cruas) -- marcas, nao precisam de traducao por idioma.
enum FcAccountPlatform {
  pc('PC', 'PC'),
  ps('PS', 'PlayStation'),
  xbox('XBOX', 'Xbox');

  const FcAccountPlatform(this.key, this.displayLabel);

  final String key;
  final String displayLabel;

  static FcAccountPlatform? tryFromKey(Object? key) {
    for (final platform in FcAccountPlatform.values) {
      if (platform.key == key) {
        return platform;
      }
    }
    return null;
  }
}
