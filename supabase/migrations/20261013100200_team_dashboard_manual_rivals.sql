-- get_team_sports_dashboard.rivals ainda so lia game_matches -- desde que
-- Rivals passou a ser contador manual (fc_account_rivals_progress,
-- 20261013100000), toda conta sem partida real registrada aparecia zerada
-- ali mesmo tendo record manual informado. Mesmo padrao ja usado em
-- weekend_league: manual manda quando existe, computado e so fallback.
create or replace function public.get_team_sports_dashboard(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_current_event uuid;
    v_result jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    select id into v_current_event
    from public.weekend_league_events
    where is_active and now() between starts_at and ends_at
    order by starts_at desc
    limit 1;

    with team_accounts as (
        select a.id as fc_account_id, a.name as account_name, a.user_id,
               a.rivals_division
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    team_matches as (
        select m.id, m.user_id, m.fc_account_id, m.game_mode, m.status,
               m.result, m.goals_for, m.goals_against, m.ended_at,
               m.weekend_league_event_id, m.squad_snapshot
        from public.game_matches as m
        where exists (
            select 1 from team_accounts as ta
            where ta.fc_account_id = m.fc_account_id
        )
    ),
    finished as (
        select * from team_matches where status = 'FINISHED' and result is not null
    ),
    player_rows as (
        select
            s.game_match_id,
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            s.player_name, s.goals, s.assists, s.updated_at,
            tm.fc_account_id, tm.user_id
        from public.game_match_player_stats as s
        join team_matches as tm on tm.id = s.game_match_id
    ),
    per_user as (
        select
            ta.user_id,
            count(distinct ta.fc_account_id) as accounts_count,
            count(distinct f.id) as matches,
            count(distinct f.id) filter (where f.result = 'WIN') as wins,
            count(distinct f.id) filter (where f.result = 'LOSS') as losses,
            coalesce(sum(f.goals_for), 0) as goals_for,
            coalesce(sum(f.goals_against), 0) as goals_against
        from team_accounts as ta
        left join finished as f on f.fc_account_id = ta.fc_account_id
        group by ta.user_id
    ),
    per_user_players as (
        select user_id,
               coalesce(sum(goals), 0) as goals,
               coalesce(sum(assists), 0) as assists
        from player_rows group by user_id
    )
    select jsonb_build_object(
        'team_id', p_team_id,
        'server_now', to_jsonb(now()),
        'min_ranked_matches', public._team_ranking_min_matches(),
        'summary', (
            select jsonb_build_object(
                'members_count', (
                    select count(*) from public.team_members where team_id = p_team_id
                ),
                'accounts_count', (select count(*) from team_accounts),
                'matches', (select count(*) from finished),
                'wins', (select count(*) from finished where result = 'WIN'),
                'losses', (select count(*) from finished where result = 'LOSS'),
                'win_rate', (
                    select case when count(*) = 0 then null
                        else round(count(*) filter (where result = 'WIN')::numeric
                                   / count(*), 4) end
                    from finished
                ),
                'goals_for', (select coalesce(sum(goals_for), 0) from finished),
                'goals_against', (select coalesce(sum(goals_against), 0) from finished),
                'goal_difference', (
                    select coalesce(sum(goals_for), 0) - coalesce(sum(goals_against), 0)
                    from finished
                ),
                'registered_player_goals', (select coalesce(sum(goals), 0) from player_rows),
                'registered_assists', (select coalesce(sum(assists), 0) from player_rows)
            )
        ),
        'ranking', (
            select coalesce(jsonb_agg(row_json order by ord), '[]'::jsonb)
            from (
                select
                    row_number() over (
                        order by
                            (pu.matches >= public._team_ranking_min_matches()) desc,
                            case when pu.matches = 0 then null
                                 else pu.wins::numeric / pu.matches end desc nulls last,
                            pu.wins desc,
                            pu.matches desc,
                            coalesce(p.display_name, '') asc
                    ) as ord,
                    jsonb_build_object(
                        'user_id', pu.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'avatar_url', p.avatar_url,
                        'accounts_count', pu.accounts_count,
                        'matches', pu.matches,
                        'wins', pu.wins,
                        'losses', pu.losses,
                        'win_rate', case when pu.matches = 0 then null
                            else round(pu.wins::numeric / pu.matches, 4) end,
                        'goals_for', pu.goals_for,
                        'goals_against', pu.goals_against,
                        'player_goals', coalesce(pup.goals, 0),
                        'player_assists', coalesce(pup.assists, 0),
                        'is_ranked', pu.matches >= public._team_ranking_min_matches()
                    ) as row_json
                from per_user as pu
                left join public.profiles as p on p.id = pu.user_id
                left join per_user_players as pup on pup.user_id = pu.user_id
            ) as ranked
        ),
        'top_scorers', public._team_player_leaderboard(p_team_id, false, 10, 0),
        'top_assists', public._team_player_leaderboard(p_team_id, true, 10, 0),
        'weekend_league', (
            select coalesce(jsonb_agg(row_json order by wins desc, losses asc, account_name asc), '[]'::jsonb)
            from (
                select
                    ta.account_name,
                    coalesce(wl.manual_wins,
                        (select count(*) from finished f
                         where f.fc_account_id = ta.fc_account_id
                           and f.game_mode = 'WEEKEND_LEAGUE'
                           and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                           and f.result = 'WIN')) as wins,
                    coalesce(wl.manual_losses,
                        (select count(*) from finished f
                         where f.fc_account_id = ta.fc_account_id
                           and f.game_mode = 'WEEKEND_LEAGUE'
                           and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                           and f.result = 'LOSS')) as losses,
                    jsonb_build_object(
                        'user_id', ta.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'fc_account_id', ta.fc_account_id,
                        'account_name', ta.account_name,
                        'event_id', v_current_event,
                        'is_manual', wl.manual_wins is not null,
                        'wins', coalesce(wl.manual_wins,
                            (select count(*) from finished f
                             where f.fc_account_id = ta.fc_account_id
                               and f.game_mode = 'WEEKEND_LEAGUE'
                               and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                               and f.result = 'WIN')),
                        'losses', coalesce(wl.manual_losses,
                            (select count(*) from finished f
                             where f.fc_account_id = ta.fc_account_id
                               and f.game_mode = 'WEEKEND_LEAGUE'
                               and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                               and f.result = 'LOSS'))
                    ) as row_json
                from team_accounts as ta
                left join public.profiles as p on p.id = ta.user_id
                left join public.fc_account_weekend_league_progress as wl
                    on wl.fc_account_id = ta.fc_account_id
                   and wl.weekend_league_event_id = v_current_event
            ) as wlrows
        ),
        'rivals', (
            select coalesce(jsonb_agg(row_json order by wins desc, losses asc, account_name asc), '[]'::jsonb)
            from (
                select
                    ta.account_name,
                    coalesce(rp.manual_wins, computed.wins, 0) as wins,
                    coalesce(rp.manual_losses, computed.losses, 0) as losses,
                    jsonb_build_object(
                        'user_id', ta.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'fc_account_id', ta.fc_account_id,
                        'account_name', ta.account_name,
                        'division', ta.rivals_division,
                        'is_manual', rp.manual_wins is not null,
                        'matches', coalesce(computed.matches, 0),
                        'wins', coalesce(rp.manual_wins, computed.wins, 0),
                        'losses', coalesce(rp.manual_losses, computed.losses, 0),
                        'win_rate', case when coalesce(computed.matches, 0) = 0 then null
                            else round(computed.wins::numeric / computed.matches, 4) end
                    ) as row_json
                from team_accounts as ta
                left join public.profiles as p on p.id = ta.user_id
                left join public.fc_account_rivals_progress as rp
                    on rp.fc_account_id = ta.fc_account_id
                left join lateral (
                    select
                        count(*) as matches,
                        count(*) filter (where f.result = 'WIN') as wins,
                        count(*) filter (where f.result = 'LOSS') as losses
                    from finished as f
                    where f.fc_account_id = ta.fc_account_id
                      and f.game_mode = 'DIVISION_RIVALS'
                ) as computed on true
            ) as rrows
        ),
        'activity', (
            select coalesce(jsonb_agg(row_json order by ended_at desc), '[]'::jsonb)
            from (
                select
                    f.ended_at,
                    jsonb_build_object(
                        'type', 'MATCH_RESULT',
                        'occurred_at', to_jsonb(f.ended_at),
                        'user_id', f.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'avatar_url', p.avatar_url,
                        'fc_account_id', f.fc_account_id,
                        'account_name', ta.account_name,
                        'game_mode', f.game_mode,
                        'result', f.result,
                        'goals_for', f.goals_for,
                        'goals_against', f.goals_against,
                        'top_scorer', (
                            select jsonb_build_object(
                                'player_name', pr.player_name, 'goals', pr.goals)
                            from player_rows pr
                            where pr.game_match_id = f.id and pr.goals > 0
                            order by pr.goals desc, pr.player_name asc
                            limit 1
                        )
                    ) as row_json
                from finished as f
                join team_accounts as ta on ta.fc_account_id = f.fc_account_id
                left join public.profiles as p on p.id = f.user_id
                where f.ended_at is not null
                order by f.ended_at desc
                limit 20
            ) as act
        )
    ) into v_result;

    return v_result;
end;
$$;

revoke execute on function public.get_team_sports_dashboard(uuid) from public, anon;
grant execute on function public.get_team_sports_dashboard(uuid) to authenticated;
