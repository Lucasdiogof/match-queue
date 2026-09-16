import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';

enum MarketPriceStatus { loading, available, unavailable, failure }

class MarketPriceState extends Equatable {
  const MarketPriceState({
    this.status = MarketPriceStatus.loading,
    this.platform = 'ps',
    this.price,
    this.failure,
  });

  final MarketPriceStatus status;

  /// Plataforma selecionada pelo usuario ('ps' cobre PS/Xbox juntos na
  /// FUTNext, 'pc' e separado) -- controla qual preco [load] busca, nao so
  /// um dado devolvido junto do preco.
  final String platform;
  final MarketPrice? price;
  final AppFailure? failure;

  MarketPriceState copyWith({
    MarketPriceStatus? status,
    String? platform,
    MarketPrice? price,
    AppFailure? failure,
  }) => MarketPriceState(
    status: status ?? this.status,
    platform: platform ?? this.platform,
    price: price ?? this.price,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => <Object?>[status, platform, price, failure];
}
