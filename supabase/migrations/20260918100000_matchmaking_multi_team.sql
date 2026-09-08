-- Matchmaking multi-time (Etapa 11, Parte A).
--
-- DECISAO: ate aqui, uma sessao/entrada de fila pertencia a UM team_id --
-- reflexo direto de a tela Jogar sempre ter exigido escolher um time antes
-- de buscar. A Etapa 11 remove esse seletor: quem busca escolhe Conta +
-- Modo (+ Escalacao), nunca Time. Uma Conta pode estar vinculada a N times
-- (fc_account_teams, N:N, ja existente desde a Etapa 9), entao "buscar"
-- passa a ocupar TODOS os times vinculados aquela conta ao mesmo tempo --
-- uma pessoa buscando por Goias+Palmeiras bloqueia SEARCHING nos dois times,
-- com uma unica sessao real (nunca N sessoes duplicadas).
--
-- Solucao: tabelas de juncao match_search_session_teams e
-- match_search_queue_teams, uma linha por time vinculado aquela sessao/fila
-- no momento da busca. match_search_sessions.team_id e
-- match_search_queue.team_id CONTINUAM existindo e nao-nulos -- viram o
-- "time primario" (o menor team_id do conjunto, escolha arbitraria mas
-- deterministica) para nao quebrar FKs, indices e o significado de
-- game_matches.team_id (uma partida sempre pertence a UM time, o time a
-- partir do qual "Encontrei" foi reportado). Todo read model que decide "sou
-- eu que estou buscando NESTE time" passa a enxergar a sessao/fila via join
-- nas tabelas novas, nunca mais comparando team_id direto.
--
-- Regra de conflito preservada e generalizada: dentro de QUALQUER time onde
-- ha sobreposicao de contas vinculadas, so uma pessoa busca por vez -- e
-- isso agora vale transitivamente pelos times compartilhados pela CONTA que
-- busca (nao por cadeias de jogadores: se Lucas busca por Goias+Palmeiras,
-- Pedro (so Goias) e Joao (so Palmeiras) ficam bloqueados, mesmo sem overlap
-- direto Pedro-Joao -- os dois times estao ocupados pela MESMA sessao). O
-- servidor decide: toda checagem de conflito mora nas RPCs abaixo, nunca no
-- Flutter.
--
-- Fila com times parcialmente livres (ex.: Pedro vinculado a Goias+
-- Bragantino, so Goias ocupado): ficou fora de escopo tratar liberacao
-- parcial na V1 -- a entrada de fila de Pedro trava o conjunto INTEIRO dos
-- times da conta dele ate ser promovido (mesma regra da sessao). Bragantino
-- fica temporariamente indisponivel para outra conta enquanto Pedro espera,
-- mesmo estando "livre" hoje. E uma simplificacao deliberada: preferimos
-- superbloquear (nunca permite dupla ocupacao) a arriscar uma promocao
-- parcial errada. Documentado aqui para nao ser reinventado por engano.

create table public.match_search_session_teams (
    search_session_id uuid not null
        references public.match_search_sessions (id) on delete cascade,
    team_id uuid not null references public.teams (id) on delete cascade,

    primary key (search_session_id, team_id)
);

comment on table public.match_search_session_teams is
    'Todos os times vinculados a conta que abriu esta sessao de busca -- o time em sessions.team_id e so o primario/deterministico.';

create index match_search_session_teams_team_idx
    on public.match_search_session_teams (team_id);

create table public.match_search_queue_teams (
    queue_id uuid not null
        references public.match_search_queue (id) on delete cascade,
    team_id uuid not null references public.teams (id) on delete cascade,

    primary key (queue_id, team_id)
);

comment on table public.match_search_queue_teams is
    'Todos os times vinculados a conta que esta na fila -- mesmo papel de match_search_session_teams para entradas de fila.';

create index match_search_queue_teams_team_idx
    on public.match_search_queue_teams (team_id);

