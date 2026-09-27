// Plataformas de preco que o app pede ('ps' cobre PS/Xbox; 'pc' separado).
// Qualquer outro valor vira 'ps': `platform` entra na URL do provider e na
// chave do cache pago -- aceitar texto livre deixava furar o cache (um
// credito do Parse.bot por chamada) e injetar parametro na URL.

export const MARKET_PLATFORMS = ['ps', 'pc'] as const;
export type MarketPlatform = (typeof MARKET_PLATFORMS)[number];

export function normalizeMarketPlatform(raw: unknown): MarketPlatform {
  return raw === 'pc' ? 'pc' : 'ps';
}
