-- Liga a maquina de estados existente a outbox. Nenhuma regra de fila muda:
-- os mesmos locks, a mesma promocao, os mesmos FQ00x. As funcoes so passam a
-- gravar uma linha na outbox quando um evento notificavel realmente ocorre.

-- YOUR_TURN nasce AQUI e em nenhum outro lugar.
--
-- Esta e a unica funcao que cria sessao a partir da fila, chamada por
-- match-found, por cancel de quem estava buscando, pela expiracao lazy e
-- pelo cron. Enfileirar aqui cobre os quatro caminhos sem repetir logica em
-- nenhuma RPC -- e evita o erro classico de esquecer um deles.
--
-- Quem toca em "Buscar" sem ninguem na frente NAO passa por aqui (a sessao e
-- inserida direto em request_match_search), entao nao recebe "sua vez": nao
-- houve espera nenhuma.
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

    insert into public.match_search_sessions (team_id, user_id, status, started_at, expires_at)
    select
        p_team_id,
        v_next.user_id,
        'SEARCHING',
        now(),
        now() + make_interval(secs => t.default_search_duration_seconds)
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

-- SEARCH_EXPIRED para quem perdeu a vez. Quem for promovido em seguida
-- recebe YOUR_TURN pela funcao acima -- sao duas pessoas diferentes, dois
-- eventos diferentes.
create or replace function public._expire_team_search_if_needed(p_team_id uuid)
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
        v_session.user_id,
        'SEARCH_EXPIRED',
        p_team_id,
        v_session.id,
        '{}'::jsonb
    );

    perform public._promote_next_queued_player(p_team_id);
    return true;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

-- Aviso de 30 segundos.
--
-- Precisa ser server-side: um timer no aparelho so funcionaria com o app
-- aberto, que e justamente o caso em que a notificacao nao faz falta.
--
-- A janela tem o mesmo tamanho do intervalo do cron (30s), entao toda sessao
-- passa por ela em exatamente um tick. O indice unico de dedupe_key garante
-- o resto: mesmo que dois ticks se sobreponham, sai uma notificacao so por
-- sessao.
create function public.enqueue_expiring_search_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_session record;
    v_count integer := 0;
begin
    for v_session in
        select id, team_id, user_id, expires_at
        from public.match_search_sessions
        where status = 'SEARCHING'
          and expires_at > now()
          and expires_at <= now() + interval '30 seconds'
    loop
        perform public._enqueue_notification(
            v_session.user_id,
            'SEARCH_EXPIRING',
            v_session.team_id,
            v_session.id,
            jsonb_build_object('expires_at', to_jsonb(v_session.expires_at))
        );
        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;

revoke execute on function public.enqueue_expiring_search_notifications()
    from public, anon, authenticated;

-- Um job de cron so, em vez de um por tarefa.
--
-- A ordem importa: expirar primeiro, avisar depois. O contrario mandaria
-- "faltam 30 segundos" para uma sessao que morre no mesmo tick.
create function public.run_matchmaking_maintenance()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.process_expired_searches();
    perform public.enqueue_expiring_search_notifications();
end;
$$;

revoke execute on function public.run_matchmaking_maintenance()
    from public, anon, authenticated;

-- cron.schedule faz upsert pelo nome do job: reaproveita o agendamento de
-- 30s da Etapa 5 em vez de criar um segundo job concorrente.
select cron.schedule(
    'matchmaking-expire-searches',
    '30 seconds',
    $$select public.run_matchmaking_maintenance();$$
);
