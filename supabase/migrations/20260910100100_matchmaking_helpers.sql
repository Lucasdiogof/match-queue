-- Helpers internos do matchmaking. Nenhum tem grant pra anon/authenticated
-- -- sao chamados so pelas RPCs publicas da proxima migration, que rodam
-- como o mesmo dono das functions (security definer nao muda quem pode
-- EXECUTAR a function chamadora, so o papel efetivo DENTRO dela).
--
-- Continuando o namespace de erro FQ00x das Etapas 3-4 (nunca PTxxx):
--   FQ012 permissao negada (reaproveitado -- "nao e membro do time")
--   FQ015 nenhuma busca/fila ativa pra cancelar ou confirmar
--   FQ016 quem chamou nao e o SEARCHING atual
--   FQ017 jogador ja esta na outra metade do estado (searching+queued)
--   FQ018 time inativo, nenhuma busca nova

-- Serializa toda operacao de escrita do matchmaking de um time por uma
-- unica chave. Isso e o que transforma "duas requests no mesmo
-- milissegundo" em "uma espera a outra terminar a transacao inteira":
-- request, cancel, match-found e a expiracao lazy/cron todas tomam este
-- lock antes de ler ou escrever qualquer coisa do time.
create function public._lock_team_matchmaking(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform pg_advisory_xact_lock(hashtext('match_search:' || p_team_id::text));
end;
$$;

revoke execute on function public._lock_team_matchmaking(uuid)
    from public, anon, authenticated;

-- Corrige uma sessao SEARCHING vencida ANTES de qualquer RPC decidir o que
-- fazer -- e o que garante que a fila avanca mesmo se o cron ainda nao
-- rodou e ninguem tocou no timer no momento exato em que ele chegou a
-- zero. So mexe em algo se realmente existir um SEARCHING com
-- expires_at no passado; caso contrario e um no-op barato.
--
-- Precisa ser chamada com o lock de _lock_team_matchmaking ja adquirido
-- pelo chamador -- ela mesma nao tenta adquiri-lo, pra nao serializar tudo
-- duas vezes dentro da mesma transacao.
create function public._expire_team_search_if_needed(p_team_id uuid)
returns void
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
        return;
    end if;

    update public.match_search_sessions
    set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
    where id = v_session.id;

    perform public._promote_next_queued_player(p_team_id);
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid)
    from public, anon, authenticated;

-- Unica fonte de verdade de "quem vira o proximo SEARCHING": chamada por
-- match-found, cancel (de quem estava SEARCHING) e pela expiracao -- nunca
-- duplicada dentro de cada uma delas. Le a duracao de busca do time NA
-- HORA da promocao (nunca a duracao de quando a sessao anterior comecou),
-- por isso funciona corretamente mesmo se o dono mudar a configuracao do
-- time enquanto alguem esta na fila.
create function public._promote_next_queued_player(p_team_id uuid)
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

    return v_new_session;
end;
$$;

revoke execute on function public._promote_next_queued_player(uuid)
    from public, anon, authenticated;

-- Monta o read model completo devolvido por toda RPC publica (request,
-- cancel, match-found, get-state) -- uma unica fonte de verdade pro
-- formato da resposta, nunca reconstruida ad-hoc em cada uma. server_now
-- vai em todo payload para o Flutter calibrar o timer contra o relogio do
-- servidor, nunca so contra o DateTime.now() do aparelho.
create function public._build_matchmaking_state(p_team_id uuid, p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_duration integer;
    v_searching public.match_search_sessions;
    v_queue jsonb;
    v_my_state text;
    v_my_position integer;
begin
    select default_search_duration_seconds into v_duration
    from public.teams
    where id = p_team_id;

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', ranked.user_id,
            'display_name', ranked.display_name,
            'avatar_url', ranked.avatar_url,
            'position', ranked.position,
            'joined_at', ranked.joined_at
        ) order by ranked.position
    ), '[]'::jsonb)
    into v_queue
    from (
        select
            q.user_id,
            p.display_name,
            p.avatar_url,
            q.joined_at,
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.profiles as p on p.id = q.user_id
        where q.team_id = p_team_id
    ) as ranked;

    if v_searching.id is not null and v_searching.user_id = p_user_id then
        v_my_state := 'SEARCHING';
        v_my_position := null;
    else
        select ranked.position into v_my_position
        from (
            select user_id, row_number() over (order by sequence) as position
            from public.match_search_queue
            where team_id = p_team_id
        ) as ranked
        where ranked.user_id = p_user_id;

        v_my_state := case when v_my_position is not null then 'QUEUED' else 'NONE' end;
    end if;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'search_duration_seconds', v_duration,
        'searching', case when v_searching.id is null then null else jsonb_build_object(
            'session_id', v_searching.id,
            'user_id', v_searching.user_id,
            'display_name', (select display_name from public.profiles where id = v_searching.user_id),
            'avatar_url', (select avatar_url from public.profiles where id = v_searching.user_id),
            'started_at', to_jsonb(v_searching.started_at),
            'expires_at', to_jsonb(v_searching.expires_at)
        ) end,
        'queue', v_queue,
        'my_state', v_my_state,
        'my_position', v_my_position
    );
end;
$$;

revoke execute on function public._build_matchmaking_state(uuid, uuid)
    from public, anon, authenticated;
