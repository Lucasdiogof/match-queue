-- O contador manual passa a ser a UNICA fonte que a UI mostra (migration
-- anterior). Sem isto, quem ja tinha partidas reais registradas veria o
-- record voltar pra 0-0 do nada -- backfill de uma vez so, nunca mais
-- roda: usa o mesmo agregado que a RPC ja usava pra mostrar o computado.
do $$
declare
    v_event public.weekend_league_events;
    v_rivals_aggregate jsonb;
begin
    v_event := public.get_current_weekend_league_event();

    if v_event.id is not null then
        insert into public.fc_account_weekend_league_progress
            (fc_account_id, weekend_league_event_id, manual_wins, manual_losses)
        select
            a.id,
            v_event.id,
            (agg ->> 'wins')::integer,
            (agg ->> 'losses')::integer
        from public.user_fc_accounts a
        cross join lateral (
            select public._fc_account_match_aggregate(a.id, 'WEEKEND_LEAGUE', v_event.id) as agg
        ) as computed
        where a.is_active
          and ((agg ->> 'wins')::integer > 0 or (agg ->> 'losses')::integer > 0)
        on conflict (fc_account_id, weekend_league_event_id) do nothing;
    end if;

    insert into public.fc_account_rivals_progress (fc_account_id, manual_wins, manual_losses)
    select
        a.id,
        (agg ->> 'wins')::integer,
        (agg ->> 'losses')::integer
    from public.user_fc_accounts a
    cross join lateral (
        select public._fc_account_match_aggregate(a.id, 'DIVISION_RIVALS', null) as agg
    ) as computed
    where a.is_active
      and ((agg ->> 'wins')::integer > 0 or (agg ->> 'losses')::integer > 0)
    on conflict (fc_account_id) do nothing;
end $$;
