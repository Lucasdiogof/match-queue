-- RPCs publicas do matchmaking. Todas: security definer, search_path='',
-- exigem auth.uid() e membership do time, tomam o lock do time antes de
-- ler/escrever qualquer coisa, corrigem uma sessao vencida primeiro
-- (_expire_team_search_if_needed) e devolvem o mesmo read model completo
-- (_build_matchmaking_state) -- nunca so um "ok", sempre o estado inteiro
-- pronto pra Home renderizar sem uma segunda chamada.

-- Ponto de entrada principal: decide sozinho se o chamador vira SEARCHING
-- (ninguem buscando) ou entra na fila (alguem ja busca). Chamar de novo
-- sem ter saido do estado atual e idempotente -- nunca duplica sessao nem
-- entrada de fila, so devolve o estado corrente.
create function public.request_match_search(p_team_id uuid)
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

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.request_match_search(uuid) is
    'Vira SEARCHING se ninguem busca, senao entra na fila. Idempotente pro mesmo usuario.';

revoke execute on function public.request_match_search(uuid) from public, anon;
grant execute on function public.request_match_search(uuid) to authenticated;

-- Cancela a participacao do chamador: se ele e o SEARCHING atual, encerra
-- a sessao e promove o proximo da fila; se esta na fila, so remove a
-- linha dele (a ordem dos demais nunca muda, sequence e monotonico).
create function public.cancel_match_search(p_team_id uuid)
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
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    select * into v_queue_entry
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id;

    if v_queue_entry.id is not null then
        delete from public.match_search_queue where id = v_queue_entry.id;
        return public._build_matchmaking_state(p_team_id, v_user_id);
    end if;

    raise exception 'no active search or queue entry to cancel'
        using errcode = 'FQ015';
end;
$$;

comment on function public.cancel_match_search(uuid) is
    'Cancela a busca (promove o proximo) ou sai da fila do chamador, o que for aplicavel.';

revoke execute on function public.cancel_match_search(uuid) from public, anon;
grant execute on function public.cancel_match_search(uuid) to authenticated;

-- So o SEARCHING atual pode confirmar. Encerra a sessao como MATCH_FOUND e
-- promove o proximo da fila na mesma transacao.
create function public.report_match_found(p_team_id uuid)
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

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.report_match_found(uuid) is
    'So o SEARCHING atual pode chamar. Encerra a sessao e promove o proximo.';

revoke execute on function public.report_match_found(uuid) from public, anon;
grant execute on function public.report_match_found(uuid) to authenticated;

-- Read model puro para a Home. Tambem corrige expiracao vencida antes de
-- responder -- so abrir o app e suficiente pra corrigir o estado, sem
-- depender do cron nem de outro jogador ter agido.
create function public.get_team_matchmaking_state(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._expire_team_search_if_needed(p_team_id);

    return public._build_matchmaking_state(p_team_id, v_user_id);
end;
$$;

comment on function public.get_team_matchmaking_state(uuid) is
    'Read model do matchmaking do time para a Home: searching atual, fila, meu estado, server_now.';

revoke execute on function public.get_team_matchmaking_state(uuid) from public, anon;
grant execute on function public.get_team_matchmaking_state(uuid) to authenticated;
