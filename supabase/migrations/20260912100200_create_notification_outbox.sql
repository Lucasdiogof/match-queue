-- Transactional Outbox.
--
-- A transacao que muda o estado da fila grava aqui, e so isso. Nenhuma
-- chamada HTTP acontece com o lock do time na mao: Postgres nunca fica
-- esperando o Firebase responder. A entrega e assincrona, depois do commit.
--
-- O ganho principal e nao perder evento: se a promocao commitou, a linha de
-- notificacao commitou junto; se a RPC deu rollback, nenhuma das duas
-- existiu. Nao existe a janela do "promoveu, commitou, e ai o push falhou e
-- sumiu".

create type public.notification_type as enum (
    'YOUR_TURN',
    'SEARCH_EXPIRING',
    'SEARCH_EXPIRED'
);

create table public.notification_outbox (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    type public.notification_type not null,
    team_id uuid references public.teams (id) on delete cascade,
    session_id uuid,
    payload jsonb not null default '{}'::jsonb,

    -- Chave de idempotencia. "YOUR_TURN:<session_id>" garante no maximo uma
    -- notificacao de vez por promocao, mesmo que a expiracao lazy e o cron
    -- tentem processar a mesma sessao ao mesmo tempo.
    dedupe_key text not null,

    created_at timestamptz not null default now(),
    -- Quando a linha volta a ficar elegivel. O worker empurra isso pra
    -- frente ao pegar o item (lease) e no backoff de retentativa.
    available_at timestamptz not null default now(),
    processed_at timestamptz,
    attempt_count integer not null default 0,
    last_error text
);

comment on table public.notification_outbox is
    'Fila de notificacoes gravada na mesma transacao que muda o matchmaking.';
comment on column public.notification_outbox.dedupe_key is
    'Idempotencia. Insercao repetida do mesmo evento e descartada.';

create unique index notification_outbox_dedupe_key_idx
    on public.notification_outbox (dedupe_key);

create index notification_outbox_pending_idx
    on public.notification_outbox (available_at)
    where processed_at is null;

-- RLS ligada e nenhuma policy, nenhum grant: mesma postura das tabelas de
-- matchmaking. O cliente nao cria evento, nao le evento dos outros e nao
-- marca nada como processado. Quem escreve sao as funcoes security definer;
-- quem processa e o worker com service_role.
alter table public.notification_outbox enable row level security;

revoke all on table public.notification_outbox from anon, authenticated;

-- Ponto unico de enfileiramento. Silencioso por design: se o evento ja
-- existe, nao faz nada.
create function public._enqueue_notification(
    p_user_id uuid,
    p_type public.notification_type,
    p_team_id uuid,
    p_session_id uuid,
    p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.notification_outbox (
        user_id, type, team_id, session_id, payload, dedupe_key
    )
    values (
        p_user_id,
        p_type,
        p_team_id,
        p_session_id,
        coalesce(p_payload, '{}'::jsonb),
        p_type::text || ':' || coalesce(p_session_id::text, gen_random_uuid()::text)
    )
    on conflict (dedupe_key) do nothing;
end;
$$;

revoke execute on function public._enqueue_notification(
    uuid, public.notification_type, uuid, uuid, jsonb
) from public, anon, authenticated;
