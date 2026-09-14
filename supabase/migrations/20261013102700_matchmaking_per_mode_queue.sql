-- Champions e Rivals passam a ter filas INDEPENDENTES dentro do mesmo Time.
--
-- Ate aqui "time livre pra buscar" (_team_free_for_search) e a fila
-- (match_search_queue) eram exclusividade do TIME inteiro, sem olhar pra
-- game_mode -- um jogador buscando Champions bloqueava qualquer outro
-- jogador do time de comecar a buscar Rivals ao mesmo tempo, mesmo os dois
-- sendo filas completamente diferentes na pratica (nunca formam par entre
-- si). Pedido explicito do dono do produto: cada (time, modo) e uma fila
-- propria, do mesmo jeito que cada time ja e uma fila propria desde
-- 20261011100000. O lock global por Conta FC (uma pessoa nao busca em dois
-- lugares ao mesmo tempo) continua igual -- isso nunca foi o problema.

-- ---------------------------------------------------------------------
-- 1. match_search_queue: dedupe por (time, conta, MODO) -- a mesma conta
--    pode ter uma entrada de fila em Champions e outra em Rivals do MESMO
--    time ao mesmo tempo agora.
-- ---------------------------------------------------------------------
drop index if exists public.match_search_queue_unique_team_fc_account;

create unique index match_search_queue_unique_team_fc_account_mode
    on public.match_search_queue (team_id, fc_account_id, game_mode)
    where fc_account_id is not null;

create or replace function public._guard_no_double_matchmaking_participation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if new.fc_account_id is null then
        return new;
    end if;

    if tg_table_name = 'match_search_sessions' then
        if exists (
            select 1 from public.match_search_queue
            where team_id = new.team_id and fc_account_id = new.fc_account_id
              and game_mode = new.game_mode
        ) then
            raise exception 'fc account already queued for this team'
                using errcode = 'FQ017';
        end if;
    elsif tg_table_name = 'match_search_queue' then
        if exists (
            select 1 from public.match_search_sessions
            where team_id = new.team_id
              and fc_account_id = new.fc_account_id
              and game_mode = new.game_mode
              and status = 'SEARCHING'
        ) then
            raise exception 'fc account already searching for this team'
                using errcode = 'FQ017';
        end if;
    end if;
    return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. Checagem central: time+MODO livre (sem SEARCHING naquele modo).
-- ---------------------------------------------------------------------
drop function if exists public._team_free_for_search(uuid);

