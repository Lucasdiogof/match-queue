import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';

/// Contrato que uma integracao de preco de mercado real precisa cumprir.
///
/// Nada acima desta interface (cubit, UI) sabe qual provider responde, nem
/// se algum responde -- ate uma fonte real ser conectada, `getIt` registra
/// uma implementacao "unavailable" aqui, que sempre devolve `null`. Nunca
/// inventar preco: ausencia de dado real deve sempre chegar como `null`,
/// nunca como um valor mockado.
abstract interface class MarketPriceRepository {
  /// `null` quando nenhum preco esta disponivel para esta carta (provider
  /// nao configurado, carta sem preco na fonte, ou erro tratado como
  /// indisponivel em vez de propagado -- ver doc da implementacao real
  /// quando existir).
  Future<MarketPrice?> getPrice(PlayerCard card, {String? platform});
}
