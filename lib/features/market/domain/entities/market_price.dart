import 'package:equatable/equatable.dart';

/// Um ponto do historico de preco -- so existe quando o provider oferece
/// historico; nunca inferido/interpolado por este app.
class MarketPricePoint extends Equatable {
  const MarketPricePoint({required this.observedAt, required this.price});

  final DateTime observedAt;
  final int price;

  @override
  List<Object?> get props => <Object?>[observedAt, price];
}

/// Preco de mercado de uma carta, como o provider devolveu.
///
/// Todo campo alem de [cardId]/[provider] e opcional de proposito: nenhum
/// provider real e obrigado a oferecer minimo/maximo/historico junto do
/// preco atual, e este app nunca preenche um campo ausente com um valor
/// inventado -- a UI esconde o que faltar, igual PlayerCardDataFace faz para
/// stats de carta ausentes.
class MarketPrice extends Equatable {
  const MarketPrice({
    required this.cardId,
    required this.provider,
    required this.updatedAt,
    this.platform,
    this.currentPrice,
    this.minPrice,
    this.maxPrice,
    this.history = const <MarketPricePoint>[],
  });

  final String cardId;

  /// Origem do dado (ex.: futuro 'FUTNEXT') -- mesmo padrao de
  /// PlayerCard.provider: nada acima desta camada deve depender de qual.
  final String provider;

  /// 'PS', 'XBOX', 'PC' quando o provider separa preco por plataforma. Null
  /// quando o preco e unico independente de plataforma.
  final String? platform;

  final int? currentPrice;
  final int? minPrice;
  final int? maxPrice;
  final DateTime updatedAt;
  final List<MarketPricePoint> history;

  bool get hasHistory => history.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
    cardId,
    provider,
    platform,
    currentPrice,
    minPrice,
    maxPrice,
    updatedAt,
    history,
  ];
}
