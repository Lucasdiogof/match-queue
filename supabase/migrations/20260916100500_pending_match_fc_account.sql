-- get_pending_game_match ganha o elenco da partida pendente (item 20: o
-- card precisa mostrar "Lucksrei" junto do modo).
create or replace function public.get_pending_game_match()
returns jsonb
language plpgsql
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
            'weekend_league_number', v_event.number,
            'fc_account_id', v_match.fc_account_id,
            'fc_account_name', (
                select name from public.user_fc_accounts where id = v_match.fc_account_id
            )
        )
    );
end;
$$;
