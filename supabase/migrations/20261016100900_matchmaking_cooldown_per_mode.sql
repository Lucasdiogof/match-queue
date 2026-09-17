-- ---------------------------------------------------------------------
-- Corrige o cooldown de 30s em request_match_search: desde a fila
-- independente por (time, modo) em 20261013102700_matchmaking_per_mode_queue,
-- so essa checagem continuou olhando so pra user_id, sem game_mode -- achar
-- partida em Rivals bloqueava a busca em Champions (e vice-versa) por 30s,
-- mesmo sendo filas completamente independentes. Resto da funcao inalterado.
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

    -- Cooldown e por (usuario, MODO): achar partida em Rivals nao pode
    -- bloquear a busca em Champions, sao filas independentes.
    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id and game_mode = p_game_mode
          and started_at > now() - interval '30 seconds'
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
    'Busca por Conta+Time+Modo. Cada (Time, Modo) e uma fila independente -- so comeca na hora se ESSE par estiver livre e a conta nao estiver buscando em outro lugar; senao entra na fila deste (time, modo). Cooldown de 30s tambem e por modo.';
