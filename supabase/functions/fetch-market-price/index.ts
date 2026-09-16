// Preco de mercado real (feature Mercado) via FUTNext.
//
// FUT.GG/FUTBIN/FUTWIZ bloqueiam por Cloudflare (ver probe-market-providers,
// ja removido). FUTNext responde 200 com JSON limpo a partir do egress da
// Supabase -- mas "enhancer-api.futnext.com/players/prices" e a API privada
// do app deles, nao uma API publica documentada: sem contrato de
// estabilidade, pode mudar ou bloquear sem aviso. Por isso o preco passa por
// esta function (nunca chamado direto do app) -- da pra trocar de provider
// ou desligar sem precisar de nova build.
//
// So devolve preco atual + plataforma + timestamp: o endpoint nao oferece
// minimo/maximo/historico sem raspar a pagina de jogador renderizada
// server-side (RSC), o que seria scraping improvisado -- exatamente o que
// foi pedido pra evitar. MarketPrice.minPrice/maxPrice/history ficam null
// ate existir uma fonte real pra eles.
//
// verify_jwt fica no default (true, ver supabase/config.toml): so usuario
// autenticado chama. O client usado pra ler fc_player_cards e o do proprio
// chamador (anon key + Authorization dele), nunca service role -- a tabela
// ja e select-authenticated via RLS, nao precisa de privilegio extra.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.47.10';

const FUTNEXT_TIMEOUT_MS = 8000;
const DEFAULT_PLATFORM = 'ps';

interface RequestBody {
  cardId?: string;
  platform?: string;
}

interface FutNextEntry {
  definitionId: number;
  prices: number[];
  updatedAt: number;
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'missing authorization header' }), { status: 401 });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'invalid json body' }), { status: 400 });
  }

  const cardId = body.cardId;
  if (!cardId) {
    return new Response(JSON.stringify({ error: 'missing cardId' }), { status: 400 });
  }
  const platform = body.platform ?? DEFAULT_PLATFORM;

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: cardRow, error: cardError } = await callerClient
    .from('fc_player_cards')
    .select('provider_card_id')
    .eq('id', cardId)
    .maybeSingle();

  if (cardError) {
    return new Response(JSON.stringify({ error: cardError.message }), { status: 500 });
  }
  const providerCardId = cardRow?.provider_card_id as string | null | undefined;
  if (!providerCardId) {
    // Carta sem provider_card_id (ex.: catalogo LOCAL/dev) -- preco
    // indisponivel, nao e um erro.
    return new Response(JSON.stringify({ success: true, price: null }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }
  // provider_card_id vem como "EA_ID:CARD_TYPE" (ex.: "231747:BASE"); o
  // FUTNext so aceita o EA_ID numerico puro.
  const numericId = providerCardId.split(':')[0];

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FUTNEXT_TIMEOUT_MS);
  let entries: FutNextEntry[] = [];
  try {
    const url = `https://enhancer-api.futnext.com/players/prices?ids=${numericId}&platform=${platform}`;
    const res = await fetch(url, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
        Accept: 'application/json',
      },
      signal: controller.signal,
    });
    if (res.ok) {
      const parsed = await res.json();
      if (Array.isArray(parsed)) {
        entries = parsed;
      }
    }
  } catch {
    // Timeout, DNS, bloqueio -- tratado como preco indisponivel, nunca
    // propagado como erro pro app.
  } finally {
    clearTimeout(timer);
  }

  const entry = entries.find((e) => String(e.definitionId) === numericId);
  if (!entry || !Array.isArray(entry.prices) || entry.prices.length === 0) {
    return new Response(JSON.stringify({ success: true, price: null }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(
    JSON.stringify({
      success: true,
      price: {
        currentPrice: entry.prices[0],
        updatedAt: entry.updatedAt,
        platform,
      },
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
