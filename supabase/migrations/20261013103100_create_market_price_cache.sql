-- Cache de preco de mercado (feature Mercado, fonte Futbin via Parse.bot).
--
-- Parse.bot cobra credito por chamada -- sem cache, cada visita a uma carta
-- gastaria credito de novo, mesmo que 50 pessoas olhem o mesmo jogador na
-- mesma hora. Uma linha por (provider, provider_card_id, platform): a
-- consulta so bate na API de verdade quando a linha nao existe ou passou de
-- 30 minutos (TTL decidido pelo dono do produto), senao devolve o preco
-- salvo. `current_price` nulo e um resultado valido (carta nao encontrada
-- no Futbin, ou API fora do ar) -- ainda assim respeita o TTL, pra nao
-- martelar credito repetido numa carta sem preco.
--
-- So a Edge Function (service role) le/escreve aqui -- nunca o cliente
-- direto, entao RLS fica habilitado sem nenhuma policy (nega tudo por
-- padrao) e os grants de anon/authenticated sao revogados.
create table public.market_price_cache (
    provider text not null,
    provider_card_id text not null,
    platform text not null,
    current_price integer,
    fetched_at timestamptz not null default now(),
    primary key (provider, provider_card_id, platform)
);

comment on table public.market_price_cache is
    'Cache de preco de mercado por (provider, provider_card_id, platform) -- so a Edge Function fetch-market-price-futbin le/escreve, TTL de 30min aplicado no codigo da function.';

alter table public.market_price_cache enable row level security;

revoke all on table public.market_price_cache from anon;
revoke all on table public.market_price_cache from authenticated;