alter table public.match_search_session_teams enable row level security;
alter table public.match_search_queue_teams enable row level security;

-- Mesma postura de match_search_sessions/queue: sem policy, sem grant --
-- toda leitura passa pelas RPCs security definer existentes.
revoke all on table public.match_search_session_teams from anon, authenticated, public;
revoke all on table public.match_search_queue_teams from anon, authenticated, public;

-- Backfill: toda sessao/fila ja existente so tinha um time mesmo (o unico
-- que o Flutter sabia escolher ate aqui) -- vira a linha primaria dela na
-- tabela nova, sem inventar time nenhum a mais.
insert into public.match_search_session_teams (search_session_id, team_id)
select id, team_id from public.match_search_sessions;

insert into public.match_search_queue_teams (queue_id, team_id)
select id, team_id from public.match_search_queue;

-- Times vinculados a uma conta, ordenados -- a ordem e o que garante lock
-- sempre na mesma sequencia (evita deadlock entre duas buscas concorrentes
-- que compartilham dois times) e escolhe o "time primario" (o primeiro)
-- de forma deterministica.
create function public._fc_account_team_ids(p_fc_account_id uuid)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(array_agg(team_id order by team_id), array[]::uuid[])
    from public.fc_account_teams
    where fc_account_id = p_fc_account_id;
$$;

revoke execute on function public._fc_account_team_ids(uuid)
    from public, anon, authenticated;

