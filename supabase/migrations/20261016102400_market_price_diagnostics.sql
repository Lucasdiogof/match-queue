-- Tabela de diagnostico do preco de mercado: guarda os candidatos CRUS que o
-- provider devolveu quando mais de um casou com a mesma carta.
--
-- POR QUE UMA TABELA E NAO O LOG DA EDGE FUNCTION
-- A funcao ja escreve isso em console.log, mas esse log so existe no painel
-- do Supabase: a CLI desta versao nao tem `functions logs`, e o Futbin
-- responde 403 pra qualquer acesso externo. Sem ver o payload nao da pra
-- saber por qual campo desempatar uma carta da outra -- e adivinhar campo de
-- API alheia foi exatamente o erro que gerou os bugs de preco. Gravando no
-- banco, o payload vira algo consultavel.
--
-- TEMPORARIA de proposito: existe para um diagnostico especifico (jogador com
-- mais de uma carta, ex.: Barcola). Assim que o criterio de desempate estiver
-- implementado, dropar.
--
-- Idempotente: pode rodar de novo sem erro.

create table if not exists public.market_price_diagnostics (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz not null default now(),
    provider text not null,
    card_id uuid,
    provider_numeric_id text,
    player_name text,
    -- O que NOS sabemos da carta, pra comparar com o que o provider mandou.
    our_club text,
    our_rating integer,
    -- Os objetos crus do provider, sem filtro: e o ponto da tabela.
    candidates jsonb not null
);

comment on table public.market_price_diagnostics is
    'Diagnostico temporario: candidatos crus do provider de preco quando mais de um casa com a mesma carta. Sem isso nao da pra saber qual campo separa uma versao da outra. Dropar depois que o desempate estiver pronto.';

create index if not exists market_price_diagnostics_created_at_idx
    on public.market_price_diagnostics (created_at desc);

-- Mesma postura de market_price_cache: so a Edge Function (service role)
-- escreve, e ninguem no app le. Sem policy nenhuma + RLS ligada, `anon` e
-- `authenticated` nao enxergam nada, mesmo com os grants revogados abaixo.
alter table public.market_price_diagnostics enable row level security;

revoke all on table public.market_price_diagnostics from anon;
revoke all on table public.market_price_diagnostics from authenticated;
