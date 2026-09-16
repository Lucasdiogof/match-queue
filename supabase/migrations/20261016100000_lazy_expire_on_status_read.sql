-- get_my_matchmaking_status era a UNICA RPC de matchmaking que nunca
-- chamava _expire_team_search_if_needed antes de ler o estado -- toda RPC
-- de ESCRITA (request_match_search, cancel_match_search,
-- leave_match_search_queue, etc.) ja faz essa expiracao lazy, exatamente
-- pelo motivo que o proprio comentario de _expire_team_search_if_needed
-- documenta (20260910100100_matchmaking_helpers.sql): corrigir uma sessao
-- vencida ANTES de qualquer RPC decidir o que fazer, "mesmo se o cron
-- ainda nao rodou".
--
-- Sem isso, o app fazia exatamente o que deveria (refreshSilently no
-- instante em que o timer bate 00:00), mas a leitura so via o status ainda
-- como SEARCHING, porque so o cron (a cada 30s) ou uma escrita em qualquer
-- RPC deste time marcava EXPIRED. Resultado: a bottomsheet de "tempo
-- esgotado" so aparecia quando o cron alcancava aquela sessao especifica
-- (ate ~30s depois do timer chegar a zero, ~10-15s na media -- exatamente
-- o atraso reportado), nunca no instante do proprio refresh.
create or replace function public.get_my_matchmaking_status(
    p_fc_account_id uuid,
    p_team_id uuid,
    p_game_mode text
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

    perform public._lock_team_matchmaking(p_team_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select default_search_duration_seconds into v_duration
    from public.teams where id = p_team_id;

    select exists (
        select 1 from public.fc_account_teams
        where fc_account_id = p_fc_account_id and team_id = p_team_id
    ) into v_linked;

    select * into v_my_session
    from public.match_search_sessions
    where team_id = p_team_id and fc_account_id = p_fc_account_id
      and game_mode = p_game_mode and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue
        from public.match_search_queue
        where team_id = p_team_id and fc_account_id = p_fc_account_id
          and game_mode = p_game_mode;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(*) + 1 into v_my_position
            from public.match_search_queue
            where team_id = p_team_id and game_mode = p_game_mode
              and sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;

        select * into v_other_session
        from public.match_search_sessions
        where team_id = p_team_id and game_mode = p_game_mode
          and status = 'SEARCHING';

        select * into v_elsewhere_session
        from public.match_search_sessions
        where fc_account_id = p_fc_account_id and status = 'SEARCHING'
          and (team_id <> p_team_id or game_mode <> p_game_mode);
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
        where q.team_id = p_team_id and q.game_mode = p_game_mode
    ) as ranked;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'fc_account_id', p_fc_account_id,
        'team_id', p_team_id,
        'game_mode', p_game_mode,
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
