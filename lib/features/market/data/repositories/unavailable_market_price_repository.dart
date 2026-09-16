import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';

/// Usado enquanto nenhum provider de preco de mercado real foi conectado.
///
/// Nao finge um preco nem devolve um valor de exemplo -- diz honestamente
/// que o preco esta indisponivel, e a UI mostra isso (nunca um numero
/// inventado). Mesmo padrao de UnavailablePushMessagingService: uma
/// implementacao "desligada" explicita, nao um TODO escondido atras de uma
/// excecao.
///
/// Troca por uma implementacao real (`FutnextMarketPriceRepository` ou
/// equivalente) assim que uma fonte passar pelo probe de reachability E pela
/// checagem de ToS/robots.txt -- ver docs/card_provider_research.md e
/// supabase/functions/probe-market-providers.
class UnavailableMarketPriceRepository implements MarketPriceRepository {
  const UnavailableMarketPriceRepository();

  @override
  Future<MarketPrice?> getPrice(PlayerCard card, {String? platform}) async =>
      null;
}
