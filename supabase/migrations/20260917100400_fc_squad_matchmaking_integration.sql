-- Liga o Squad ao matchmaking e a partida.
--
-- O squad e OPCIONAL (item 63): o Squad Builder e um extra, nunca um portao
-- para jogar. fc_squad_id nullable em toda a cadeia, e partidas antigas
-- continuam com null sem backfill nenhum.

-- Gancho antigo, criado na Etapa 8.5 como reserva para este momento. Nunca
-- foi escrito por nenhum caminho de codigo (sempre null) e agora tem
-- substituto de verdade -- manter os dois so criaria confusao de nome.
alter table public.game_matches drop column if exists account_squad_id;

alter table public.match_search_sessions
    add column fc_squad_id uuid references public.fc_squads (id) on delete set null;
alter table public.match_search_queue
    add column fc_squad_id uuid references public.fc_squads (id) on delete set null;
alter table public.game_matches
    add column fc_squad_id uuid references public.fc_squads (id) on delete set null;

-- O snapshot e o que sobrevive a edicao do squad (itens 64-66). Guardar so
-- fc_squad_id nao bastaria: amanha o usuario troca metade do time e a
-- partida de hoje passaria a mentir sobre quem jogou. Imutavel: escrito uma
-- vez, no nascimento da partida, e nunca mais atualizado.
alter table public.game_matches add column squad_snapshot jsonb;

comment on column public.game_matches.squad_snapshot is
    'Escalacao usada NESTA partida, congelada no inicio. Nunca atualizar.';

create index match_search_sessions_fc_squad_idx
    on public.match_search_sessions (fc_squad_id)
    where fc_squad_id is not null;
create index game_matches_fc_squad_idx
    on public.game_matches (fc_squad_id)
    where fc_squad_id is not null;

-- Snapshot gerado SEMPRE server-side, a partir do estado persistido (item
-- 119/120). O Flutter nao envia escalacao: se enviasse, um cliente adulterado
-- poderia registrar uma partida com um time que nunca existiu.
create function public._fc_squad_snapshot(p_squad_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'squad_id', s.id,
        'name', s.name,
        'formation', s.formation_code,
        'captured_at', to_jsonb(now()),
        'manager', (
            select jsonb_build_object('id', m.id, 'name', m.name)
            from public.fc_managers as m where m.id = s.manager_id
        ),
        'manager_league', (
            select jsonb_build_object('id', l.id, 'name', l.name)
            from public.fc_leagues as l where l.id = s.manager_league_id
        ),
        -- Nome/rating/posicao vao junto do id de proposito: a Etapa 11 pode
        -- reimportar o catalogo de cartas e trocar ids, e o historico tem de
        -- continuar legivel mesmo assim.
        'players', (
            select coalesce(jsonb_agg(
                jsonb_build_object(
                    'slot_type', sl.slot_type,
                    'slot', sl.slot_code,
                    'card_id', c.id,
                    'player_name', coalesce(c.common_name, c.player_name),
                    'rating', c.rating,
                    'position', c.primary_position
                ) order by sl.slot_type, sl.slot_code
            ), '[]'::jsonb)
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = s.id
        )
    )
    from public.fc_squads as s
    where s.id = p_squad_id;
$$;

revoke execute on function public._fc_squad_snapshot(uuid) from public, anon;

-- request_match_search ganha o squad. Assinatura muda (3 -> 4 args), mesmo
-- padrao de drop+create usado quando o elenco entrou na Etapa 9.
drop function if exists public.request_match_search(uuid, uuid, text);

create function public.request_match_search(
    p_team_id uuid,
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

    -- Squad opcional, mas se vier tem de ser DAQUELE elenco: nao da para
    -- jogar com o squad de uma conta usando outra.
    if p_fc_squad_id is not null and not exists (
        select 1 from public.fc_squads
        where id = p_fc_squad_id
          and fc_account_id = p_fc_account_id
          and is_active
    ) then
        raise exception 'squad not found' using errcode = 'FQ029';
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
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_account_id, fc_squad_id)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode, p_fc_account_id, p_fc_squad_id
        from public.teams as t
        where t.id = p_team_id;
    else
        insert into public.match_search_queue
            (team_id, user_id, game_mode, fc_account_id, fc_squad_id)
        values (p_team_id, v_user_id, p_game_mode, p_fc_account_id,
                p_fc_squad_id);
    end if;

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.request_match_search(uuid, uuid, uuid, text) is
    'Vira SEARCHING ou entra na fila com elenco, squad (opcional) e modo.';

revoke execute on function public.request_match_search(uuid, uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, uuid, uuid, text)
    to authenticated;

-- Promocao carrega o squad escolhido na hora de entrar na fila (itens
-- 121/122): se o usuario trocar o default enquanto espera, a vez dele
-- continua sendo jogada com o squad que ele escolheu.
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
        (team_id, user_id, status, started_at, expires_at, game_mode,
         fc_account_id, fc_squad_id)
    select
        p_team_id,
        v_next.user_id,
        'SEARCHING',
        now(),
        now() + make_interval(secs => t.default_search_duration_seconds),
        v_next.game_mode,
        v_next.fc_account_id,
        v_next.fc_squad_id
    from public.teams as t
    where t.id = p_team_id
    returning * into v_new_session;

    perform public._enqueue_notification(
        v_new_session.user_id,
        'YOUR_TURN',
        p_team_id,
        v_new_session.id,
        jsonb_build_object('expires_at', to_jsonb(v_new_session.expires_at))
    );

    return v_new_session;
end;
$$;

revoke execute on function public._promote_next_queued_player(uuid)
    from public, anon, authenticated;

-- "Encontrei" congela a escalacao no momento em que a partida nasce.
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
    v_snapshot jsonb;
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
        raise exception 'caller is not the current searcher'
            using errcode = 'FQ016';
    end if;

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
        (v_user_id, p_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(), v_searching.fc_account_id,
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_player(p_team_id);
    perform public._notify_matchmaking_changed(p_team_id);

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

revoke execute on function public.report_match_found_and_start_game(uuid)
    from public, anon;
grant execute on function public.report_match_found_and_start_game(uuid)
    to authenticated;
