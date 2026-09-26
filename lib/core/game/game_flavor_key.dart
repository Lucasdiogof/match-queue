/// Identifica qual jogo esta build do Match Queue representa. V1: apenas
/// EA FC existe de verdade -- os demais ficam aqui só como destino conhecido
/// para quando o flavor correspondente for criado (Supabase + build próprios).
enum GameFlavorKey {
  eaFc('ea_fc'),
  efootball('efootball'),
  ufl('ufl'),
  goals('goals');

  const GameFlavorKey(this.key);

  final String key;

  static GameFlavorKey? tryFromKey(String key) {
    for (final value in GameFlavorKey.values) {
      if (value.key == key) {
        return value;
      }
    }
    return null;
  }
}
