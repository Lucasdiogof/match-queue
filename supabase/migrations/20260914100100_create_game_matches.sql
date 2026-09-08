-- Partida real, criada quando o SEARCHING toca "Encontrei". É uma entidade
-- SEPARADA da match_search_sessions: a session registra a BUSCA (histórico de
-- fila/tempo), a game_match registra o JOGO (resultado, placar). O status
-- 'EXPIRED' existe nas duas tabelas mas significa coisas diferentes — busca
-- expirada sem promoção vs. partida sem resultado em 20 min — e nunca se
-- misturam porque vivem em tabelas distintas.

create table public.game_matches (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete restrict,
    team_id uuid not null references public.teams (id) on delete cascade,

    -- De qual busca esta partida nasceu. set null: apagar a linha de busca
    -- (não acontece hoje) não apaga o jogo nem seu resultado.
    search_session_id uuid references public.match_search_sessions (id)
        on delete set null,

    game_mode text not null,
    -- Só partidas de Weekend League apontam para o evento; Rivals fica null.
    weekend_league_event_id uuid
        references public.weekend_league_events (id) on delete set null,
    -- Divisão de Rivals no momento da partida (só Rivals). Preparado, seleção
    -- manual simples nesta etapa.
    rivals_division text,

    -- Vínculo futuro com "elenco/conta" (Etapa 9). Deliberadamente SEM FK
    -- agora: a tabela de elencos ainda não existe e uma FK prematura
    -- obrigaria a ordem de criação. Nullable + sem FK = fácil de ligar depois.
    account_squad_id uuid,

    status text not null default 'IN_MATCH',
    result text,
    goals_for integer,
    goals_against integer,

    started_at timestamptz not null default now(),
    ended_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint game_matches_mode_check
        check (game_mode in ('WEEKEND_LEAGUE', 'DIVISION_RIVALS')),
    constraint game_matches_status_check
        check (status in ('IN_MATCH', 'FINISHED', 'ABANDONED', 'EXPIRED')),
    constraint game_matches_result_check
        check (result is null or result in ('WIN', 'LOSS')),
    -- Só partida FINISHED tem resultado; IN_MATCH/ABANDONED/EXPIRED nunca.
    constraint game_matches_result_consistency
        check ((result is not null) = (status = 'FINISHED')),
    -- IN_MATCH nunca tem ended_at; qualquer estado final sempre tem.
    constraint game_matches_ended_consistency
        check ((status = 'IN_MATCH') = (ended_at is null)),
    -- Placar é tudo-ou-nada e não-negativo.
    constraint game_matches_goals_pairing
        check ((goals_for is null) = (goals_against is null)),
    constraint game_matches_goals_non_negative
        check (
            (goals_for is null or goals_for >= 0)
            and (goals_against is null or goals_against >= 0)
        ),
    constraint game_matches_rivals_division_check
        check (
            rivals_division is null
            or rivals_division in (
                'DIV_10','DIV_9','DIV_8','DIV_7','DIV_6',
                'DIV_5','DIV_4','DIV_3','DIV_2','DIV_1','ELITE'
            )
        )
);

comment on table public.game_matches is
    'Partida real (jogo). Separada de match_search_sessions. Escrita só por RPC.';

-- No máximo UMA partida IN_MATCH por usuário. Decisão da Etapa 8.5: começar
-- uma nova partida resolve a anterior (a RPC a marca ABANDONED antes de
-- inserir a nova), então este índice é a garantia estrutural da regra.
create unique index game_matches_one_in_match_per_user
    on public.game_matches (user_id)
    where status = 'IN_MATCH';

-- "Minha partida pendente" e o cooldown: filtram por user_id + status/tempo.
create index game_matches_user_status_idx
    on public.game_matches (user_id, status);
-- Histórico/timeline do time por tempo.
create index game_matches_team_started_idx
    on public.game_matches (team_id, started_at desc);
-- Filtro por modo.
create index game_matches_mode_idx on public.game_matches (game_mode);
-- Record de Weekend League por evento.
create index game_matches_wl_event_idx
    on public.game_matches (weekend_league_event_id)
    where weekend_league_event_id is not null;

create trigger game_matches_set_updated_at
    before update on public.game_matches
    for each row
    execute function public.set_updated_at();

alter table public.game_matches enable row level security;

-- Mesma postura fechada do resto do produto: sem policy, escrita e leitura
-- só pelas RPCs security definer da próxima migration.
revoke all on table public.game_matches from anon, authenticated, public;
