-- report_match_found_and_start_game e finish_game_match (Etapa 8.5) nasceram
-- sem chamar _notify_matchmaking_changed -- a funcao antiga que substituiram
-- (report_match_found, dropada na Etapa 8.5) tinha essa chamada, mas a nova
-- foi escrita direto sem ela. Sem isso, quem toca Encontrei muda o proprio
-- estado (IN_MATCH) mas os outros membros do time so veriam isso no proximo
-- refresh espontaneo -- nao em tempo real, quebrando a expectativa que ja
-- existe pro resto do matchmaking desde a Etapa 6.
--
-- Reaproveita o mesmo sinal (team_matchmaking_revisions) que o resto do
-- matchmaking ja usa: quem escuta esse canal so sabe "o time X mudou",
-- nunca o que mudou -- entao servir tanto pra fila quanto pra status
-- operacional dos jogadores e exatamente o proposito dele, nao uma
-- reinterpretacao.
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
         weekend_league_event_id, status, started_at)
    values
        (v_user_id, p_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now());

    perform public._promote_next_queued_player(p_team_id);
    perform public._notify_matchmaking_changed(p_team_id);

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

-- finish_game_match nao recebe team_id (so p_match_id) -- o time vem da
-- propria linha, apos o update, pra notificar quem esta olhando aquele time.
create or replace function public.finish_game_match(
    p_match_id uuid,
    p_result text default null,
    p_goals_for integer default null,
    p_goals_against integer default null
)
returns public.game_matches
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_result text;
    v_gf integer := p_goals_for;
    v_ga integer := p_goals_against;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;
    if v_match.status <> 'IN_MATCH' then
        raise exception 'game match already finalized' using errcode = 'FQ022';
    end if;

    if v_gf is not null or v_ga is not null then
        if v_gf is null or v_ga is null or v_gf < 0 or v_ga < 0 then
            raise exception 'invalid score' using errcode = 'FQ024';
        end if;
        if v_gf = v_ga then
            raise exception 'a draw is not a valid final result'
                using errcode = 'FQ024';
        end if;
        v_result := case when v_gf > v_ga then 'WIN' else 'LOSS' end;
    elsif p_result in ('WIN', 'LOSS') then
        v_result := p_result;
    else
        raise exception 'a result or a score is required' using errcode = 'FQ024';
    end if;

    update public.game_matches
    set status = 'FINISHED',
        result = v_result,
        goals_for = v_gf,
        goals_against = v_ga,
        ended_at = now()
    where id = v_match.id
    returning * into v_match;

    perform public._notify_matchmaking_changed(v_match.team_id);

    return v_match;
end;
$$;
