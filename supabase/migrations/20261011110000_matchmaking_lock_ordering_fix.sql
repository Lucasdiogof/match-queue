-- Corrige uma ordem de lock inconsistente que podia gerar deadlock real
-- (nao corrupcao de dado -- o Postgres detecta e aborta uma das duas
-- transacoes -- mas um erro evitavel) entre duas contas cancelando/
-- reportando busca ao mesmo tempo quando cada uma esta na fila do time da
-- outra.
--
-- Problema: request_match_search trava (time, depois conta). Mas
-- cancel_match_search/report_match_found_and_start_game travavam (conta,
-- depois o time liberado), e _retry_promotion_for_fc_account_queues travava
-- MAIS times depois disso -- em duas chamadas de lock separadas, cada uma
-- ordenada dentro de si mas nao em relacao a ordem entre CONTA e TIME.
-- Exemplo real: conta X cancela (trava X, trava T5); conta Y cancela ao
-- mesmo tempo (trava Y, trava T5) -- se X esta na fila de T(Y-livre) e
-- vice-versa, as dias travas subsequentes podem se cruzar.
--
-- Correcao: TODA funcao passa a levantar o conjunto COMPLETO de times
-- relevantes (o time liberado + todo time onde esta conta ja espera na
-- fila) ANTES de travar qualquer coisa, trava esse conjunto inteiro
-- ordenado (mesma rotina de sempre, _lock_teams_matchmaking), SO DEPOIS
-- trava a conta -- e entao rele o estado fresco (o "peek" inicial pode
-- ficar obsoleto entre o momento de levantar o conjunto e travar; reler
-- depois de travar e o que garante corretude, nao o peek em si).
-- _retry_promotion_for_fc_account_queues para de travar por conta propria:
-- quem chama ja segura todos os locks necessarios.

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
    v_team_id uuid;
begin
    if p_fc_account_id is null then
        return;
    end if;

    -- O chamador ja travou todos os times relevantes (incluindo estes) --
    -- ver comentario da migration. So itera e promove onde couber.
    for v_team_id in
        select distinct team_id
        from public.match_search_queue
        where fc_account_id = p_fc_account_id and team_id <> p_exclude_team_id
    loop
        if public._team_free_for_search(v_team_id) then
            perform public._promote_next_queued_player_for_team(v_team_id);
            perform public._notify_matchmaking_changed(v_team_id);
        end if;
    end loop;
end;
$$;

create or replace function public.cancel_match_search(p_fc_account_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_peek public.match_search_sessions;
    v_team_ids uuid[];
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

    -- Peek sem lock: so pra saber QUAIS times travar. Reconferido abaixo,
    -- ja com os locks -- nunca confiado pra decidir nada sozinho.
    select * into v_peek
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_peek.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    select coalesce(array_agg(distinct tid order by tid), array[]::uuid[])
        into v_team_ids
    from (
        select v_peek.team_id as tid
        union
        select team_id from public.match_search_queue
        where fc_account_id = p_fc_account_id
    ) as teams(tid);

    perform public._lock_teams_matchmaking(v_team_ids);
    perform public._lock_fc_account_matchmaking(p_fc_account_id);

    -- Rele fresco: o que importa e o estado agora, com os locks seguros,
    -- nao o peek de antes.
    select * into v_searching
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    update public.match_search_sessions
    set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player_for_team(v_searching.team_id);
    perform public._notify_matchmaking_changed(v_searching.team_id);
    perform public._retry_promotion_for_fc_account_queues(
        p_fc_account_id, v_searching.team_id
    );

    return public.get_my_matchmaking_status(p_fc_account_id, v_searching.team_id);
end;
$$;

create or replace function public.report_match_found_and_start_game(
    p_fc_account_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_peek public.match_search_sessions;
    v_team_ids uuid[];
    v_searching public.match_search_sessions;
    v_event_id uuid;
    v_mode text;
    v_snapshot jsonb;
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

    select * into v_peek
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_peek.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    select coalesce(array_agg(distinct tid order by tid), array[]::uuid[])
        into v_team_ids
    from (
        select v_peek.team_id as tid
        union
        select team_id from public.match_search_queue
        where fc_account_id = p_fc_account_id
    ) as teams(tid);

    perform public._lock_teams_matchmaking(v_team_ids);
    perform public._lock_fc_account_matchmaking(p_fc_account_id);

    select * into v_searching
    from public.match_search_sessions
    where fc_account_id = p_fc_account_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

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
        (v_user_id, v_searching.team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(), v_searching.fc_account_id,
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_player_for_team(v_searching.team_id);
    perform public._notify_matchmaking_changed(v_searching.team_id);
    perform public._retry_promotion_for_fc_account_queues(
        p_fc_account_id, v_searching.team_id
    );

    return public.get_my_matchmaking_status(p_fc_account_id, v_searching.team_id);
end;
$$;

-- _expire_team_search_if_needed continua chamada com o TIME ja travado pelo
-- chamador (convencao do produto inteiro, nao so desta etapa -- mudar isso
-- exigiria revisar toda RPC que chama expiracao lazy). Residual: ela ainda
-- trava as OUTRAS filas da conta expirada depois disso, o que pode colidir
-- em teoria com outra transacao fazendo o mesmo na ordem inversa. Diferente
-- de corrupcao de dado: o Postgres detecta o ciclo e aborta uma das duas
-- transacoes (o cliente ve um erro e pode tentar de novo) -- documentado
-- como risco residual conhecido, aceito por ora, nao escondido.
comment on function public._expire_team_search_if_needed(uuid) is
    'Expira lazy o time (ja travado pelo chamador) e promove a fila dele + retenta as outras filas da conta expirada. Risco residual de deadlock (auto-detectado pelo Postgres, nao corrompe dado) entre duas expiracoes cruzadas simultaneas -- ver migration 20261011110000.';