-- Trava, em ordem, o matchmaking de cada time do conjunto. Precisa ser
-- chamada antes de qualquer leitura/escrita que decida estado -- e o que
-- torna "duas contas buscando times sobrepostos ao mesmo tempo" seguro.
create function public._lock_teams_matchmaking(p_team_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_team_id uuid;
begin
    foreach v_team_id in array p_team_ids loop
        perform public._lock_team_matchmaking(v_team_id);
    end loop;
end;
$$;

revoke execute on function public._lock_teams_matchmaking(uuid[])
    from public, anon, authenticated;

-- Verdadeiro se NENHUM dos times do conjunto tem sessao SEARCHING ativa no
-- momento -- a checagem central de "posso virar SEARCHING agora".
create function public._teams_free_for_search(p_team_ids uuid[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select not exists (
        select 1
        from public.match_search_session_teams as st
        join public.match_search_sessions as s on s.id = st.search_session_id
        where st.team_id = any (p_team_ids) and s.status = 'SEARCHING'
    );
$$;

revoke execute on function public._teams_free_for_search(uuid[])
    from public, anon, authenticated;

-- Reescrita para achar a sessao SEARCHING que toca este time via join,
-- nunca mais por igualdade direta de team_id (a sessao pode pertencer a
-- outro time como primario e ainda assim tocar este via a tabela nova).
create or replace function public._expire_team_search_if_needed(p_team_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_session public.match_search_sessions;
    v_team_ids uuid[];
    v_team_id_notify uuid;
begin
    select s.* into v_session
    from public.match_search_sessions as s
    join public.match_search_session_teams as st on st.search_session_id = s.id
    where st.team_id = p_team_id and s.status = 'SEARCHING';

    if v_session.id is null or v_session.expires_at > now() then
        return false;
    end if;

    update public.match_search_sessions
    set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
    where id = v_session.id;

    perform public._enqueue_notification(
        v_session.user_id,
        'SEARCH_EXPIRED',
        p_team_id,
        v_session.id,
        '{}'::jsonb
    );

    select coalesce(array_agg(team_id), array[]::uuid[]) into v_team_ids
    from public.match_search_session_teams
    where search_session_id = v_session.id;

    perform public._promote_next_queued_players_for_teams(v_team_ids);

    for v_team_id_notify in
        select unnest(v_team_ids) except select p_team_id
    loop
        perform public._notify_matchmaking_changed(v_team_id_notify);
    end loop;

    return true;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

-- Promove entradas de fila enquanto existir alguma cujo conjunto INTEIRO de
-- times esteja livre agora. Chamada apos qualquer evento que libere times
-- (cancelamento, "Encontrei", expiracao) com o conjunto de times que
-- acabaram de ficar livres. Uma unica conta promovida pode cobrir varios
-- times de uma vez (se o conjunto dela for subconjunto dos livres) -- o
-- loop repete ate nao achar mais candidato, permitindo tambem promover uma
-- segunda conta disjunta para um time que sobrou livre.
create function public._promote_next_queued_players_for_teams(p_team_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_candidate public.match_search_queue;
    v_candidate_teams uuid[];
    v_new_session public.match_search_sessions;
begin
    loop
        select q.* into v_candidate
        from public.match_search_queue as q
        where exists (
            select 1 from public.match_search_queue_teams as qt
            where qt.queue_id = q.id and qt.team_id = any (p_team_ids)
        )
        and public._teams_free_for_search((
            select coalesce(array_agg(qt2.team_id), array[]::uuid[])
            from public.match_search_queue_teams as qt2
            where qt2.queue_id = q.id
        ))
        order by q.sequence
        limit 1;

        exit when v_candidate.id is null;

        select coalesce(array_agg(team_id), array[]::uuid[]) into v_candidate_teams
        from public.match_search_queue_teams
        where queue_id = v_candidate.id;

        delete from public.match_search_queue_teams where queue_id = v_candidate.id;
        delete from public.match_search_queue where id = v_candidate.id;

        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_account_id, fc_squad_id)
        select
            v_candidate_teams[1],
            v_candidate.user_id,
            'SEARCHING',
            now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            v_candidate.game_mode,
            v_candidate.fc_account_id,
            v_candidate.fc_squad_id
        from public.teams as t
        where t.id = v_candidate_teams[1]
        returning * into v_new_session;

        insert into public.match_search_session_teams (search_session_id, team_id)
        select v_new_session.id, tid from unnest(v_candidate_teams) as tid;

        perform public._enqueue_notification(
            v_new_session.user_id,
            'YOUR_TURN',
            v_candidate_teams[1],
            v_new_session.id,
            jsonb_build_object('expires_at', to_jsonb(v_new_session.expires_at))
        );
    end loop;
end;
$$;

revoke execute on function public._promote_next_queued_players_for_teams(uuid[])
    from public, anon, authenticated;

-- _promote_next_queued_player(uuid) antigo (por time) fica orfao: nenhuma
-- RPC daqui pra frente promove por um unico time isolado, sempre pelo
-- conjunto inteiro da conta liberada. Removido para nao convidar uso errado.
drop function if exists public._promote_next_queued_player(uuid);

-- Read model por time, agora via join nas tabelas de times vinculados --
-- nunca mais comparando team_id direto contra a sessao/fila, que pode
-- pertencer a outro time como primario e ainda tocar este.
create or replace function public._build_matchmaking_state(p_team_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_duration integer;
    v_searching public.match_search_sessions;
    v_queue jsonb;
    v_my_state text;
    v_my_position integer;
begin
    select default_search_duration_seconds into v_duration
    from public.teams
    where id = p_team_id;

    select s.* into v_searching
    from public.match_search_sessions as s
    join public.match_search_session_teams as st on st.search_session_id = s.id
    where st.team_id = p_team_id and s.status = 'SEARCHING';

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', ranked.user_id,
            'display_name', ranked.display_name,
            'avatar_url', ranked.avatar_url,
            'position', ranked.position,
            'joined_at', ranked.joined_at,
            'game_mode', ranked.game_mode,
            'fc_account_name', ranked.fc_account_name
        ) order by ranked.position
    ), '[]'::jsonb)
    into v_queue
    from (
        select
            q.user_id,
            p.display_name,
            p.avatar_url,
            q.joined_at,
            q.game_mode,
            a.name as fc_account_name,
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.match_search_queue_teams as qt on qt.queue_id = q.id
        join public.profiles as p on p.id = q.user_id
        left join public.user_fc_accounts as a on a.id = q.fc_account_id
        where qt.team_id = p_team_id
    ) as ranked;

    if v_searching.id is not null and v_searching.user_id = p_user_id then
        v_my_state := 'SEARCHING';
        v_my_position := null;
    else
        select ranked.position into v_my_position
        from (
            select q.user_id, row_number() over (order by q.sequence) as position
            from public.match_search_queue as q
            join public.match_search_queue_teams as qt on qt.queue_id = q.id
            where qt.team_id = p_team_id
        ) as ranked
        where ranked.user_id = p_user_id;

        v_my_state := case when v_my_position is not null then 'QUEUED' else 'NONE' end;
    end if;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'search_duration_seconds', v_duration,
        'searching', case when v_searching.id is null then null else jsonb_build_object(
            'session_id', v_searching.id,
            'user_id', v_searching.user_id,
            'display_name', (select display_name from public.profiles where id = v_searching.user_id),
            'avatar_url', (select avatar_url from public.profiles where id = v_searching.user_id),
            'started_at', to_jsonb(v_searching.started_at),
            'expires_at', to_jsonb(v_searching.expires_at),
            'game_mode', v_searching.game_mode,
            'fc_account_name', (
                select name from public.user_fc_accounts where id = v_searching.fc_account_id
            )
        ) end,
        'queue', v_queue,
        'my_state', v_my_state,
        'my_position', v_my_position
    );
end;
$$;

-- Read model novo, centrado em conta em vez de time -- e o que a tela Jogar
-- passa a consumir depois que o seletor de time some (item 3 da Etapa 11).
-- FQ035: conta sem nenhum time vinculado, busca impossivel.
create function public.get_my_matchmaking_status(p_fc_account_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_team_ids uuid[];
    v_duration integer;
    v_my_session public.match_search_sessions;
    v_my_queue public.match_search_queue;
    v_other_session public.match_search_sessions;
    v_my_state text;
    v_my_position integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    v_team_ids := public._fc_account_team_ids(p_fc_account_id);

    if array_length(v_team_ids, 1) is not null then
        select default_search_duration_seconds into v_duration
        from public.teams
        where id = v_team_ids[1];
    end if;

    select * into v_my_session
    from public.match_search_sessions
    where user_id = v_user_id and fc_account_id = p_fc_account_id
      and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue
        from public.match_search_queue
        where user_id = v_user_id and fc_account_id = p_fc_account_id;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(distinct q.id) + 1 into v_my_position
            from public.match_search_queue as q
            join public.match_search_queue_teams as qt on qt.queue_id = q.id
            where qt.team_id = any (v_team_ids) and q.sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;
    end if;

    if v_my_state = 'NONE' and array_length(v_team_ids, 1) is not null then
        select s.* into v_other_session
        from public.match_search_sessions as s
        join public.match_search_session_teams as st on st.search_session_id = s.id
        where st.team_id = any (v_team_ids) and s.status = 'SEARCHING'
        limit 1;
    end if;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'fc_account_id', p_fc_account_id,
        'linked_team_ids', to_jsonb(v_team_ids),
        'search_duration_seconds', v_duration,
        'my_state', v_my_state,
        'my_position', v_my_position,
        'searching', case when v_my_session.id is null then null else jsonb_build_object(
            'session_id', v_my_session.id,
            'started_at', to_jsonb(v_my_session.started_at),
            'expires_at', to_jsonb(v_my_session.expires_at),
            'game_mode', v_my_session.game_mode,
            'fc_squad_id', v_my_session.fc_squad_id,
            'fc_squad_name', (
                select name from public.fc_squads where id = v_my_session.fc_squad_id
            )
        ) end,
        'blocking_search', case when v_other_session.id is null then null else jsonb_build_object(
            'user_id', v_other_session.user_id,
            'display_name', (select display_name from public.profiles where id = v_other_session.user_id),
            'avatar_url', (select avatar_url from public.profiles where id = v_other_session.user_id),
            'expires_at', to_jsonb(v_other_session.expires_at),
            'fc_account_name', (
                select name from public.user_fc_accounts where id = v_other_session.fc_account_id
            )
        ) end
    );
end;
$$;

comment on function public.get_my_matchmaking_status(uuid) is
    'Read model centrado em conta para a tela Jogar: meu estado (SEARCHING/QUEUED/NONE), quem me bloqueia se houver.';

revoke execute on function public.get_my_matchmaking_status(uuid) from public, anon;
grant execute on function public.get_my_matchmaking_status(uuid) to authenticated;

-- request_match_search deixa de receber team_id: a conta ja carrega os times
-- vinculados (fc_account_teams), entao a tela Jogar nunca mais escolhe time.
-- Assinatura muda de (team, account, squad, mode) para (account, squad,
-- mode) -- dropa a versao antiga.
drop function if exists public.request_match_search(uuid, uuid, uuid, text);

create function public.request_match_search(
    p_fc_account_id uuid,
    p_fc_squad_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_team_ids uuid[];
    v_active_team_ids uuid[];
    v_already_session public.match_search_sessions;
    v_already_queue public.match_search_queue;
    v_tid uuid;
    v_new_session public.match_search_sessions;
    v_new_queue public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_game_mode is null
        or p_game_mode not in ('WEEKEND_LEAGUE', 'DIVISION_RIVALS')
    then
        raise exception 'invalid game mode' using errcode = 'FQ023';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if p_fc_squad_id is not null and not exists (
        select 1 from public.fc_squads
        where id = p_fc_squad_id
          and fc_account_id = p_fc_account_id
          and is_active
    ) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    v_team_ids := public._fc_account_team_ids(p_fc_account_id);
    if array_length(v_team_ids, 1) is null then
        raise exception 'fc account is not linked to any team'
            using errcode = 'FQ035';
    end if;

    select coalesce(array_agg(t.id order by t.id), array[]::uuid[])
        into v_active_team_ids
    from public.teams as t
    where t.id = any (v_team_ids) and t.is_active;

    if array_length(v_active_team_ids, 1) is null then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;
    v_team_ids := v_active_team_ids;

    foreach v_tid in array v_team_ids loop
        if not public.is_team_member(v_tid) then
            raise exception 'permission denied' using errcode = 'FQ012';
        end if;
    end loop;

    perform public._lock_teams_matchmaking(v_team_ids);

    foreach v_tid in array v_team_ids loop
        perform public._expire_team_search_if_needed(v_tid);
    end loop;

    select * into v_already_session
    from public.match_search_sessions
    where user_id = v_user_id and fc_account_id = p_fc_account_id
      and status = 'SEARCHING';
    if v_already_session.id is not null then
        return public.get_my_matchmaking_status(p_fc_account_id);
    end if;

    select * into v_already_queue
    from public.match_search_queue
    where user_id = v_user_id and fc_account_id = p_fc_account_id;
    if v_already_queue.id is not null then
        return public.get_my_matchmaking_status(p_fc_account_id);
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id
          and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    if public._teams_free_for_search(v_team_ids) then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_account_id, fc_squad_id)
        select
            v_team_ids[1], v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode, p_fc_account_id, p_fc_squad_id
        from public.teams as t
        where t.id = v_team_ids[1]
        returning * into v_new_session;

        insert into public.match_search_session_teams (search_session_id, team_id)
        select v_new_session.id, tid from unnest(v_team_ids) as tid;
    else
        insert into public.match_search_queue
            (team_id, user_id, game_mode, fc_account_id, fc_squad_id)
        values (v_team_ids[1], v_user_id, p_game_mode, p_fc_account_id, p_fc_squad_id)
        returning * into v_new_queue;

        insert into public.match_search_queue_teams (queue_id, team_id)
        select v_new_queue.id, tid from unnest(v_team_ids) as tid;
    end if;

    foreach v_tid in array v_team_ids loop
        perform public._notify_matchmaking_changed(v_tid);
    end loop;

    return public.get_my_matchmaking_status(p_fc_account_id);
end;
$$;

comment on function public.request_match_search(uuid, uuid, text) is
    'Vira SEARCHING ou entra na fila usando os times vinculados a conta. Sem time explicito: a conta ja sabe quais times ocupar.';

revoke execute on function public.request_match_search(uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, uuid, text)
    to authenticated;

-- cancel_match_search e report_match_found_and_start_game passam a receber
-- a CONTA, nao o time -- a tela Jogar so conhece a conta selecionada. O tipo
-- do parametro continua uuid, mas o NOME muda (p_team_id -> p_fc_account_id)
-- -- Postgres nao permite renomear parametro via create or replace, entao
-- precisa dropar a versao antiga primeiro.
drop function if exists public.cancel_match_search(uuid);

create function public.cancel_match_search(p_fc_account_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_queue_entry public.match_search_queue;
    v_team_ids uuid[];
    v_tid uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    v_team_ids := public._fc_account_team_ids(p_fc_account_id);
    if array_length(v_team_ids, 1) is not null then
        perform public._lock_teams_matchmaking(v_team_ids);
    end if;

    select * into v_searching
    from public.match_search_sessions
    where user_id = v_user_id and fc_account_id = p_fc_account_id
      and status = 'SEARCHING';

    if v_searching.id is not null then
        select coalesce(array_agg(team_id), array[]::uuid[]) into v_team_ids
        from public.match_search_session_teams
        where search_session_id = v_searching.id;

        update public.match_search_sessions
        set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
        where id = v_searching.id;

        perform public._promote_next_queued_players_for_teams(v_team_ids);

        foreach v_tid in array v_team_ids loop
            perform public._notify_matchmaking_changed(v_tid);
        end loop;

        return public.get_my_matchmaking_status(p_fc_account_id);
    end if;

    select * into v_queue_entry
    from public.match_search_queue
    where user_id = v_user_id and fc_account_id = p_fc_account_id;

    if v_queue_entry.id is not null then
        select coalesce(array_agg(team_id), array[]::uuid[]) into v_team_ids
        from public.match_search_queue_teams
        where queue_id = v_queue_entry.id;

        delete from public.match_search_queue_teams where queue_id = v_queue_entry.id;
        delete from public.match_search_queue where id = v_queue_entry.id;

        foreach v_tid in array v_team_ids loop
            perform public._notify_matchmaking_changed(v_tid);
        end loop;

        return public.get_my_matchmaking_status(p_fc_account_id);
    end if;

    raise exception 'no active search or queue entry to cancel'
        using errcode = 'FQ015';
end;
$$;

comment on function public.cancel_match_search(uuid) is
    'Cancela a busca (promove quem esperava) ou sai da fila da conta chamadora, o que for aplicavel.';

revoke execute on function public.cancel_match_search(uuid) from public, anon;
grant execute on function public.cancel_match_search(uuid) to authenticated;

-- report_match_found_and_start_game tambem passa a receber a conta. O time
-- gravado em game_matches.team_id e o time primario da sessao (o menor
-- team_id do conjunto vinculado) -- a partida continua pertencendo a UM
-- time, mesmo que a busca tenha ocupado varios. Mesmo motivo do drop acima:
-- o parametro muda de nome (p_team_id -> p_fc_account_id).
drop function if exists public.report_match_found_and_start_game(uuid);

create function public.report_match_found_and_start_game(p_fc_account_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_event_id uuid;
    v_mode text;
    v_snapshot jsonb;
    v_team_ids uuid[];
    v_tid uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    select * into v_searching
    from public.match_search_sessions
    where user_id = v_user_id and fc_account_id = p_fc_account_id
      and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    select coalesce(array_agg(team_id order by team_id), array[]::uuid[])
        into v_team_ids
    from public.match_search_session_teams
    where search_session_id = v_searching.id;

    perform public._lock_teams_matchmaking(v_team_ids);

    v_mode := coalesce(v_searching.game_mode, 'DIVISION_RIVALS');

    if v_searching.fc_squad_id is not null then
        v_snapshot := public._fc_squad_snapshot(v_searching.fc_squad_id);
    end if;

    update public.match_search_sessions
    set status = 'MATCH_FOUND', finish_reason = 'MATCH_FOUND',
        finished_at = now()
    where id = v_searching.id;

    update public.game_matches
    set status = 'ABANDONED', ended_at = now()
    where user_id = v_user_id and status = 'IN_MATCH';

    if v_mode = 'WEEKEND_LEAGUE' then
        select id into v_event_id
        from public.weekend_league_events
        where is_active and now() between starts_at and ends_at
        order by starts_at desc
        limit 1;
    end if;

    insert into public.game_matches
        (user_id, team_id, search_session_id, game_mode,
         weekend_league_event_id, status, started_at, fc_account_id,
         fc_squad_id, squad_snapshot)
    values
        (v_user_id, v_searching.team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(), v_searching.fc_account_id,
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_players_for_teams(v_team_ids);

    foreach v_tid in array v_team_ids loop
        perform public._notify_matchmaking_changed(v_tid);
    end loop;

    return public.get_my_matchmaking_status(p_fc_account_id);
end;
$$;

revoke execute on function public.report_match_found_and_start_game(uuid)
    from public, anon;
grant execute on function public.report_match_found_and_start_game(uuid)
    to authenticated;

-- get_team_player_statuses (Etapa 8.5/8.5+) passa a enxergar SEARCHING/
-- QUEUED via as tabelas de juncao -- um membro pode aparecer buscando neste
-- time mesmo que a sessao dele tenha outro time como primario.
create or replace function public.get_team_player_statuses(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_members jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', m.user_id,
            'display_name', coalesce(p.display_name, ''),
            'avatar_url', p.avatar_url,
            'role', m.role,
            'last_active_at', to_jsonb(p.last_active_at),
            'status', case
                when exists (
                    select 1 from public.game_matches g
                    where g.user_id = m.user_id and g.status = 'IN_MATCH'
                ) then 'IN_MATCH'
                when exists (
                    select 1 from public.match_search_sessions s
                    join public.match_search_session_teams st
                        on st.search_session_id = s.id
                    where st.team_id = p_team_id and s.user_id = m.user_id
                      and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    join public.match_search_queue_teams qt
                        on qt.queue_id = q.id
                    where qt.team_id = p_team_id and q.user_id = m.user_id
                ) then 'QUEUED'
                when p.last_active_at is not null
                    and p.last_active_at >= now() - interval '60 minutes'
                    then 'RECENTLY_ACTIVE'
                else 'OFFLINE'
            end,
            'queue_position', (
                select row_number() over (order by q.sequence)
                from public.match_search_queue as q
                join public.match_search_queue_teams as qt on qt.queue_id = q.id
                where qt.team_id = p_team_id and q.user_id = m.user_id
            )
        )
        order by
            case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end,
            coalesce(p.display_name, '')
    ), '[]'::jsonb)
    into v_members
    from public.team_members as m
    join public.profiles as p on p.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'members', v_members
    );
end;
$$;

-- Historico e estatisticas por time passam a enxergar tambem sessoes cujo
-- time primario e OUTRO mas que tocaram este time via a tabela de juncao --
-- senao o historico de um time secundario ficaria mudo para buscas de conta
-- multi-time.
create or replace function public.get_team_match_search_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_finished_at timestamptz default null,
    p_cursor_id uuid default null,
    p_status text default null,
    p_user_id uuid default null,
    p_from timestamptz default null,
    p_to timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (
                order by s.finished_at desc, s.id desc
            ) as ord,
            jsonb_build_object(
                'session_id', s.id,
                'user_id', s.user_id,
                'display_name', coalesce(p.display_name, ''),
                'avatar_url', p.avatar_url,
                'status', s.status,
                'finish_reason', s.finish_reason,
                'started_at', to_jsonb(s.started_at),
                'finished_at', to_jsonb(s.finished_at),
                'duration_seconds',
                    round(extract(epoch from (s.finished_at - s.started_at)))::int,
                'configured_duration_seconds',
                    round(extract(epoch from (s.expires_at - s.started_at)))::int
            ) as item
        from public.match_search_sessions as s
        join public.match_search_session_teams as st on st.search_session_id = s.id
        left join public.profiles as p on p.id = s.user_id
        where st.team_id = p_team_id
          and s.finished_at is not null
          and (p_status is null or s.status = p_status)
          and (p_user_id is null or s.user_id = p_user_id)
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
          and (
              p_cursor_finished_at is null
              or p_cursor_id is null
              or (s.finished_at, s.id) < (p_cursor_finished_at, p_cursor_id)
          )
        order by s.finished_at desc, s.id desc
        limit v_limit + 1
    ) as page;

    v_items := case
        when v_count > v_limit then
            (select jsonb_agg(value)
             from jsonb_array_elements(v_rows) with ordinality as t(value, i)
             where i <= v_limit)
        else v_rows
    end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case
            when v_count > v_limit then jsonb_build_object(
                'finished_at', v_items -> (v_limit - 1) -> 'finished_at',
                'id', v_items -> (v_limit - 1) -> 'session_id'
            )
            else null
        end
    );
