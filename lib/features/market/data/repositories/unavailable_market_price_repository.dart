import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';

/// Usado enquanto nenhuma fonte de preco de mercado real e VALIDA pra FC 27
/// esta conectada.
///
/// FutNextMarketPriceRepository ja existe e funciona, mas fica desligada
/// (ver market_module.dart): em 2026-09-16 a FUTNext ainda respondia com
/// dados do FC 26, nao do FC 27 -- reconectar aquela implementacao mostraria
/// preco real de uma fonte real, mas do jogo errado, como se fosse o preco
/// atual. Isso e pior que "indisponivel": e dado errado com cara de certo.
///
/// Nao finge um preco nem devolve um valor de exemplo -- diz honestamente
/// que o preco esta indisponivel, e a UI mostra isso (nunca um numero
/// inventado). Mesmo padrao de UnavailablePushMessagingService: uma
/// implementacao "desligada" explicita, nao um TODO escondido atras de uma
/// excecao.
class UnavailableMarketPriceRepository implements MarketPriceRepository {
  const UnavailableMarketPriceRepository();

  @override
  Future<MarketPrice?> getPrice(PlayerCard card, {String? platform}) async =>
      null;
}
