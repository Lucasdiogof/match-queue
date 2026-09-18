// Preco de mercado real via Futbin, atras da API paga do Parse.bot
// (api.parse.bot) -- o app nunca fala direto com o Parse.bot nem com o
// Futbin, e a chave (PARSEBOT_API_KEY) nunca sai desta function.
//
// Cada chamada ao Parse.bot custa credito de verdade, entao TUDO passa
// primeiro pelo cache em `market_price_cache` (TTL de 1h, decidido pelo
// dono do produto): a mesma carta consultada por varias pessoas na mesma
// janela usa a MESMA linha de cache, sem gastar credito de novo.
//
// Futbin nao tem endpoint de busca por ID numerico da EA -- so por nome.
// Por isso: busca por nome em search_players_fc27, e casa a carta certa
// comparando o ID numerico da EA (embutido na URL da imagem do resultado,
// ex. ".../players/231747.png") contra provider_card_id da nossa carta.
// IDs proprios do Futbin (o "id" no corpo da resposta) NAO servem pra isso:
// sao escopados por catalogo/ano e nao sao o mesmo numero entre FC26/FC27
// (confirmado testando -- o mesmo player_id=8 e duas pessoas diferentes
// dependendo do ano), entao nunca usados aqui.
//
// Preco "0" (mercado do FC 27 ainda fechado, documentado pelo proprio
// Parse.bot) e devolvido tal qual -- decisao explicita do produto de NAO
// mascarar como "indisponivel", so cartas sem nenhum resultado no Futbin
// viram null de verdade.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.47.10';

const CACHE_TTL_MS = 60 * 60 * 1000;
const DEFAULT_PLATFORM = 'ps';
const PARSEBOT_SCRAPER_BASE =
  'https://api.parse.bot/scraper/21963078-8a17-40ff-a896-9b0b0ec3e828';
const FUTBIN_IMAGE_ID_PATTERN = /\/players\/(\d+)\.png/;

interface RequestBody {
  cardId?: string;
  platform?: string;
}

// Os campos declarados sao os que o app consome hoje. O provider devolve
// mais coisa; o index de assinatura mantem o resto no objeto para o log de
// candidatos ambiguos poder mostrar tudo que veio.
interface FutbinSearchResult {
  image?: string;
  price_ps?: string;
  price_pc?: string;
  [key: string]: unknown;
}

