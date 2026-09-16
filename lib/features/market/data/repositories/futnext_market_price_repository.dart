import 'package:fifa_queue/features/fc_squads/domain/entities/player_card.dart';
import 'package:fifa_queue/features/market/domain/entities/market_price.dart';
import 'package:fifa_queue/features/market/domain/repositories/market_price_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Preco de mercado real via FUTNext, atras da Edge Function
/// `fetch-market-price` -- o app nunca fala direto com a API deles.
///
/// NAO ESTA CONECTADA HOJE (ver market_module.dart) -- checado em
/// 2026-09-16 direto no site: FUTNext ainda roda em cima do EA FC 26
/// ("FUTNext — EA FC 26..." no title/footer, /fc27 devolve 404), entao o
/// preco que a API deles devolve e do mercado do FC 26, nao do FC 27 --
/// mostrar isso no app seria exibir dado real de uma fonte real, mas do
/// jogo errado, disfarçado de preco atual. FUT.GG e FUTBIN ja migraram pra
/// FC 27 (confirmado no title de cada site), mas os dois continuam
/// bloqueando por Cloudflare a partir do egress da Supabase (probe
/// original); FUTWIZ tambem ainda esta no FC 26. Antes de reconectar esta
/// classe, confirmar de novo que futnext.com fala FC 27 (title/footer, ou
/// um /fc27 que resolva).
///
/// So `currentPrice`/`platform`/`updatedAt` vem preenchidos: o endpoint nao
/// oferece minimo/maximo/historico sem raspar a pagina de jogador
/// renderizada server-side, o que seria scraping improvisado. Qualquer falha
/// (rede, timeout, function fora do ar, carta sem provider_card_id) vira
/// `null` -- nunca propagada como erro, igual UnavailableMarketPriceRepository
/// faz enquanto isto ficar desconectado.
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
