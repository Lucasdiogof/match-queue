import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:fifa_queue/features/market/presentation/cubit/market_price_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Carrega o preco de UMA carta para o detalhe. `null` do repositorio vira
/// [MarketPriceStatus.unavailable] -- nunca tratado como falha, porque
/// "sem preco" e uma resposta valida (provider nao configurado, ou carta sem
/// preco na fonte), nao um erro.
class MarketPriceCubit extends Cubit<MarketPriceState> {
  MarketPriceCubit(this._repository) : super(const MarketPriceState());

  final MarketPriceRepository _repository;

  Future<void> load(PlayerCard card, {String? platform}) async {
    emit(state.copyWith(status: MarketPriceStatus.loading));
    try {
      final price = await _repository.getPrice(card, platform: platform);
      if (isClosed) {
        return;
      }
      emit(
        MarketPriceState(
          status: price == null
              ? MarketPriceStatus.unavailable
              : MarketPriceStatus.available,
          price: price,
        ),
      );
    } on AppFailure catch (failure) {
      if (!isClosed) {
        emit(
          MarketPriceState(status: MarketPriceStatus.failure, failure: failure),
        );
      }
    }
  }
}
