-- Continuacao do diagnostico: pra cada par de nome duplicado ja achado
-- (clube dentro da mesma liga, tecnico), quantas referencias reais cada id
-- tem -- decide se da pra so apagar o vazio ou se precisa reatribuir FK
-- como fizemos com fc_nations.
create function public._data_checkup_dupe_usage()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_result jsonb := '{}'::jsonb;
    v_part jsonb;
begin
    select coalesce(jsonb_agg(jsonb_build_object(
        'club_id', c.id,
        'name', c.name,
        'league_id', c.league_id,
        'provider_club_id', c.provider_club_id,
        'player_cards_count', (
            select count(*) from public.fc_player_cards where club_id = c.id
        ),
        'players_count', (
            select count(*) from public.fc_players where club_id = c.id
        )
    ) order by c.name, c.id), '[]'::jsonb) into v_part
    from public.fc_clubs as c
    where (lower(c.name), c.league_id) in (
        select lower(name), league_id from public.fc_clubs
        group by lower(name), league_id having count(*) > 1
    );
    v_result := v_result || jsonb_build_object('duplicate_club_usage', v_part);

    select coalesce(jsonb_agg(jsonb_build_object(
        'manager_id', m.id,
        'name', m.name,
        'provider_manager_id', m.provider_manager_id,
        'squads_count', (
            select count(*) from public.fc_squads where manager_id = m.id
        )
    ) order by m.name, m.id), '[]'::jsonb) into v_part
    from public.fc_managers as m
    where lower(m.name) in (
        select lower(name) from public.fc_managers
        group by lower(name) having count(*) > 1
    );
    v_result := v_result || jsonb_build_object('duplicate_manager_usage', v_part);

    return v_result;
end;
$$;

grant execute on function public._data_checkup_dupe_usage() to service_role;
