/// Catálogo por CHECK no banco, não enum Postgres -- se a FC 27 mudar o
/// número de divisões, isso muda aqui e no CHECK, nunca um ALTER TYPE.
enum RivalsDivision {
  div10('DIV_10'),
  div9('DIV_9'),
  div8('DIV_8'),
  div7('DIV_7'),
  div6('DIV_6'),
  div5('DIV_5'),
  div4('DIV_4'),
  div3('DIV_3'),
  div2('DIV_2'),
  div1('DIV_1'),
  elite('ELITE');

  const RivalsDivision(this.key);

  final String key;

  static RivalsDivision? tryFromKey(Object? key) {
    for (final division in RivalsDivision.values) {
      if (division.key == key) {
        return division;
      }
    }
    return null;
  }
}
