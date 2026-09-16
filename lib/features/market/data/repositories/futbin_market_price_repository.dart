import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Preco de mercado real via Futbin, atras da Edge Function
/// `fetch-market-price-futbin` -- o app nunca fala com o Parse.bot direto,
/// e a chave paga deles nunca sai da function.
///
/// Preco "0" e devolvido tal qual, sem virar `null`: decisao explicita do
/// produto (o mercado do FC 27 ainda nao abriu em nenhuma fonte quando esta
/// classe foi escrita -- ver commit -- e 0 e o sinal documentado disso, nao
/// um valor a esconder). So vira `null` quando a carta nem foi encontrada no
/// Futbin.
///
/// Cada chamada custa credito de verdade (Parse.bot) -- a function cacheia
/// por 1h em `market_price_cache` antes de bater na API, entao chamar
/// este metodo de novo pra mesma carta/plataforma dentro da janela nao
/// gasta credito adicional.
class FutbinMarketPriceRepository implements MarketPriceRepository {
  const FutbinMarketPriceRepository(this._client);

  static const String _functionName = 'fetch-market-price-futbin';
  static const String _provider = 'FUTBIN';

  final SupabaseClient _client;

  @override
  Future<MarketPrice?> getPrice(PlayerCard card, {String? platform}) async {
    try {
      final response = await _client.functions.invoke(
        _functionName,
        body: <String, dynamic>{'cardId': card.id, 'platform': ?platform},
      );
      final body = response.data;
      if (response.status != 200 || body is! Map) {
        return null;
      }
      final priceData = body['price'];
      if (priceData is! Map) {
        return null;
      }
      final currentPrice = priceData['currentPrice'] as int?;
      final updatedAtMs = priceData['updatedAt'] as int?;
      if (currentPrice == null || updatedAtMs == null) {
        return null;
      }
      return MarketPrice(
        cardId: card.id,
        provider: _provider,
        platform: priceData['platform'] as String?,
        currentPrice: currentPrice,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      );
    } catch (_) {
      return null;
    }
  }
}
