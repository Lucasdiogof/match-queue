import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Preco de mercado real via FUTNext, atras da Edge Function
/// `fetch-market-price` -- o app nunca fala direto com a API deles.
///
/// FUT.GG/FUTBIN/FUTWIZ bloqueiam por Cloudflare (investigado antes desta
/// implementacao). FUTNext responde, mas "enhancer-api.futnext.com" e a API
/// privada do app deles, nao uma API publica documentada: por isso a
/// integracao mora inteira na function, nunca no cliente -- da pra trocar de
/// provider ou desligar sem nova build.
///
/// So `currentPrice`/`platform`/`updatedAt` vem preenchidos: o endpoint nao
/// oferece minimo/maximo/historico sem raspar a pagina de jogador
/// renderizada server-side, o que seria scraping improvisado. Qualquer falha
/// (rede, timeout, function fora do ar, carta sem provider_card_id) vira
/// `null` -- nunca propagada como erro, igual UnavailableMarketPriceRepository
/// fazia antes desta troca.
class FutNextMarketPriceRepository implements MarketPriceRepository {
  const FutNextMarketPriceRepository(this._client);

  static const String _functionName = 'fetch-market-price';
  static const String _provider = 'FUTNEXT';

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
