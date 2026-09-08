-- Liga elenco ao matchmaking. Coluna NULLABLE nas três tabelas -- registros
-- históricos anteriores a esta migration nunca tiveram elenco e continuam
-- sem (item 53: não inventar elenco fake retroativo). Daqui pra frente, as
-- RPCs sempre exigem e sempre preenchem -- a obrigatoriedade é de aplicação,
-- não de constraint física, de propósito.

alter table public.match_search_sessions
    add column fc_account_id uuid
        references public.user_fc_accounts (id) on delete restrict;

alter table public.match_search_queue
    add column fc_account_id uuid
        references public.user_fc_accounts (id) on delete restrict;

alter table public.game_matches
    add column fc_account_id uuid
        references public.user_fc_accounts (id) on delete restrict;

create index match_search_sessions_fc_account_idx
    on public.match_search_sessions (fc_account_id)
    where fc_account_id is not null;
create index game_matches_fc_account_idx
    on public.game_matches (fc_account_id)
    where fc_account_id is not null;

-- request_match_search ganha fc_account_id. Assinatura muda (2 args -> 3),
-- então dropa e recria -- é o mesmo padrão usado quando o modo de jogo
-- entrou na Etapa 8.5.
drop function if exists public.request_match_search(uuid, text);

create function public.request_match_search(
    p_team_id uuid,
    p_fc_account_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_is_active boolean;
    v_searching public.match_search_sessions;
    v_existing_queue public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
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

    if not exists (
        select 1 from public.fc_account_teams
        where fc_account_id = p_fc_account_id and team_id = p_team_id
    ) then
        raise exception 'fc account is not linked to this team'
            using errcode = 'FQ026';
    end if;

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    -- Idempotente: já sou o SEARCHING ou já estou na fila -- devolve o
    -- estado como está. Elenco/modo não trocam nesse retorno (item 18: pra
    -- mudar, precisa sair da fila e pedir de novo).
    if v_searching.id is not null and v_searching.user_id = v_user_id then
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    select * into v_existing_queue
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id;

    if v_existing_queue.id is not null then
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id
          and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    if v_searching.id is null then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode, fc_account_id)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode, p_fc_account_id
        from public.teams as t
        where t.id = p_team_id;
    else
        insert into public.match_search_queue
            (team_id, user_id, game_mode, fc_account_id)
        values (p_team_id, v_user_id, p_game_mode, p_fc_account_id);
    end if;

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.request_match_search(uuid, uuid, text) is
    'Vira SEARCHING ou entra na fila com elenco+modo escolhidos. Cooldown de 30s pós-partida.';

revoke execute on function public.request_match_search(uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, uuid, text)
    to authenticated;

-- Promoção herda elenco+modo escolhidos pela pessoa na fila (item 16: nunca
-- perder esse contexto ao avançar).
create or replace function public._promote_next_queued_player(p_team_id uuid)
returns public.match_search_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_next public.match_search_queue;
    v_new_session public.match_search_sessions;
begin
    select * into v_next
    from public.match_search_queue
    where team_id = p_team_id
    order by sequence
    limit 1;

    if v_next.id is null then
        return null;
    end if;

    delete from public.match_search_queue where id = v_next.id;

    insert into public.match_search_sessions
        (team_id, user_id, status, started_at, expires_at, game_mode, fc_account_id)
    select
        p_team_id,
        v_next.user_id,
        'SEARCHING',
        now(),
        now() + make_interval(secs => t.default_search_duration_seconds),
        v_next.game_mode,
        v_next.fc_account_id
    from public.teams as t
    where t.id = p_team_id
    returning * into v_new_session;

    return v_new_session;
end;
$$;

-- Read model expõe o elenco de quem busca/espera (item 15/20: "Lucas ·
-- Lucksrei · Weekend League").
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

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

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
        join public.profiles as p on p.id = q.user_id
        left join public.user_fc_accounts as a on a.id = q.fc_account_id
        where q.team_id = p_team_id
    ) as ranked;

    if v_searching.id is not null and v_searching.user_id = p_user_id then
        v_my_state := 'SEARCHING';
        v_my_position := null;
    else
        select ranked.position into v_my_position
        from (
            select user_id, row_number() over (order by sequence) as position
            from public.match_search_queue
            where team_id = p_team_id
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

-- "Encontrei" carrega o elenco da sessão pra dentro da partida nova.
create or replace function public.report_match_found_and_start_game(p_team_id uuid)
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
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;
    if v_searching.user_id <> v_user_id then
        raise exception 'caller is not the current searcher' using errcode = 'FQ016';
    end if;

    v_mode := coalesce(v_searching.game_mode, 'DIVISION_RIVALS');

    update public.match_search_sessions
    set status = 'MATCH_FOUND', finish_reason = 'MATCH_FOUND', finished_at = now()
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
         weekend_league_event_id, status, started_at, fc_account_id)
    values
        (v_user_id, p_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(), v_searching.fc_account_id);

    perform public._promote_next_queued_player(p_team_id);
    perform public._notify_matchmaking_changed(p_team_id);

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;
