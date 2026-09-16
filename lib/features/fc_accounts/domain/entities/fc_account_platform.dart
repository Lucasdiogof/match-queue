/// Plataforma que o usuario joga com este elenco. Catalogo por CHECK no
/// banco (mesmo padrao de RivalsDivision), nao enum Postgres.
///
/// Os rotulos (PC/PS/XBOX) sao siglas/marcas -- nao precisam de traducao,
/// mesma logica de nao traduzir "PAC"/"SHO" nos atributos de carta.
enum FcAccountPlatform {
  pc('PC'),
  ps('PS'),
  xbox('XBOX');

  const FcAccountPlatform(this.key);

  final String key;

  static FcAccountPlatform? tryFromKey(Object? key) {
    for (final platform in FcAccountPlatform.values) {
      if (platform.key == key) {
        return platform;
      }
    }
    return null;
  }
}
