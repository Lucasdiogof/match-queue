-- Rate limit por usuario das consultas que gastam credito pago do Parse.bot
-- (Edge Function fetch-market-price-futbin).
--
-- Antes: so o cache de 1h por (carta, plataforma) segurava o gasto. Um
-- usuario logado percorrendo cartas diferentes gerava um cache-miss -- e um
-- credito -- por chamada, sem teto. (O outro vetor, variar `platform` para
-- furar o cache, foi fechado na propria function: so aceita 'ps'/'pc'.)
--
-- Agora a function chama consume_market_price_quota(user) SO no cache-miss,
-- antes de ir ao Parse.bot. Acima de 60 misses na ultima hora o usuario
-- recebe "preco indisponivel" (price null, igual a provider fora do ar) em
-- vez de gastar credito. Cache-hit nunca conta.
--
-- Tabela e funcao so para service_role: o app nunca le nem escreve aqui.
-- Idempotente.

create table if not exists public.market_price_quota_usage (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users (id) on delete cascade,
    used_at timestamptz not null default now()
);

create index if not exists market_price_quota_usage_user_used_idx
    on public.market_price_quota_usage (user_id, used_at desc);

alter table public.market_price_quota_usage enable row level security;
revoke all on table public.market_price_quota_usage from anon, authenticated;
grant select, insert, delete on table public.market_price_quota_usage to service_role;

create or replace function public.consume_market_price_quota(
    p_user_id uuid,
    p_limit integer default 60,
    p_window interval default interval '1 hour'
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_used integer;
begin
    if p_user_id is null then
        return false;
    end if;

    -- Serializa por usuario: duas chamadas simultaneas nao passam as duas
    -- pelo ultimo slot.
    perform pg_advisory_xact_lock(
        hashtextextended('market_price_quota:' || p_user_id::text, 0)
    );

    -- Limpeza oportunista do que ja saiu da janela deste usuario.
    delete from public.market_price_quota_usage
    where user_id = p_user_id and used_at < now() - p_window;

    select count(*) into v_used
    from public.market_price_quota_usage
    where user_id = p_user_id;

    if v_used >= p_limit then
        return false;
    end if;

    insert into public.market_price_quota_usage (user_id) values (p_user_id);
    return true;
end;
$$;

comment on function public.consume_market_price_quota(uuid, integer, interval) is
    'Consome 1 consulta paga (cache-miss do Futbin) do usuario; false = limite da janela atingido. So service_role. Ver migration 20261021100100.';

revoke execute on function public.consume_market_price_quota(uuid, integer, interval)
    from public, anon, authenticated;
grant execute on function public.consume_market_price_quota(uuid, integer, interval)
    to service_role;