end;
$$;

create or replace function public.get_team_matchmaking_stats(
    p_team_id uuid,
    p_from timestamptz default null,
    p_to timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_totals jsonb;
    v_players jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    with finished as (
        select
            s.user_id,
            s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        join public.match_search_session_teams as st on st.search_session_id = s.id
        where st.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    )
    select
        jsonb_build_object(
            'total', count(*),
            'match_found', count(*) filter (where status = 'MATCH_FOUND'),
            'cancelled', count(*) filter (where status = 'CANCELLED'),
            'expired', count(*) filter (where status = 'EXPIRED'),
            'success_rate', case
                when count(*) = 0 then null
                else round(
                    count(*) filter (where status = 'MATCH_FOUND')::numeric
                        / count(*), 4)
            end,
            'avg_duration_seconds', case
                when count(*) = 0 then null
                else round(avg(duration))::int
            end
        )
    into v_totals
    from finished;

    with finished as (
        select
            s.user_id,
            s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        join public.match_search_session_teams as st on st.search_session_id = s.id
        where st.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    ),
    per_player as (
        select
            f.user_id,
            count(*) as total,
            count(*) filter (where f.status = 'MATCH_FOUND') as match_found,
            count(*) filter (where f.status = 'CANCELLED') as cancelled,
            count(*) filter (where f.status = 'EXPIRED') as expired,
            round(
                count(*) filter (where f.status = 'MATCH_FOUND')::numeric
                    / count(*), 4) as success_rate,
            round(avg(f.duration))::int as avg_duration_seconds
        from finished as f
        group by f.user_id
    )
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', pp.user_id,
            'display_name', coalesce(pr.display_name, ''),
            'avatar_url', pr.avatar_url,
            'total', pp.total,
            'match_found', pp.match_found,
            'cancelled', pp.cancelled,
            'expired', pp.expired,
            'success_rate', pp.success_rate,
            'avg_duration_seconds', pp.avg_duration_seconds
        )
        order by pp.total desc, coalesce(pr.display_name, '') asc
    ), '[]'::jsonb)
    into v_players
    from per_player as pp
    left join public.profiles as pr on pr.id = pp.user_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'from', to_jsonb(p_from),
        'to', to_jsonb(p_to),
        'totals', v_totals,
        'players', v_players
    );
end;
$$;