create function public._team_free_for_search(p_team_id uuid, p_game_mode text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select not exists (
        select 1 from public.match_search_sessions
        where team_id = p_team_id and game_mode = p_game_mode
          and status = 'SEARCHING'
    );
$$;

revoke execute on function public._team_free_for_search(uuid, text)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Promocao por (time, MODO): so olha a fila DAQUELE modo.
-- ---------------------------------------------------------------------
drop function if exists public._promote_next_queued_player_for_team(uuid);

create function public._promote_next_queued_player_for_team(
    p_team_id uuid,
    p_game_mode text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_attempts_left integer;
    v_candidate public.match_search_queue;
    v_new_session public.match_search_sessions;
begin
    select count(*) into v_attempts_left
    from public.match_search_queue
    where team_id = p_team_id and game_mode = p_game_mode;

    while v_attempts_left > 0 loop
        v_attempts_left := v_attempts_left - 1;

        select * into v_candidate
        from public.match_search_queue
        where team_id = p_team_id and game_mode = p_game_mode
        order by sequence
        limit 1;

        exit when v_candidate.id is null;

        if v_candidate.fc_account_id is not null then
            perform public._lock_fc_account_matchmaking(v_candidate.fc_account_id);
        end if;

        if v_candidate.fc_account_id is not null
            and public._fc_account_globally_searching(v_candidate.fc_account_id)
        then
            -- Passa a vez: a conta ja esta buscando em outro (time, modo)
            -- agora. Volta pro final da fila DESTE (time, modo), sem
            -- notificar ninguem. Continua tentando o proximo.
            delete from public.match_search_queue where id = v_candidate.id;
            insert into public.match_search_queue
                (team_id, user_id, game_mode, fc_account_id, fc_squad_id)
            values (
                v_candidate.team_id, v_candidate.user_id, v_candidate.game_mode,
                v_candidate.fc_account_id, v_candidate.fc_squad_id
            );
            continue;
        end if;

        delete from public.match_search_queue where id = v_candidate.id;

        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_account_id, fc_squad_id)
        select
            p_team_id, v_candidate.user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            v_candidate.game_mode, v_candidate.fc_account_id, v_candidate.fc_squad_id
        from public.teams as t
        where t.id = p_team_id
        returning * into v_new_session;

        perform public._enqueue_notification(
            v_new_session.user_id,
            'YOUR_TURN',
            p_team_id,
            v_new_session.id,
            jsonb_build_object(
                'expires_at', to_jsonb(v_new_session.expires_at),
                'fc_account_id', v_new_session.fc_account_id
            )
        );
        return;
    end loop;
end;
$$;

revoke execute on function public._promote_next_queued_player_for_team(uuid, text)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. Retry de promocao por conta: agora por (time, MODO) -- a mesma conta
--    pode ter fila pendente em mais de um (time, modo) ao mesmo tempo.
-- ---------------------------------------------------------------------
create or replace function public._retry_promotion_for_fc_account_queues(
    p_fc_account_id uuid,
    p_exclude_team_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_pair record;
    v_team_ids uuid[];
begin
    if p_fc_account_id is null then
        return;
    end if;

    select coalesce(array_agg(distinct team_id order by team_id), array[]::uuid[])
        into v_team_ids
    from public.match_search_queue
    where fc_account_id = p_fc_account_id and team_id <> p_exclude_team_id;

    if array_length(v_team_ids, 1) is null then
        return;
    end if;

    perform public._lock_teams_matchmaking(v_team_ids);

    for v_pair in
        select distinct team_id, game_mode
        from public.match_search_queue
        where fc_account_id = p_fc_account_id and team_id <> p_exclude_team_id
    loop
        if public._team_free_for_search(v_pair.team_id, v_pair.game_mode) then
            perform public._promote_next_queued_player_for_team(
                v_pair.team_id, v_pair.game_mode
            );
            perform public._notify_matchmaking_changed(v_pair.team_id);
        end if;
    end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- 5. Expiracao lazy: um TIME pode ter ate uma sessao SEARCHING por MODO
--    agora (Champions e Rivals em paralelo), entao verifica e expira cada
--    uma independentemente em vez de assumir "a" sessao do time.
-- ---------------------------------------------------------------------
drop function if exists public._expire_team_search_if_needed(uuid);

create function public._expire_team_search_if_needed(p_team_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_session public.match_search_sessions;
    v_expired_any boolean := false;
begin
    for v_session in
        select * from public.match_search_sessions
        where team_id = p_team_id and status = 'SEARCHING'
          and expires_at <= now()
    loop
        update public.match_search_sessions
        set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
        where id = v_session.id;

        perform public._enqueue_notification(
            v_session.user_id, 'SEARCH_EXPIRED', p_team_id, v_session.id, '{}'::jsonb
        );

        perform public._promote_next_queued_player_for_team(
            p_team_id, v_session.game_mode
        );
        perform public._notify_matchmaking_changed(p_team_id);

        if v_session.fc_account_id is not null then
            perform public._retry_promotion_for_fc_account_queues(
                v_session.fc_account_id, p_team_id
            );
        end if;

        v_expired_any := true;
    end loop;

    return v_expired_any;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 6. request_match_search: livre/fila agora escopados por (time, MODO).
-- ---------------------------------------------------------------------
create or replace function public.request_match_search(
    p_fc_account_id uuid,
    p_team_id uuid,
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
    v_is_active boolean;
    v_already_session public.match_search_sessions;
    v_already_queue public.match_search_queue;
    v_queue_count integer;
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

    if not exists (
        select 1 from public.fc_account_teams
        where fc_account_id = p_fc_account_id and team_id = p_team_id
    ) then
        raise exception 'fc account is not linked to this team'
            using errcode = 'FQ026';
    end if;

    if p_fc_squad_id is not null and not exists (
        select 1 from public.fc_squads
        where id = p_fc_squad_id and fc_account_id = p_fc_account_id and is_active
    ) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._lock_fc_account_matchmaking(p_fc_account_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_already_session
    from public.match_search_sessions
    where team_id = p_team_id and fc_account_id = p_fc_account_id
      and game_mode = p_game_mode and status = 'SEARCHING';
    if v_already_session.id is not null then
        return public.get_my_matchmaking_status(
            p_fc_account_id, p_team_id, p_game_mode
        );
    end if;

    select * into v_already_queue
    from public.match_search_queue
    where team_id = p_team_id and fc_account_id = p_fc_account_id
      and game_mode = p_game_mode;
    if v_already_queue.id is not null then
        return public.get_my_matchmaking_status(
            p_fc_account_id, p_team_id, p_game_mode
        );
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    select count(*) into v_queue_count
    from public.match_search_queue
    where team_id = p_team_id and game_mode = p_game_mode;

    if v_queue_count = 0
        and public._team_free_for_search(p_team_id, p_game_mode)
        and not public._fc_account_globally_searching(p_fc_account_id)
    then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_account_id, fc_squad_id)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode, p_fc_account_id, p_fc_squad_id
        from public.teams as t
        where t.id = p_team_id
        returning * into v_new_session;
    else
        insert into public.match_search_queue
            (team_id, user_id, game_mode, fc_account_id, fc_squad_id)
        values (p_team_id, v_user_id, p_game_mode, p_fc_account_id, p_fc_squad_id)
        returning * into v_new_queue;
    end if;

    perform public._notify_matchmaking_changed(p_team_id);
    return public.get_my_matchmaking_status(
        p_fc_account_id, p_team_id, p_game_mode
    );
end;
$$;

comment on function public.request_match_search(uuid, uuid, uuid, text) is
    'Busca por Conta+Time+Modo. Cada (Time, Modo) e uma fila independente -- so comeca na hora se ESSE par estiver livre e a conta nao estiver buscando em outro lugar; senao entra na fila deste (time, modo).';

-- ---------------------------------------------------------------------
-- 7. cancel_match_search: promove usando o MODO da sessao cancelada.
-- ---------------------------------------------------------------------
create or replace function public.cancel_match_search(p_fc_account_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_team_id uuid;
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

    perform public._lock_fc_account_matchmaking(p_fc_account_id);

    select * into v_searching
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;
    perform public._lock_team_matchmaking(v_team_id);

    update public.match_search_sessions
    set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player_for_team(
        v_team_id, v_searching.game_mode
    );
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_fc_account_queues(p_fc_account_id, v_team_id);

    return public.get_my_matchmaking_status(
        p_fc_account_id, v_team_id, v_searching.game_mode
    );
end;
$$;

-- ---------------------------------------------------------------------
-- 8. leave_match_search_queue: ganha p_game_mode -- a conta pode ter fila
--    em mais de um modo do mesmo time agora, precisa dizer qual sair.
-- ---------------------------------------------------------------------
drop function if exists public.leave_match_search_queue(uuid, uuid);

create function public.leave_match_search_queue(
    p_fc_account_id uuid,
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_entry public.match_search_queue;
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

    perform public._lock_team_matchmaking(p_team_id);

    select * into v_entry
    from public.match_search_queue
    where team_id = p_team_id and fc_account_id = p_fc_account_id
      and game_mode = p_game_mode;

    if v_entry.id is null then
        raise exception 'not in this team queue' using errcode = 'FQ047';
    end if;

    delete from public.match_search_queue where id = v_entry.id;

    perform public._notify_matchmaking_changed(p_team_id);

    return public.get_my_matchmaking_status(
        p_fc_account_id, p_team_id, p_game_mode
    );
end;
$$;

comment on function public.leave_match_search_queue(uuid, uuid, text) is
    'Sai da fila de UM (time, modo) especifico -- a conta pode continuar em filas de outros times/modos.';

revoke execute on function public.leave_match_search_queue(uuid, uuid, text)
    from public, anon;
grant execute on function public.leave_match_search_queue(uuid, uuid, text)
    to authenticated;

-- ---------------------------------------------------------------------
-- 9. report_match_found_and_start_game: promove usando o MODO da sessao.
-- ---------------------------------------------------------------------
create or replace function public.report_match_found_and_start_game(p_fc_account_id uuid)
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
    v_team_id uuid;
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

    perform public._lock_fc_account_matchmaking(p_fc_account_id);

    select * into v_searching
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;
    perform public._lock_team_matchmaking(v_team_id);

    v_mode := coalesce(v_searching.game_mode, 'DIVISION_RIVALS');

    if v_searching.fc_squad_id is not null then
        v_snapshot := public._fc_squad_snapshot(v_searching.fc_squad_id);
    end if;

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
         weekend_league_event_id, status, started_at, fc_account_id,
         fc_squad_id, squad_snapshot)
    values
        (v_user_id, v_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(), v_searching.fc_account_id,
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_player_for_team(v_team_id, v_mode);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_fc_account_queues(p_fc_account_id, v_team_id);

    return public.get_my_matchmaking_status(p_fc_account_id, v_team_id, v_mode);
end;
$$;

-- ---------------------------------------------------------------------
-- 10. get_my_matchmaking_status: ganha p_game_mode -- minha posicao, quem
--     me bloqueia e a fila mostrada agora sao SEMPRE do (time, modo)
--     pedido, nunca do time inteiro misturando os dois modos.
-- ---------------------------------------------------------------------
drop function if exists public.get_my_matchmaking_status(uuid, uuid);

create function public.get_my_matchmaking_status(
    p_fc_account_id uuid,
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_duration integer;
    v_linked boolean;
    v_my_session public.match_search_sessions;
    v_my_queue public.match_search_queue;
    v_other_session public.match_search_sessions;
    v_elsewhere_session public.match_search_sessions;
    v_my_state text;
    v_my_position integer;
    v_queue jsonb;
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

    select default_search_duration_seconds into v_duration
    from public.teams where id = p_team_id;

    select exists (
        select 1 from public.fc_account_teams
        where fc_account_id = p_fc_account_id and team_id = p_team_id
    ) into v_linked;

    select * into v_my_session
    from public.match_search_sessions
    where team_id = p_team_id and fc_account_id = p_fc_account_id
      and game_mode = p_game_mode and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue
        from public.match_search_queue
        where team_id = p_team_id and fc_account_id = p_fc_account_id
          and game_mode = p_game_mode;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(*) + 1 into v_my_position
            from public.match_search_queue
            where team_id = p_team_id and game_mode = p_game_mode
              and sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;

        select * into v_other_session
        from public.match_search_sessions
        where team_id = p_team_id and game_mode = p_game_mode
          and status = 'SEARCHING';

        select * into v_elsewhere_session
        from public.match_search_sessions
        where fc_account_id = p_fc_account_id and status = 'SEARCHING'
          and (team_id <> p_team_id or game_mode <> p_game_mode);
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'position', ranked.position,
            'user_id', ranked.user_id,
            'fc_account_id', ranked.fc_account_id,
            'display_name', ranked.display_name,
            'avatar_url', ranked.avatar_url,
            'fc_account_name', ranked.fc_account_name,
            'game_mode', ranked.game_mode,
            'joined_at', ranked.joined_at,
            'is_me', ranked.fc_account_id = p_fc_account_id
        ) order by ranked.position
    ), '[]'::jsonb)
    into v_queue
    from (
        select
            q.user_id, q.fc_account_id, q.game_mode, q.joined_at,
            p.display_name, p.avatar_url,
            a.name as fc_account_name,
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.profiles as p on p.id = q.user_id
        left join public.user_fc_accounts as a on a.id = q.fc_account_id
        where q.team_id = p_team_id and q.game_mode = p_game_mode
    ) as ranked;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'fc_account_id', p_fc_account_id,
        'team_id', p_team_id,
        'game_mode', p_game_mode,
        'account_linked_to_team', v_linked,
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
            'game_mode', v_other_session.game_mode,
            'fc_account_name', (
                select name from public.user_fc_accounts where id = v_other_session.fc_account_id
            )
        ) end,
        'searching_elsewhere', case when v_elsewhere_session.id is null then null else jsonb_build_object(
            'team_id', v_elsewhere_session.team_id,
            'team_name', (select name from public.teams where id = v_elsewhere_session.team_id),
            'expires_at', to_jsonb(v_elsewhere_session.expires_at)
        ) end,
        'queue', v_queue
    );
end;
$$;

comment on function public.get_my_matchmaking_status(uuid, uuid, text) is
    'Estado de Conta+Time+MODO: minha busca/posicao NESSE (time, modo), quem me bloqueia nele, se estou buscando em outro (time, modo), e a fila daquele par.';

revoke execute on function public.get_my_matchmaking_status(uuid, uuid, text)
    from public, anon;
grant execute on function public.get_my_matchmaking_status(uuid, uuid, text)
    to authenticated;

-- ---------------------------------------------------------------------
-- 11. request_match_search_priority: pede prioridade na sessao daquele
--     (time, MODO), nao mais "a" sessao do time (podem existir duas).
-- ---------------------------------------------------------------------
drop function if exists public.request_match_search_priority(uuid, uuid);

create function public.request_match_search_priority(
    p_fc_account_id uuid,
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_requester_name text;
    v_team_name text;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and game_mode = p_game_mode and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search to prioritize' using errcode = 'FQ048';
    end if;

    select name into v_requester_name
    from public.user_fc_accounts where id = p_fc_account_id;
    select name into v_team_name from public.teams where id = p_team_id;

    perform public._enqueue_notification(
        v_searching.user_id,
        'PRIORITY_REQUESTED',
        p_team_id,
        v_searching.id,
        jsonb_build_object(
            'fc_account_id', v_searching.fc_account_id,
            'requested_by_display_name', (
                select display_name from public.profiles where id = v_user_id
            ),
            'requested_by_fc_account_name', v_requester_name,
            'team_name', v_team_name
        ),
        'PRIORITY_REQUESTED:' || v_searching.id::text || ':' || p_fc_account_id::text
    );

    return jsonb_build_object('server_now', to_jsonb(now()), 'requested', true);
end;
$$;

comment on function public.request_match_search_priority(uuid, uuid, text) is
    'Pedido humano de prioridade na sessao daquele (time, modo) -- nunca altera fila/busca/lock, so notifica quem esta buscando.';

revoke execute on function public.request_match_search_priority(uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search_priority(uuid, uuid, text)
    to authenticated;
