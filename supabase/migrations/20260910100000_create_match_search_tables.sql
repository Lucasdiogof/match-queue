-- Fila de busca de partida de um time. Duas tabelas:
--
-- match_search_sessions: uma linha por TENTATIVA real de busca. Nunca
-- deletada -- e o historico (tempo medio, expiracoes, estatisticas
-- futuras). O indice unico parcial abaixo e a garantia estrutural central
-- desta etapa: no maximo um SEARCHING por time, no banco, mesmo sob duas
-- requests simultaneas.
--
-- match_search_queue: quem esta esperando a vez. Representa só o estado
-- CORRENTE -- ao contrario de sessions, uma linha aqui e removida assim
-- que o jogador sai da fila (por vontade propria ou por ser promovido).
-- `sequence` e monotonico (identity), nao um `position` armazenado: dar
-- vaga a alguem nunca renumera as linhas restantes, so muda quem e o
-- menor `sequence` pendente.
--
-- match_search_events fica de fora desta etapa de proposito: sessions ja
-- registra toda tentativa real de busca (started/finished/motivo), que e
-- o que importa pra metrica central do produto. Entrar e sair da fila sem
-- nunca ter sido promovido perde o rastro quando a linha e removida, mas
-- isso e auditoria de fila, nao de busca -- criar uma terceira tabela so
-- pra isso agora seria event sourcing sem consumidor concreto ainda.
-- Aditiva e facil de introduzir depois se aparecer uma razao real.

create table public.match_search_sessions (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete restrict,

    status text not null,
    started_at timestamptz not null default now(),
    expires_at timestamptz not null,
    finished_at timestamptz,
    finish_reason text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint match_search_sessions_status_check
        check (status in ('SEARCHING', 'MATCH_FOUND', 'CANCELLED', 'EXPIRED')),
    constraint match_search_sessions_finish_reason_check
        check (finish_reason is null or finish_reason in ('MATCH_FOUND', 'CANCELLED', 'EXPIRED')),
    -- SEARCHING nunca tem finished_at; qualquer outro status sempre tem.
    constraint match_search_sessions_finished_consistency
        check ((status = 'SEARCHING') = (finished_at is null)),
    constraint match_search_sessions_finish_reason_consistency
        check ((status = 'SEARCHING') = (finish_reason is null)),
    constraint match_search_sessions_expires_after_started
        check (expires_at > started_at)
);

comment on table public.match_search_sessions is
    'Uma linha por tentativa real de busca. Nunca deletada -- historico.';

-- A garantia estrutural central da Etapa 5: no maximo um SEARCHING por
-- time, no banco, independente de quantas requests concorrentes chegarem.
create unique index match_search_sessions_one_searching_per_team
    on public.match_search_sessions (team_id)
    where status = 'SEARCHING';

-- Suporte ao cron/varredura de expiracao: so as linhas SEARCHING importam
-- pra esse scan, e permanecem poucas mesmo com o historico crescendo.
create index match_search_sessions_expiring_idx
    on public.match_search_sessions (expires_at)
    where status = 'SEARCHING';

create trigger match_search_sessions_set_updated_at
    before update on public.match_search_sessions
    for each row
    execute function public.set_updated_at();

create table public.match_search_queue (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete restrict,
    sequence bigint generated always as identity,
    joined_at timestamptz not null default now(),

    -- Uma entrada por jogador por time -- nunca duas vezes na mesma fila.
    constraint match_search_queue_unique_team_user unique (team_id, user_id)
);

comment on table public.match_search_queue is
    'Quem esta esperando a vez agora. Linha removida ao sair ou ser promovido -- estado corrente, nao historico.';

create index match_search_queue_team_sequence_idx
    on public.match_search_queue (team_id, sequence);

-- Um jogador nunca pode estar SEARCHING e QUEUED ao mesmo tempo no mesmo
-- time. As RPCs ja garantem isso procedimentalmente (sao o unico caminho
-- de escrita), mas estas duas triggers sao a rede de seguranca estrutural
-- -- valem mesmo se um bug futuro numa RPC tentar violar a regra.
create function public._guard_no_double_matchmaking_participation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if tg_table_name = 'match_search_sessions' then
        if exists (
            select 1 from public.match_search_queue
            where team_id = new.team_id and user_id = new.user_id
        ) then
            raise exception 'user already queued for this team'
                using errcode = 'FQ017';
        end if;
    elsif tg_table_name = 'match_search_queue' then
        if exists (
            select 1 from public.match_search_sessions
            where team_id = new.team_id
              and user_id = new.user_id
              and status = 'SEARCHING'
        ) then
            raise exception 'user already searching for this team'
                using errcode = 'FQ017';
        end if;
    end if;
    return new;
end;
$$;

create trigger match_search_sessions_guard_participation
    before insert or update on public.match_search_sessions
    for each row
    when (new.status = 'SEARCHING')
    execute function public._guard_no_double_matchmaking_participation();

create trigger match_search_queue_guard_participation
    before insert on public.match_search_queue
    for each row
    execute function public._guard_no_double_matchmaking_participation();

alter table public.match_search_sessions enable row level security;
alter table public.match_search_queue enable row level security;

-- Sem policies de proposito, igual team_invite_links na Etapa 4: leitura e
-- escrita passam exclusivamente pelas RPCs security definer (request/
-- cancel/match-found/get-state), nunca por select/insert direto do Flutter.
revoke all on table public.match_search_sessions from anon, authenticated, public;
revoke all on table public.match_search_queue from anon, authenticated, public;
