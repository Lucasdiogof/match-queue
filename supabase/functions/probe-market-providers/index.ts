// Probe temporario e isolado, NAO faz parte da feature Mercado.
//
// Objetivo unico: descobrir, a partir do IP de egress real da Supabase,
// se FUT.GG, FUTBIN e FUTWIZ respondem a um GET normal (headers comuns,
// timeout curto, sem retry agressivo) ou se bloqueiam por Cloudflare/
// challenge/403/429/timeout. Nao guarda nada em banco, nao chama nenhuma
// outra function ou tabela. Deletar (ou manter so como ferramenta de
// diagnostico fora de producao) depois que o relatorio for gerado.

interface ProbeResult {
  provider: string;
  url: string;
  httpStatus: number | null;
  timeMs: number;
  contentType: string | null;
  approxBytes: number | null;
  looksLikeJson: boolean;
  looksLikeHtml: boolean;
  cloudflareChallenge: boolean;
  timedOut: boolean;
  errorMessage: string | null;
  snippet: string | null;
}

const COMMON_HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
  Accept: 'application/json, text/html;q=0.9, */*;q=0.8',
  'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
};

const TIMEOUT_MS = 8000;
const SNIPPET_MAX = 400;

async function probe(provider: string, url: string): Promise<ProbeResult> {
  const start = performance.now();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const res = await fetch(url, {
      method: 'GET',
      headers: COMMON_HEADERS,
      redirect: 'follow',
      signal: controller.signal,
    });
    const elapsed = Math.round(performance.now() - start);
    const contentType = res.headers.get('content-type');
    const text = await res.text();
    const snippet = text.slice(0, SNIPPET_MAX);

    const looksLikeJson = (contentType?.includes('json') ?? false) || /^\s*[\[{]/.test(text);
    const looksLikeHtml = /^\s*<!doctype html|^\s*<html/i.test(text) || (contentType?.includes('text/html') ?? false);
    const cloudflareChallenge =
      /cf-mitigated|just a moment|cf-chl|checking your browser|attention required/i.test(text) ||
      res.headers.get('cf-mitigated') !== null;

    return {
      provider,
      url,
      httpStatus: res.status,
      timeMs: elapsed,
      contentType,
      approxBytes: text.length,
      looksLikeJson,
      looksLikeHtml,
      cloudflareChallenge,
      timedOut: false,
      errorMessage: null,
      snippet,
    };
  } catch (error) {
    const elapsed = Math.round(performance.now() - start);
    const isAbort = error instanceof Error && error.name === 'AbortError';
    return {
      provider,
      url,
      httpStatus: null,
      timeMs: elapsed,
      contentType: null,
      approxBytes: null,
      looksLikeJson: false,
      looksLikeHtml: false,
      cloudflareChallenge: false,
      timedOut: isAbort,
      errorMessage: error instanceof Error ? error.message : String(error),
      snippet: null,
    };
  } finally {
    clearTimeout(timer);
  }
}

const TARGETS: Array<{ provider: string; url: string }> = [
  { provider: 'futgg', url: 'https://www.fut.gg/api/fut/player-item-definitions/27/?search=mbappe' },
  { provider: 'futgg', url: 'https://www.fut.gg/api/fut/player-prices/27/?ids=239085' },
  { provider: 'futbin', url: 'https://www.futbin.org/futbin/api/getPlayersPrice' },
  { provider: 'futbin', url: 'https://www.futbin.com/27/player/1/kylian-mbappe' },
  { provider: 'futwiz', url: 'https://www.futwiz.com/en/fc27/player/kylian-mbappe/1' },
  { provider: 'futwiz', url: 'https://www.futwiz.com/en/fc27' },
  // FUTNext: acessibilidade estrutural primeiro (id dummy, so pra ver o
  // shape/erro de validacao), depois qualquer provider_card_id real que
  // acharmos no nosso catalogo (ver catalogSample abaixo).
  { provider: 'futnext', url: 'https://enhancer-api.futnext.com/players/prices?ids=1&platform=ps' },
  { provider: 'futnext', url: 'https://enhancer-api.futnext.com/players/prices?ids=1&platform=pc' },
];

async function fetchCatalogSample(): Promise<unknown> {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceKey) return { error: 'missing SUPABASE_URL/SERVICE_ROLE_KEY env' };

  const res = await fetch(
    `${url}/rest/v1/fc_player_cards?select=id,provider,provider_card_id,player_name,rating,primary_position,card_type&player_name=ilike.*mbapp*&limit=8`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } },
  );
  if (!res.ok) return { error: `catalog query failed: ${res.status}` };
  return res.json();
}

Deno.serve(async () => {
  const catalogSample = await fetchCatalogSample();

  const rawIds: string[] = Array.isArray(catalogSample)
    ? (catalogSample as Array<{ provider_card_id: string | null }>)
        .map((c) => c.provider_card_id)
        .filter((v): v is string => typeof v === 'string' && v.length > 0)
    : [];
  // provider_card_id no nosso catalogo vem como "EA_ID:CARD_TYPE" (ex.:
  // "231747:BASE"). O FUTNext espera so o EA_ID numerico no formato
  // ID1_ID2 -- testamos as duas formas pra confirmar qual o endpoint aceita.
  const numericIds = rawIds.map((id) => id.split(':')[0]).filter(Boolean);

  const dynamicTargets: Array<{ provider: string; url: string }> = numericIds.length
    ? [
        {
          provider: 'futnext',
          url: `https://enhancer-api.futnext.com/players/prices?ids=${numericIds.join('_')}&platform=ps`,
        },
        {
          provider: 'futnext',
          url: `https://enhancer-api.futnext.com/players/prices?ids=${numericIds.join('_')}&platform=pc`,
        },
        {
          provider: 'futnext',
          url: `https://enhancer-api.futnext.com/players/prices?ids=${rawIds.join('_')}&platform=ps`,
        },
      ]
    : [];

  const results = await Promise.allSettled(
    [...TARGETS, ...dynamicTargets].map((t) => probe(t.provider, t.url)),
  );
  const report = results.map((r) =>
    r.status === 'fulfilled'
      ? r.value
      : { provider: 'unknown', url: 'unknown', errorMessage: String(r.reason) },
  );
  return new Response(JSON.stringify({ catalogSample, report }, null, 2), {
    headers: { 'content-type': 'application/json' },
  });
});
