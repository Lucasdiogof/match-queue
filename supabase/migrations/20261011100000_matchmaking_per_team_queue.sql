-- Fila real por Time (evolucao do matchmaking multi-time da Etapa 11).
--
-- MUDANCA DE ARQUITETURA, DELIBERADA E PEDIDA EXPLICITAMENTE: a Etapa 11
-- (20260918100000_matchmaking_multi_team.sql) fez "buscar" ocupar TODOS os
-- times vinculados a conta de uma vez (superbloco), porque a tela Jogar
-- parou de deixar escolher um time. O pedido desta etapa e o oposto: cada
-- Time tem sua PROPRIA fila, independente -- a mesma conta pode estar em
-- 1o lugar no Time A e 3o no Time B ao mesmo tempo, e so nao pode BUSCAR
-- (SEARCHING) em dois times ao mesmo tempo. Ou seja: escopo de fila = Time;
-- escopo do lock de disponibilidade = fc_account_id (a identidade que
-- efetivamente joga -- nao user_id, porque um usuario pode ter mais de uma
-- Conta FC/EA e cada uma e uma pessoa jogando de verdade dentro do jogo).
--
-- Volta pratica: match_search_sessions.team_id / match_search_queue.team_id
-- passam a ser, de novo, O UNICO time da linha (nao mais um "primario" de
-- um conjunto). match_search_session_teams / match_search_queue_teams
-- (as tabelas de juncao da Etapa 11) PARAM DE RECEBER LINHAS NOVAS a partir
-- daqui -- ficam como tabelas historicas mortas, nao apagadas (as linhas
-- antigas continuam existindo, so nunca mais crescem). Nao apago porque
-- nada depende de apagar, e reverter esquema fisico e mais risco do que
-- valor aqui.
--
-- get_team_player_statuses / get_team_match_search_history /
-- get_team_matchmaking_stats voltam a comparar team_id diretamente (cada
-- sessao/fila so pertence a um time de novo, entao o join na tabela de
-- juncao deixaria de enxergar tudo que for criado a partir de agora).
--
-- _build_matchmaking_state / get_team_matchmaking_state ficam intocadas:
-- nao sao chamadas por nenhum codigo Dart hoje (confirmado por auditoria),
-- entao mexer nelas seria escopo extra sem consumidor. Ficam obsoletas,
-- documentado aqui para quem for mexer depois.

-- ---------------------------------------------------------------------
-- 1. Preferencias de notificacao: novo evento PRIORITY_REQUESTED
-- ---------------------------------------------------------------------
alter table public.notification_preferences
    add column priority_requested_enabled boolean not null default true;

comment on column public.notification_preferences.priority_requested_enabled is
    'Push de PRIORITY_REQUESTED (alguem pediu prioridade na minha busca). Sub-toggle de matchmaking_enabled, mesmo padrao de queue_turn_enabled.';

