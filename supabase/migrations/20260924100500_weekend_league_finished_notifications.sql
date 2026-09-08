-- WEEKEND_LEAGUE_FINISHED (itens 12/62): nunca por partida -- so quando a
-- janela do evento (weekend_league_events.ends_at) fecha de verdade. Reusa
-- o cron de 30s do matchmaking (run_matchmaking_maintenance) em vez de criar
-- um job novo: mais um passo barato no mesmo tick, e pg_cron so aceita
-- intervalo em segundos ate 59 (documentado desde a Etapa 7).

alter table public.weekend_league_events
    add column notifications_dispatched_at timestamptz;

comment on column public.weekend_league_events.notifications_dispatched_at is
    'Quando o record final deste evento foi anunciado aos Times. Null = ainda nao (evento em andamento ou nao processado).';

create function public._dispatch_finished_weekend_league_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_event record;
    v_account record;
    v_team_id uuid;
    v_member record;
    v_wins integer;
    v_losses integer;
    v_count integer := 0;
begin
    for v_event in
        select id, ends_at
        from public.weekend_league_events
        where ends_at < now() and notifications_dispatched_at is null
    loop
        -- So Contas que de fato jogaram este evento (partida ou override
        -- manual) recebem o anuncio -- ninguem "termina" um WL que nao
        -- disputou.
        for v_account in
            select distinct a.id as fc_account_id, a.name as account_name, a.user_id
            from public.user_fc_accounts as a
            where exists (
                select 1 from public.game_matches as m
                where m.fc_account_id = a.id
                  and m.weekend_league_event_id = v_event.id
                  and m.status = 'FINISHED'
            ) or exists (
                select 1 from public.fc_account_weekend_league_progress as wl
                where wl.fc_account_id = a.id
                  and wl.weekend_league_event_id = v_event.id
                  and wl.manual_wins is not null
            )
        loop
            select
                coalesce(wl.manual_wins, count(*) filter (
                    where m.status = 'FINISHED' and m.result = 'WIN')),
                coalesce(wl.manual_losses, count(*) filter (
                    where m.status = 'FINISHED' and m.result = 'LOSS'))
            into v_wins, v_losses
            from public.user_fc_accounts as a
            left join public.game_matches as m
                on m.fc_account_id = a.id
               and m.weekend_league_event_id = v_event.id
               and m.game_mode = 'WEEKEND_LEAGUE'
            left join public.fc_account_weekend_league_progress as wl
                on wl.fc_account_id = a.id
               and wl.weekend_league_event_id = v_event.id
            where a.id = v_account.fc_account_id
            group by wl.manual_wins, wl.manual_losses;

            for v_team_id in
                select team_id from public.fc_account_teams
                where fc_account_id = v_account.fc_account_id
            loop
                for v_member in
                    select tm.user_id
                    from public.team_members as tm
                    where tm.team_id = v_team_id
                      and tm.user_id <> v_account.user_id
                loop
                    perform public._emit_user_notification(
                        v_member.user_id, 'WEEKEND_LEAGUE', 'WEEKEND_LEAGUE_FINISHED',
                        'WEEKEND_LEAGUE_FINISHED:' || v_event.id || ':' || v_account.fc_account_id,
                        'notification_weekend_league_finished',
                        jsonb_build_object(
                            'team_id', v_team_id,
                            'event_id', v_event.id,
                            'fc_account_id', v_account.fc_account_id,
                            'account_name', v_account.account_name,
                            'user_id', v_account.user_id,
                            'display_name', (
                                select display_name from public.profiles
                                where id = v_account.user_id
                            ),
                            'wins', v_wins,
                            'losses', v_losses
                        ),
                        'team_weekend_league', jsonb_build_object('team_id', v_team_id),
                        'weekend_league_event', v_event.id
                    );
                end loop;
            end loop;

            v_count := v_count + 1;
        end loop;

        update public.weekend_league_events
        set notifications_dispatched_at = now()
        where id = v_event.id;
    end loop;

    return v_count;
end;
$$;

revoke execute on function public._dispatch_finished_weekend_league_notifications()
    from public, anon, authenticated;

create or replace function public.run_matchmaking_maintenance()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.process_expired_searches();
    perform public.enqueue_expiring_search_notifications();
    perform public._dispatch_finished_weekend_league_notifications();
end;
$$;

revoke execute on function public.run_matchmaking_maintenance()
    from public, anon, authenticated;
