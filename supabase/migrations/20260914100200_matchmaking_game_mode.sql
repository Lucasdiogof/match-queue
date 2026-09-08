-- Cada busca passa a registrar o modo de jogo. A coluna entra nas DUAS
-- tabelas: na session (o SEARCHING atual) e na queue (quem espera escolheu o
-- modo ao entrar). Quando a fila avança, o novo SEARCHING herda o modo que a
-- pessoa escolheu, não o do anterior. Linhas históricas ficam com game_mode
-- null — o CHECK permite null de propósito para não reescrever o passado.

alter table public.match_search_sessions
    add column game_mode text
    constraint match_search_sessions_game_mode_check
        check (game_mode is null or game_mode in ('WEEKEND_LEAGUE', 'DIVISION_RIVALS'));

alter table public.match_search_queue
    add column game_mode text
    constraint match_search_queue_game_mode_check
        check (game_mode is null or game_mode in ('WEEKEND_LEAGUE', 'DIVISION_RIVALS'));

-- request_match_search ganha o modo e o cooldown; a assinatura muda
-- (uuid → uuid, text), então dropamos a antiga e recriamos.
drop function if exists public.request_match_search(uuid);

create function public.request_match_search(p_team_id uuid, p_game_mode text)
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

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    -- Idempotente: já sou o SEARCHING ou já estou na fila → só devolvo estado
    -- (sem aplicar cooldown, porque não estou iniciando nada novo).
    if v_searching.id is not null and v_searching.user_id = v_user_id then
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    select * into v_existing_queue
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id;

    if v_existing_queue.id is not null then
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    -- Cooldown de 30s: contado do início da última partida do usuário (em
    -- qualquer time). IN_MATCH é informativo, não um lock eterno — passados
    -- 30s a busca é liberada. A promoção automática da fila NÃO passa por
    -- aqui, então nunca é bloqueada pelo cooldown.
    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id
          and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    if v_searching.id is null then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode
        from public.teams as t
        where t.id = p_team_id;
    else
        insert into public.match_search_queue (team_id, user_id, game_mode)
        values (p_team_id, v_user_id, p_game_mode);
    end if;

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.request_match_search(uuid, text) is
    'Vira SEARCHING ou entra na fila com o modo escolhido. Cooldown de 30s pós-partida.';

revoke execute on function public.request_match_search(uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, text)
    to authenticated;

-- Promoção herda o modo escolhido pela pessoa na fila.
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
        (team_id, user_id, status, started_at, expires_at, game_mode)
    select
        p_team_id,
        v_next.user_id,
        'SEARCHING',
        now(),
        now() + make_interval(secs => t.default_search_duration_seconds),
        v_next.game_mode
    from public.teams as t
    where t.id = p_team_id
    returning * into v_new_session;

    return v_new_session;
end;
$$;

-- Read model expõe o modo da busca corrente (a Home mostra "Weekend League"
-- ou "Division Rivals" no card de quem está buscando).
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
            'game_mode', ranked.game_mode
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
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.profiles as p on p.id = q.user_id
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
            'game_mode', v_searching.game_mode
        ) end,
        'queue', v_queue,
        'my_state', v_my_state,
        'my_position', v_my_position
    );
end;
$$;