create or replace function public._notification_allowed(
    p_user_id uuid,
    p_type public.notification_type
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select case p_type
        when 'YOUR_TURN' then coalesce(
            (select matchmaking_enabled and queue_turn_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'PRIORITY_REQUESTED' then coalesce(
            (select matchmaking_enabled and priority_requested_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRING' then coalesce(
            (select matchmaking_enabled and search_expiring_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRED' then coalesce(
            (select matchmaking_enabled and search_expired_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_MEMBER_JOINED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_LEADER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_SCORER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_ASSIST_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'WEEKEND_LEAGUE_FINISHED' then coalesce(
            (select weekend_league_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'RIVALS_DIVISION_CHANGED' then coalesce(
            (select rivals_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        else true
    end;
$$;

-- ---------------------------------------------------------------------
-- 2. _enqueue_notification ganha dedupe_key customizavel (PRIORITY_REQUESTED
--    precisa deduplicar por sessao + solicitante, nao so por sessao -- dois
--    companheiros diferentes pedindo prioridade na MESMA busca sao dois
--    eventos distintos, cada um deve gerar seu proprio push).
-- ---------------------------------------------------------------------
drop function if exists public._enqueue_notification(
    uuid, public.notification_type, uuid, uuid, jsonb
);

create function public._enqueue_notification(
    p_user_id uuid,
    p_type public.notification_type,
    p_team_id uuid,
    p_session_id uuid,
    p_payload jsonb default '{}'::jsonb,
    p_dedupe_key text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.notification_outbox (
        user_id, type, team_id, session_id, payload, dedupe_key
    )
    values (
        p_user_id,
        p_type,
        p_team_id,
        p_session_id,
        coalesce(p_payload, '{}'::jsonb),
        coalesce(
            p_dedupe_key,
            p_type::text || ':' || coalesce(p_session_id::text, gen_random_uuid()::text)
        )
    )
    on conflict (user_id, dedupe_key) do nothing;
end;
$$;

revoke execute on function public._enqueue_notification(
    uuid, public.notification_type, uuid, uuid, jsonb, text
) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. match_search_queue: dedupe por (time, CONTA), nao mais (time, usuario)
--    -- a identidade que ocupa uma vaga na fila e a Conta FC, nao a pessoa
--    (a mesma pessoa pode ter mais de uma Conta FC vinculada ao mesmo time).
-- ---------------------------------------------------------------------
alter table public.match_search_queue
    drop constraint if exists match_search_queue_unique_team_user;

create unique index match_search_queue_unique_team_fc_account
    on public.match_search_queue (team_id, fc_account_id)
    where fc_account_id is not null;

-- Garantia estrutural do LOCK GLOBAL: no maximo uma sessao SEARCHING por
-- Conta FC, em qualquer time, no banco -- e o que torna "a mesma identidade
-- nao busca em dois times ao mesmo tempo" verdade mesmo sob concorrencia,
-- nao so por disciplina das RPCs.
create unique index match_search_sessions_one_searching_per_fc_account
    on public.match_search_sessions (fc_account_id)
    where status = 'SEARCHING' and fc_account_id is not null;

-- Guarda de dupla participacao passa a comparar fc_account_id (a identidade
-- nova), nao mais user_id. Linhas sem fc_account_id (nunca deveriam
-- acontecer nas RPCs novas) nao sao checadas por esta guarda -- ela e rede
-- de seguranca, nao a unica fonte da regra.
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
        ) then
            raise exception 'fc account already queued for this team'
                using errcode = 'FQ017';
        end if;
    elsif tg_table_name = 'match_search_queue' then
        if exists (
            select 1 from public.match_search_sessions
            where team_id = new.team_id
              and fc_account_id = new.fc_account_id
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
-- 4. Locks: trava por Conta FC, junto com a trava por Time ja existente
--    (_lock_team_matchmaking). Ordem sempre: times (ordenados) primeiro,
--    Conta FC depois -- mesma logica de "ordem fixa evita deadlock" da
--    Etapa 11, so que agora o segundo tipo de recurso e a Conta, nao mais
--    um segundo time.
-- ---------------------------------------------------------------------
create function public._lock_fc_account_matchmaking(p_fc_account_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform pg_advisory_xact_lock(hashtext('fc_account_matchmaking:' || p_fc_account_id::text));
end;
$$;

revoke execute on function public._lock_fc_account_matchmaking(uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. Checagens centrais: time livre (sem SEARCHING) e conta livre (sem
--    SEARCHING em NENHUM time) -- a segunda e o lock global de
--    disponibilidade pedido explicitamente.
-- ---------------------------------------------------------------------
drop function if exists public._teams_free_for_search(uuid[]);

create function public._team_free_for_search(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select not exists (
        select 1 from public.match_search_sessions
        where team_id = p_team_id and status = 'SEARCHING'
    );
$$;

revoke execute on function public._team_free_for_search(uuid)
    from public, anon, authenticated;

create function public._fc_account_globally_searching(p_fc_account_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.match_search_sessions
        where fc_account_id = p_fc_account_id and status = 'SEARCHING'
    );
$$;

revoke execute on function public._fc_account_globally_searching(uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 6. Promocao por time, com "passar a vez" quando o candidato do topo da
--    fila ja esta buscando em OUTRO time (item 9 do pedido): a entrada dele
--    volta pro FINAL da fila deste time (novo `sequence`, mais alto que
--    qualquer um ja existente) e o proximo candidato e tentado -- sem
--    notificar ninguem nesse caso. Limitada ao numero de candidatos que
--    existiam no INICIO da chamada, pra nunca girar em loop infinito quando
--    sobra so gente ocupada (o time fica sem promover ninguem ate o
--    proximo evento relevante -- ver funcao seguinte).
-- ---------------------------------------------------------------------
drop function if exists public._promote_next_queued_players_for_teams(uuid[]);
drop function if exists public._promote_next_queued_player(uuid);

create function public._promote_next_queued_player_for_team(p_team_id uuid)
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
    where team_id = p_team_id;

    while v_attempts_left > 0 loop
        v_attempts_left := v_attempts_left - 1;

        select * into v_candidate
        from public.match_search_queue
        where team_id = p_team_id
        order by sequence
        limit 1;

        exit when v_candidate.id is null;

        if v_candidate.fc_account_id is not null then
            perform public._lock_fc_account_matchmaking(v_candidate.fc_account_id);
        end if;

        if v_candidate.fc_account_id is not null
            and public._fc_account_globally_searching(v_candidate.fc_account_id)
        then
            -- Passa a vez: a conta ja esta buscando em outro time agora.
            -- Volta pro final da fila DESTE time (sequence novo = mais alto
            -- que qualquer entrada existente), sem notificar ninguem (item
            -- 9: "sem push para Lucas"). Continua tentando o proximo.
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

revoke execute on function public._promote_next_queued_player_for_team(uuid)
    from public, anon, authenticated;

-- Depois que uma Conta FC termina de buscar (achou partida, cancelou ou
-- expirou) em p_freed_team_id, ela pode ser exatamente quem travava a
-- promocao de OUTRO time onde ja estava na fila (item 9, o inverso: quem
-- "passou a vez" antes agora pode ser promovido). Tenta de novo so nos
-- times onde esta Conta tem entrada de fila agora -- nunca varre o produto
-- inteiro.
create function public._retry_promotion_for_fc_account_queues(
    p_fc_account_id uuid,
    p_exclude_team_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_team_ids uuid[];
    v_team_id uuid;
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

    foreach v_team_id in array v_team_ids loop
        if public._team_free_for_search(v_team_id) then
            perform public._promote_next_queued_player_for_team(v_team_id);
            perform public._notify_matchmaking_changed(v_team_id);
        end if;
    end loop;
end;
$$;

revoke execute on function public._retry_promotion_for_fc_account_queues(uuid, uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 7. Expiracao lazy, agora por time direto (sem juncao) -- e reaproveita o
--    retry acima pra desbloquear outras filas da mesma conta expirada.
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
begin
    select * into v_session
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    if v_session.id is null or v_session.expires_at > now() then
        return false;
    end if;

    update public.match_search_sessions
    set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
    where id = v_session.id;

    perform public._enqueue_notification(
        v_session.user_id, 'SEARCH_EXPIRED', p_team_id, v_session.id, '{}'::jsonb
    );

    perform public._promote_next_queued_player_for_team(p_team_id);

    if v_session.fc_account_id is not null then
        perform public._retry_promotion_for_fc_account_queues(
            v_session.fc_account_id, p_team_id
        );
    end if;

    return true;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 8. request_match_search: ganha p_team_id explicito (a Central deixou de
--    existir escondendo o time -- agora quem busca escolhe Conta + TIME +
--    Modo, igual a Jogar sempre operou "no time selecionado"). So comeca a
--    buscar de verdade se (a) o time esta livre, (b) a fila do time esta
--    VAZIA (senao um pedido novo furaria a fila -- item 3: FIFO de
--    verdade) e (c) a Conta nao esta buscando em NENHUM outro time agora.
--    Qualquer uma falsa -> entra na fila deste time (nunca erro).
-- ---------------------------------------------------------------------
drop function if exists public.request_match_search(uuid, uuid, text);

create function public.request_match_search(
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
      and status = 'SEARCHING';
    if v_already_session.id is not null then
        return public.get_my_matchmaking_status(p_fc_account_id, p_team_id);
    end if;

    select * into v_already_queue
    from public.match_search_queue
    where team_id = p_team_id and fc_account_id = p_fc_account_id;
    if v_already_queue.id is not null then
        return public.get_my_matchmaking_status(p_fc_account_id, p_team_id);
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    select count(*) into v_queue_count
    from public.match_search_queue where team_id = p_team_id;

    if v_queue_count = 0
        and public._team_free_for_search(p_team_id)
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
    return public.get_my_matchmaking_status(p_fc_account_id, p_team_id);
end;
$$;

comment on function public.request_match_search(uuid, uuid, uuid, text) is
    'Busca por Conta+Time+Modo. So comeca na hora se o time e a fila estiverem livres e a conta nao estiver buscando em outro lugar -- senao entra na fila deste time.';

revoke execute on function public.request_match_search(uuid, uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, uuid, uuid, text)
    to authenticated;

-- ---------------------------------------------------------------------
-- 9. cancel_match_search: cancela a busca ATIVA da conta, em qualquer time
--    (so pode haver uma, pelo lock global). Promove o time liberado e tenta
--    de novo as OUTRAS filas onde esta conta esperava (pode desbloquear
--    quem estava so esperando ela ficar livre).
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

    perform public._promote_next_queued_player_for_team(v_team_id);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_fc_account_queues(p_fc_account_id, v_team_id);

    return public.get_my_matchmaking_status(p_fc_account_id, v_team_id);
end;
$$;

revoke execute on function public.cancel_match_search(uuid) from public, anon;
grant execute on function public.cancel_match_search(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 10. leave_match_search_queue: NOVA. cancel_match_search so sabe cancelar
--     a busca ATIVA (unica, pelo lock global); sair de uma fila especifica
--     precisa dizer QUAL time, porque a mesma conta pode estar em varias
--     filas ao mesmo tempo agora (item 4).
-- ---------------------------------------------------------------------
create function public.leave_match_search_queue(
    p_fc_account_id uuid,
    p_team_id uuid
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
    where team_id = p_team_id and fc_account_id = p_fc_account_id;

    if v_entry.id is null then
        raise exception 'not in this team queue' using errcode = 'FQ047';
    end if;

    delete from public.match_search_queue where id = v_entry.id;

    -- Sair da fila nunca gera notificacao (item 4: "sem enviar notificacao").
    perform public._notify_matchmaking_changed(p_team_id);

    return public.get_my_matchmaking_status(p_fc_account_id, p_team_id);
end;
$$;

comment on function public.leave_match_search_queue(uuid, uuid) is
    'Sai da fila de UM time especifico -- a conta pode continuar em filas de outros times.';

revoke execute on function public.leave_match_search_queue(uuid, uuid)
    from public, anon;
grant execute on function public.leave_match_search_queue(uuid, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- 11. report_match_found_and_start_game: mesma ideia do cancel, mas marca
--     MATCH_FOUND e cria game_matches. Sem push sobre a partida encontrada
--     (item 27).
-- ---------------------------------------------------------------------
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

    perform public._promote_next_queued_player_for_team(v_team_id);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_fc_account_queues(p_fc_account_id, v_team_id);

    return public.get_my_matchmaking_status(p_fc_account_id, v_team_id);
end;
$$;

revoke execute on function public.report_match_found_and_start_game(uuid)
    from public, anon;
grant execute on function public.report_match_found_and_start_game(uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- 12. get_my_matchmaking_status: agora por Conta + TIME (a tela Jogar
--     sempre opera sobre o time selecionado). Devolve tambem a fila
--     inteira e visivel (item 2/25) e, quando a conta esta ocupada
--     buscando OUTRO time, avisa isso explicitamente em vez de so
--     esconder o botao.
-- ---------------------------------------------------------------------
drop function if exists public.get_my_matchmaking_status(uuid);

create function public.get_my_matchmaking_status(
    p_fc_account_id uuid,
    p_team_id uuid
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
      and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue
        from public.match_search_queue
        where team_id = p_team_id and fc_account_id = p_fc_account_id;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(*) + 1 into v_my_position
            from public.match_search_queue
            where team_id = p_team_id and sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;

        select * into v_other_session
        from public.match_search_sessions
        where team_id = p_team_id and status = 'SEARCHING';

        select * into v_elsewhere_session
        from public.match_search_sessions
        where fc_account_id = p_fc_account_id and status = 'SEARCHING'
          and team_id <> p_team_id;
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
        where q.team_id = p_team_id
    ) as ranked;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'fc_account_id', p_fc_account_id,
        'team_id', p_team_id,
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

comment on function public.get_my_matchmaking_status(uuid, uuid) is
    'Estado de Conta+Time: minha busca/posicao NESTE time, quem me bloqueia, se estou buscando em outro time, e a fila inteira e visivel.';

revoke execute on function public.get_my_matchmaking_status(uuid, uuid)
    from public, anon;
grant execute on function public.get_my_matchmaking_status(uuid, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- 13. request_match_search_priority: NOVA. So um pedido humano -- nao muda
--     fila/busca/lock/titular (item 13). Dedupe por (sessao ativa,
--     solicitante) via o dedupe_key customizado da secao 2.
-- ---------------------------------------------------------------------
create function public.request_match_search_priority(
    p_fc_account_id uuid,
    p_team_id uuid
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
    where team_id = p_team_id and status = 'SEARCHING';

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

comment on function public.request_match_search_priority(uuid, uuid) is
    'Pedido humano de prioridade -- nunca altera fila/busca/lock, so notifica quem esta buscando.';

revoke execute on function public.request_match_search_priority(uuid, uuid)
    from public, anon;
grant execute on function public.request_match_search_priority(uuid, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- 14. Leitura por time: voltam a comparar team_id direto (cada sessao/fila
--     pertence a UM time de novo -- a juncao da Etapa 11 parou de ser
--     necessaria pra escrita nova, entao teria parado de enxergar dado
--     novo se estas 3 continuassem juntando por ela).
-- ---------------------------------------------------------------------
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
                    where s.team_id = p_team_id and s.user_id = m.user_id
                      and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    where q.team_id = p_team_id and q.user_id = m.user_id
                ) then 'QUEUED'
                when p.last_active_at is not null
                    and p.last_active_at >= now() - interval '60 minutes'
                    then 'RECENTLY_ACTIVE'
                else 'OFFLINE'
            end,
            'queue_position', (
                select row_number() over (order by q.sequence)
                from public.match_search_queue as q
                where q.team_id = p_team_id and q.user_id = m.user_id
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
        left join public.profiles as p on p.id = s.user_id
        where s.team_id = p_team_id
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
            s.user_id, s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    )
    select jsonb_build_object(
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
            s.user_id, s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
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
