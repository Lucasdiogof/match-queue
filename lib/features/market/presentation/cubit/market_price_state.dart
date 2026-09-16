import 'package:equatable/equatable.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';

enum MarketPriceStatus { loading, available, unavailable, failure }

class MarketPriceState extends Equatable {
  const MarketPriceState({
    this.status = MarketPriceStatus.loading,
    this.price,
    this.failure,
  });

  final MarketPriceStatus status;
  final MarketPrice? price;
  final AppFailure? failure;

  MarketPriceState copyWith({
    MarketPriceStatus? status,
    MarketPrice? price,
    AppFailure? failure,
  }) => MarketPriceState(
    status: status ?? this.status,
    price: price ?? this.price,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => <Object?>[status, price, failure];
}