// O Futbin publica preco em forma COMPACTA: "750", "1.45K", "34K",
// "49.75K", "1.2M". Jogar fora tudo que nao e digito transformava
// "49.75K" em 4975 e "45K" em 45 -- o preco aparecia dividido por 10 ou
// por 1000 no app, sem nenhum sinal de erro.
//
// Regras:
//   sem sufixo  -> '.' e ',' sao separador de MILHAR e caem fora
//                  ("1.450" e "1,450" = 1450, "750" = 750)
//   com K ou M  -> o separador antes do sufixo e DECIMAL
//                  ("49.75K" = 49750, "1,2M" = 1200000)
function parsePrice(raw: string | undefined): number | null {
  if (raw == null) {
    return null;
  }

  const text = raw.trim().toUpperCase();
  const match = /^[^0-9]*([0-9][0-9.,]*)\s*([KM]?)/.exec(text);
  if (match == null) {
    return null;
  }

  const [, numberPart, suffix] = match;
  let value: number;

  if (suffix === '') {
    const digits = numberPart.replace(/[^0-9]/g, '');
    if (digits.length === 0) {
      return null;
    }
    value = Number.parseInt(digits, 10);
  } else {
    // Ha no maximo um separador decimal nessa forma; se vier mais de um, o
    // dado nao e o que esperamos e nao vale chutar.
    const separators = numberPart.replace(/[0-9]/g, '');
    if (separators.length > 1) {
      return null;
    }
    const normalized = numberPart.replace(',', '.');
    const scale = suffix === 'M' ? 1000000 : 1000;
    value = Number.parseFloat(normalized) * scale;
  }

  if (!Number.isFinite(value)) {
    return null;
  }
  // Preco em coins e inteiro: "49.75K" da 49750 exato, mas ponto flutuante
  // pode devolver 49749.999999.
  return Math.round(value);
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
    .select('provider_card_id, player_name, common_name, club_name, rating')
    .eq('id', cardId)
    .maybeSingle();

  if (cardError) {
    return new Response(JSON.stringify({ error: cardError.message }), { status: 500 });
  }
  const providerCardId = cardRow?.provider_card_id as string | null | undefined;
  if (!providerCardId) {
    return new Response(JSON.stringify({ success: true, price: null }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }
  const numericId = providerCardId.split(':')[0];

  // service role: market_price_cache nao tem grant nenhum pra
  // anon/authenticated de proposito, so esta function le/escreve.
  const serviceClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: cacheRow, error: cacheReadError } = await serviceClient
    .from('market_price_cache')
    .select('current_price, fetched_at')
    .eq('provider', 'FUTBIN')
    .eq('provider_card_id', cardId)
    .eq('platform', platform)
    .maybeSingle();
  if (cacheReadError) {
    // Nunca propagado pro app (cache e so uma otimizacao de credito), mas
    // logado: uma leitura de cache falhando em silencio vira "sempre
    // cache-miss", que gasta credito do Parse.bot em toda chamada -- ja
    // aconteceu uma vez por falta de GRANT pro service_role na tabela.
    console.error('market_price_cache read failed', cacheReadError);
  }

  const cachedAt = cacheRow ? new Date(cacheRow.fetched_at as string).getTime() : null;
  if (cachedAt !== null && Date.now() - cachedAt < CACHE_TTL_MS) {
    const cachedPrice = cacheRow!.current_price as number | null;
    return new Response(
      JSON.stringify({
        success: true,
        price:
          cachedPrice == null
            ? null
            : { currentPrice: cachedPrice, updatedAt: cachedAt, platform },
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  }

  const playerName = (cardRow?.common_name as string | null) || (cardRow?.player_name as string);
  let price: number | null = null;
  try {
    const apiKey = Deno.env.get('PARSEBOT_API_KEY')!;
    const searchUrl = `${PARSEBOT_SCRAPER_BASE}/search_players_fc27?query=${encodeURIComponent(playerName)}`;
    const res = await fetch(searchUrl, { headers: { 'X-API-Key': apiKey } });
    if (res.ok) {
      const parsed = await res.json();
      const results = parsed?.data?.results as FutbinSearchResult[] | undefined;
      const candidates = (results ?? []).filter(
        (r) => FUTBIN_IMAGE_ID_PATTERN.exec(r.image ?? '')?.[1] === numericId,
      );

      if (candidates.length === 1) {
        const match = candidates[0];
        price = parsePrice(platform === 'pc' ? match.price_pc : match.price_ps);
      } else if (candidates.length > 1) {
        // Um jogador com MAIS DE UMA carta (ex.: Barcola no PSG e no
        // Liverpool) cai aqui: a imagem do Futbin traz o id do JOGADOR, nao
        // o da carta, entao os dois resultados casam igual. O `find` antigo
        // pegava o primeiro da lista -- e a carta do Liverpool acabava
        // mostrando o preco da do PSG, sem nenhum sinal de que estava
        // errado.
        //
        // Preco errado e pior que preco ausente: alguem compra ou vende em
        // cima disso. Ate sabermos qual campo do provider separa uma carta
        // da outra, devolve null e registra os candidatos crus no log --
        // e desse log que sai o criterio de desempate.
        console.log(
          'futbin: multiplos candidatos para o mesmo id de jogador',
          JSON.stringify({
            cardId,
            numericId,
            playerName,
            ourClub: cardRow?.club_name ?? null,
            ourRating: cardRow?.rating ?? null,
            candidates,
          }),
        );
      }
    }
  } catch {
    // Rede/timeout/Parse.bot fora do ar -- vira null abaixo, nunca propagado
    // como erro pro app.
  }

  const fetchedAtIso = new Date().toISOString();
  const { error: cacheWriteError } = await serviceClient.from('market_price_cache').upsert({
    provider: 'FUTBIN',
    // Chave do cache e a NOSSA carta, nao o id de jogador do Futbin:
    // um jogador com duas cartas (ex.: Barcola no PSG e no Liverpool)
    // compartilha o mesmo id de jogador, e cachear por ele fazia uma
    // carta servir o preco da outra.
    provider_card_id: cardId,
    platform,
    current_price: price,
    fetched_at: fetchedAtIso,
  });
  if (cacheWriteError) {
    console.error('market_price_cache write failed', cacheWriteError);
  }

  return new Response(
    JSON.stringify({
      success: true,
      price: price == null ? null : { currentPrice: price, updatedAt: Date.parse(fetchedAtIso), platform },
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});
