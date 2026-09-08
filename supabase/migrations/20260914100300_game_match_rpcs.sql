-- RPCs de partida. Continuam o namespace FQ00x:
--   FQ020 cooldown de busca ativo (na request_match_search)
--   FQ021 partida não encontrada ou não é do chamador
--   FQ022 partida já finalizada (sem double-finish)
--   FQ023 modo de jogo inválido
--   FQ024 resultado/placar inválido (empate ou nada informado)

-- "Encontrei": encerra a busca como MATCH_FOUND, cria a partida IN_MATCH e
-- promove o próximo da fila — tudo numa transação. Substitui report_match_found
-- (dropado: a versão que só encerrava a busca não serve mais).
drop function if exists public.report_match_found(uuid);

create function public.report_match_found_and_start_game(p_team_id uuid)
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

    -- ≤1 IN_MATCH por usuário: a anterior sem resultado vira ABANDONED.
    update public.game_matches
    set status = 'ABANDONED', ended_at = now()
    where user_id = v_user_id and status = 'IN_MATCH';

    -- Weekend League vincula ao evento da janela atual; Rivals fica null.
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

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.report_match_found_and_start_game(uuid) is
    'Encerra a busca (MATCH_FOUND), abre a partida IN_MATCH e promove o próximo.';

revoke execute on function public.report_match_found_and_start_game(uuid)
    from public, anon;
grant execute on function public.report_match_found_and_start_game(uuid)
    to authenticated;

-- Registrar resultado. Placar deriva o resultado; sem placar aceita WIN/LOSS
-- direto. Só funciona a partir de IN_MATCH — uma partida FINISHED não pode
-- ser finalizada de novo (FQ022).
create function public.finish_game_match(
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
        -- WL e Rivals não têm empate como desfecho final.
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

    return v_match;
end;
$$;

comment on function public.finish_game_match(uuid, text, integer, integer) is
    'Finaliza uma partida IN_MATCH com resultado (WIN/LOSS) ou placar. Sem double-finish.';

revoke execute on function public.finish_game_match(uuid, text, integer, integer)
    from public, anon;
grant execute on function public.finish_game_match(uuid, text, integer, integer)
    to authenticated;

-- Marca partidas IN_MATCH paradas há mais de 20 min como EXPIRED (partida sem
-- resultado, distinta da expiração da busca). Chamada pelo cron e, de forma
-- preguiçosa e escopada ao chamador, por get_pending_game_match.
create function public._expire_stale_game_matches(p_user_id uuid default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.game_matches
    set status = 'EXPIRED', ended_at = now()
    where status = 'IN_MATCH'
      and started_at < now() - interval '20 minutes'
      and (p_user_id is null or user_id = p_user_id);
end;
$$;

revoke execute on function public._expire_stale_game_matches(uuid)
    from public, anon, authenticated;

-- Minha partida pendente de resultado (a única IN_MATCH possível). Corrige a
-- expiração de 20 min antes de responder, então só abrir o app basta.
create function public.get_pending_game_match()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_event public.weekend_league_events;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._expire_stale_game_matches(v_user_id);

    select * into v_match
    from public.game_matches
    where user_id = v_user_id and status = 'IN_MATCH'
    order by started_at desc
    limit 1;

    if v_match.id is null then
        return jsonb_build_object('server_now', to_jsonb(now()), 'match', null);
    end if;

    if v_match.weekend_league_event_id is not null then
        select * into v_event from public.weekend_league_events
        where id = v_match.weekend_league_event_id;
    end if;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'match', jsonb_build_object(
            'id', v_match.id,
            'team_id', v_match.team_id,
            'game_mode', v_match.game_mode,
            'status', v_match.status,
            'started_at', to_jsonb(v_match.started_at),
            'weekend_league_event_id', v_match.weekend_league_event_id,
            'weekend_league_number', v_event.number
        )
    );
end;
$$;

comment on function public.get_pending_game_match() is
    'Partida IN_MATCH do chamador pendente de resultado, ou null. Expira 20 min lazily.';

revoke execute on function public.get_pending_game_match() from public, anon;
grant execute on function public.get_pending_game_match() to authenticated;

-- Cron de 1 min: rede de segurança da expiração de partida (o lazy em
-- get_pending já cobre o caminho de quem abre o app). 20 min não precisa de
-- precisão sub-minuto. pg_cron aceita '* * * * *'.
select cron.schedule(
    'game-match-expire',
    '* * * * *',
    $$select public._expire_stale_game_matches()$$
);
