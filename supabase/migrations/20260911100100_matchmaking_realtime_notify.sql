-- Liga as RPCs da Etapa 5 ao sinal de invalidacao. Nenhuma regra de
-- negocio muda aqui: mesmo lock, mesma atomicidade, mesmos erros FQ00x,
-- mesma expiracao lazy, mesma promocao. A unica diferenca e uma chamada a
-- _notify_matchmaking_changed no ponto em que a operacao ja terminou.
--
-- Regra de emissao: no maximo UMA notificacao por transacao, e so quando
-- algo realmente mudou. Em particular get_team_matchmaking_state e
-- chamada em todo refresh -- se ela notificasse sempre, cada leitura de um
-- cliente viraria um evento para todos os outros, que leriam de novo, que
-- notificariam de novo. Por isso a expiracao lazy passou a dizer se agiu.

-- Antes retornava void. Agora devolve se realmente expirou algo, para o
-- chamador saber se precisa notificar. Troca de tipo de retorno exige
-- drop + create; as functions que a chamam sao resolvidas em tempo de
-- execucao e estao todas recriadas logo abaixo, na mesma transacao.
drop function public._expire_team_search_if_needed(uuid);

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

    perform public._promote_next_queued_player(p_team_id);
    return true;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

create or replace function public.request_match_search(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_is_active boolean;
    v_expired boolean;
    v_searching public.match_search_sessions;
    v_existing_queue public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    v_expired := public._expire_team_search_if_needed(p_team_id);

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    -- Chamadas repetidas de quem ja esta no estado nao mudam nada, entao so
    -- notificam se a expiracao lazy acima tiver mexido em alguma coisa.
    if v_searching.id is not null and v_searching.user_id = v_user_id then
        if v_expired then
            perform public._notify_matchmaking_changed(p_team_id);
        end if;
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    select * into v_existing_queue
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id;

    if v_existing_queue.id is not null then
        if v_expired then
            perform public._notify_matchmaking_changed(p_team_id);
        end if;
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    if v_searching.id is null then
        insert into public.match_search_sessions (team_id, user_id, status, started_at, expires_at)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds)
        from public.teams as t
        where t.id = p_team_id;
    else
        insert into public.match_search_queue (team_id, user_id)
        values (p_team_id, v_user_id);
    end if;

    perform public._notify_matchmaking_changed(p_team_id);
    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

create or replace function public.cancel_match_search(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_queue_entry public.match_search_queue;
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

    if v_searching.id is not null and v_searching.user_id = v_user_id then
        update public.match_search_sessions
        set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
        where id = v_searching.id;

        perform public._promote_next_queued_player(p_team_id);
        perform public._notify_matchmaking_changed(p_team_id);
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    select * into v_queue_entry
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id;

    if v_queue_entry.id is not null then
        delete from public.match_search_queue where id = v_queue_entry.id;
        perform public._notify_matchmaking_changed(p_team_id);
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    -- Sem retorno util: a excecao desfaz a transacao inteira, inclusive uma
    -- eventual expiracao lazy acima. Nada foi commitado, entao tambem nao
    -- ha o que notificar.
    raise exception 'no active search or queue entry to cancel'
        using errcode = 'FQ015';
end;
$$;

create or replace function public.report_match_found(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
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

    update public.match_search_sessions
    set status = 'MATCH_FOUND', finish_reason = 'MATCH_FOUND', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player(p_team_id);
    perform public._notify_matchmaking_changed(p_team_id);

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

create or replace function public.get_team_matchmaking_state(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_expired boolean;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    v_expired := public._expire_team_search_if_needed(p_team_id);

    -- Leitura pura nao notifica. So avisa os outros clientes quando a
    -- propria leitura corrigiu uma sessao vencida.
    if v_expired then
        perform public._notify_matchmaking_changed(p_team_id);
    end if;

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

-- O cron tambem precisa avisar: sem isto, uma busca que expira com todo
-- mundo parado so apareceria no proximo refresh manual de cada cliente.
create or replace function public.process_expired_searches()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_team record;
    v_count integer := 0;
begin
    for v_team in
        select distinct team_id
        from public.match_search_sessions
        where status = 'SEARCHING' and expires_at <= now()
    loop
        perform public._lock_team_matchmaking(v_team.team_id);

        if public._expire_team_search_if_needed(v_team.team_id) then
            perform public._notify_matchmaking_changed(v_team.team_id);
            v_count := v_count + 1;
        end if;
    end loop;

    return v_count;
end;
$$;

revoke execute on function public.process_expired_searches()
    from public, anon, authenticated;
