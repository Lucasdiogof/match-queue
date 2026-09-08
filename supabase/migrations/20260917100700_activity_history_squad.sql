-- Historico passa a mostrar o squad usado na partida.
--
-- Le do SNAPSHOT e nao do squad vivo: o objetivo do historico e dizer o que
-- aconteceu naquele dia, e o squad de hoje pode ja estar diferente. Buscas
-- (SEARCH) nao ganham o campo -- ali ainda nao existe partida, entao nao ha
-- escalacao congelada.

create or replace function public.get_team_activity_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_occurred_at timestamptz default null,
    p_cursor_id uuid default null,
    p_scope text default 'ALL',
    p_game_result text default null,
    p_search_status text default null,
    p_user_id uuid default null,
    p_from timestamptz default null,
    p_to timestamptz default null,
    p_fc_account_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
    v_scope text := coalesce(p_scope, 'ALL');
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
            row_number() over (order by occurred_at desc, id desc) as ord,
            item
        from (
            select
                g.ended_at as occurred_at,
                g.id as id,
                jsonb_build_object(
                    'type', 'GAME',
                    'id', g.id,
                    'user_id', g.user_id,
                    'display_name', coalesce(p.display_name, ''),
                    'avatar_url', p.avatar_url,
                    'game_mode', g.game_mode,
                    'status', g.status,
                    'result', g.result,
                    'goals_for', g.goals_for,
                    'goals_against', g.goals_against,
                    'started_at', to_jsonb(g.started_at),
                    'ended_at', to_jsonb(g.ended_at),
                    'weekend_league_number', we.number,
                    'fc_account_id', g.fc_account_id,
                    'fc_account_name', a.name,
                    'fc_squad_id', g.fc_squad_id,
                    'fc_squad_name', g.squad_snapshot ->> 'name',
                    'fc_formation_code', g.squad_snapshot ->> 'formation'
                ) as item
            from public.game_matches as g
            left join public.profiles as p on p.id = g.user_id
            left join public.weekend_league_events as we
                on we.id = g.weekend_league_event_id
            left join public.user_fc_accounts as a on a.id = g.fc_account_id
            where g.team_id = p_team_id
              and g.ended_at is not null
              and v_scope <> 'SEARCHES'
              and (p_game_result is null or g.result = p_game_result)
              and (p_user_id is null or g.user_id = p_user_id)
              and (p_fc_account_id is null or g.fc_account_id = p_fc_account_id)
              and (p_from is null or g.ended_at >= p_from)
              and (p_to is null or g.ended_at < p_to)
              and (
                  p_cursor_occurred_at is null or p_cursor_id is null
                  or (g.ended_at, g.id) < (p_cursor_occurred_at, p_cursor_id)
              )

            union all

            select
                s.finished_at as occurred_at,
                s.id as id,
                jsonb_build_object(
                    'type', 'SEARCH',
                    'id', s.id,
                    'user_id', s.user_id,
                    'display_name', coalesce(p.display_name, ''),
                    'avatar_url', p.avatar_url,
                    'game_mode', s.game_mode,
                    'status', s.status,
                    'started_at', to_jsonb(s.started_at),
                    'finished_at', to_jsonb(s.finished_at),
                    'duration_seconds',
                        round(extract(epoch from (s.finished_at - s.started_at)))::int,
                    'fc_account_id', s.fc_account_id,
                    'fc_account_name', a.name
                ) as item
            from public.match_search_sessions as s
            left join public.profiles as p on p.id = s.user_id
            left join public.user_fc_accounts as a on a.id = s.fc_account_id
            where s.team_id = p_team_id
              and s.finished_at is not null
              and v_scope <> 'GAMES'
              and (v_scope = 'SEARCHES' or s.status <> 'MATCH_FOUND')
              and (p_search_status is null or s.status = p_search_status)
              and (p_user_id is null or s.user_id = p_user_id)
              and (p_fc_account_id is null or s.fc_account_id = p_fc_account_id)
              and (p_from is null or s.finished_at >= p_from)
              and (p_to is null or s.finished_at < p_to)
              and (
                  p_cursor_occurred_at is null or p_cursor_id is null
                  or (s.finished_at, s.id) < (p_cursor_occurred_at, p_cursor_id)
              )
        ) as combined
        order by occurred_at desc, id desc
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
                'occurred_at', v_items -> (v_limit - 1) -> (
                    case
                        when (v_items -> (v_limit - 1) ->> 'type') = 'GAME'
                        then 'ended_at' else 'finished_at'
                    end
                ),
                'id', v_items -> (v_limit - 1) -> 'id'
            )
            else null
        end
    );
end;
$$;
