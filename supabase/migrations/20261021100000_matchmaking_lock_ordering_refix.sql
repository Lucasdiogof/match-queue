-- Reaplica a correcao de ordem de lock de 20261011110000, desfeita sem
-- querer por duas migrations posteriores.
--
-- Historico:
-- - 20261011110000_matchmaking_lock_ordering_fix fez cancel_match_search e
--   report_match_found_and_start_game travarem TODOS os times relevantes
--   (ordenados) ANTES da conta, igual request_match_search (time -> conta).
-- - 20261013102700_matchmaking_per_mode_queue recriou as duas via
--   "create or replace" a partir de uma copia anterior a essa correcao:
--   voltaram a travar conta -> time, e _retry_promotion_* voltou a travar os
--   outros times por conta propria, depois da conta.
-- - 20261016102000_eliminate_profile_concept trocou conta FC por usuario e
--   manteve a ordem errada (usuario -> time -> outros times). E o que esta em
--   producao ate aqui.
--
-- Efeito: request_match_search trava (time, usuario); cancel/report travam
-- (usuario, time, outros times). Duas transacoes concorrentes podem se
-- cruzar e o Postgres aborta uma delas com deadlock_detected (40P01). Nao
-- corrompe dado, mas o usuario ve um erro evitavel ao cancelar/iniciar
-- partida.
--
-- Correcao (mesma ideia de 20261011110000, adaptada a usuario + modo):
-- 1. "peek" sem lock para descobrir QUAIS times importam: o time da sessao
--    SEARCHING + todo time onde o usuario esta na fila;
-- 2. trava esse conjunto inteiro, ordenado (_lock_teams_matchmaking exige
--    array ordenado);
-- 3. SO ENTAO trava o usuario;
-- 4. rele o estado fresco -- o peek pode ter ficado obsoleto; decidir pelo
--    estado relido e o que garante corretude.
--
-- Depois do lock do usuario ninguem mais coloca esse usuario numa fila nova
-- (request_match_search tambem trava o usuario), entao o conjunto relido e
-- estavel. Se ele mudou entre o peek e o lock (janela de microssegundos), os
-- times que faltam sao travados em seguida: volta a ser a ordem antiga so
-- nesse caso raro, com o mesmo risco residual de antes (deadlock detectado
-- pelo Postgres, nunca dado corrompido).
--
-- _retry_promotion_for_user_queues NAO muda: continua travando os times que
-- percorre porque _expire_team_search_if_needed depende disso. Vindo de
-- cancel/report, esses times ja estao travados nesta transacao e
-- pg_advisory_xact_lock e reentrante -- vira no-op, sem nova espera.
--
-- Assinaturas, retorno, errcodes e grants ficam identicos: so a ordem dos
-- locks muda. Idempotente ("create or replace" com a mesma assinatura).

create or replace function public._matchmaking_user_team_ids(
    p_user_id uuid,
    p_extra_team_id uuid
)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(array_agg(distinct tid order by tid), array[]::uuid[])
    from (
        select p_extra_team_id as tid where p_extra_team_id is not null
        union
        select team_id from public.match_search_queue where user_id = p_user_id
    ) as teams(tid);
$$;

comment on function public._matchmaking_user_team_ids(uuid, uuid) is
    'Times que uma RPC de matchmaking precisa travar para o usuario: o time informado + todo time onde ele esta na fila. Ordenado, pronto para _lock_teams_matchmaking. Ver migration 20261021100000.';

revoke execute on function public._matchmaking_user_team_ids(uuid, uuid)
    from public, anon, authenticated;

-- Trava times -> usuario na ordem canonica e devolve a sessao SEARCHING
-- relida DEPOIS dos locks (id null se nao houver).
create or replace function public._lock_user_search_for_update(p_user_id uuid)
returns public.match_search_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_peek_team_id uuid;
    v_locked uuid[];
    v_fresh uuid[];
    v_missing uuid[];
    v_searching public.match_search_sessions;
begin
    select team_id into v_peek_team_id
    from public.match_search_sessions
    where user_id = p_user_id and status = 'SEARCHING'
    limit 1;

    v_locked := public._matchmaking_user_team_ids(p_user_id, v_peek_team_id);
    perform public._lock_teams_matchmaking(v_locked);
    perform public._lock_user_matchmaking(p_user_id);

    select * into v_searching
    from public.match_search_sessions
    where user_id = p_user_id and status = 'SEARCHING';

    v_fresh := public._matchmaking_user_team_ids(p_user_id, v_searching.team_id);
    select coalesce(array_agg(t order by t), array[]::uuid[]) into v_missing
    from unnest(v_fresh) as t
    where not (t = any (v_locked));

    if array_length(v_missing, 1) is not null then
        perform public._lock_teams_matchmaking(v_missing);
    end if;

    return v_searching;
end;
$$;

comment on function public._lock_user_search_for_update(uuid) is
    'Ordem canonica de lock do matchmaking (times ordenados -> usuario) para cancel/report. Devolve a sessao SEARCHING relida com os locks seguros. Ver migration 20261021100000.';

revoke execute on function public._lock_user_search_for_update(uuid)
    from public, anon, authenticated;

create or replace function public.cancel_match_search()
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

    v_searching := public._lock_user_search_for_update(v_user_id);

    if v_searching.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;

    update public.match_search_sessions
    set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player_for_team(
        v_team_id, v_searching.game_mode
    );
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_searching.game_mode);
end;
$$;

revoke execute on function public.cancel_match_search() from public, anon;
grant execute on function public.cancel_match_search() to authenticated;

create or replace function public.report_match_found_and_start_game()
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

    v_searching := public._lock_user_search_for_update(v_user_id);

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;

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
         weekend_league_event_id, status, started_at,
         fc_squad_id, squad_snapshot)
    values
        (v_user_id, v_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(),
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_player_for_team(v_team_id, v_mode);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_mode);
end;
$$;

revoke execute on function public.report_match_found_and_start_game()
    from public, anon;
grant execute on function public.report_match_found_and_start_game()
    to authenticated;
