-- Regressao: a migration que trocou fc_account_id por user_id em
-- get_fc_squad_builder/list_fc_squads (20261016102000_eliminate_profile_concept.sql)
-- recriou as duas funcoes do zero e, no processo, derrubou o calculo de
-- quimica/overall que ja existia -- a versao nova nem chama mais
-- _fc_squad_chemistry()/_fc_squad_overall(). Efeito visivel: escalacao
-- completa mostrava OVR "--" na tela Jogar, e a quimica voltava pra 0/33
-- assim que o builder recarregava (load()/save() usam get_fc_squad_builder;
-- so o preview ao vivo, que usa outra RPC intocada, continuava certo).
--
-- Esta migration restaura o comportamento de
-- 20261012100400_save_fc_squad_lineup.sql (ultima versao correta, com
-- updated_at + quimica) e de 20260921100000_fc_squad_chemistry_and_reserves.sql
-- (list_fc_squads com overall/chemistry/reserve_count), so trocando
-- fc_account_id por user_id pra bater com o schema atual.

create or replace function public.get_fc_squad_builder(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_squad public.fc_squads;
    v_chem jsonb;
    v_overall jsonb;
    v_result jsonb;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select * into v_squad from public.fc_squads where id = p_squad_id;
    v_chem := public._fc_squad_chemistry(p_squad_id);
    v_overall := public._fc_squad_overall(p_squad_id);

    select jsonb_build_object(
        'id', v_squad.id,
        'user_id', v_squad.user_id,
        'name', v_squad.name,
        'formation_code', v_squad.formation_code,
        'is_default', v_squad.is_default,
        -- Baseline de concorrencia do rascunho: volta em
        -- p_expected_updated_at no save.
        'updated_at', v_squad.updated_at,
        'is_active', v_squad.is_active,
        'bench_size', public._fc_bench_size(),
        'reserve_size', public._fc_reserve_size(),
        'chemistry_rule_version', public._fc_chemistry_rule_version(),
        'chemistry', coalesce(v_chem -> 'total', '0'::jsonb),
        'overall', v_overall -> 'overall',
        'filled_starters', v_overall -> 'filled_starters',
        'starter_count', (
            select count(*) from public.fc_formation_slots
            where formation_code = v_squad.formation_code
        ),
        'formation', (
            select jsonb_build_object(
                'code', f.code,
                'display_name', f.display_name,
                'slots', (
                    select coalesce(jsonb_agg(
                        jsonb_build_object(
                            'slot_code', fs.slot_code,
                            'position_code', fs.position_code,
                            'x', fs.x,
                            'y', fs.y,
                            'sort_order', fs.sort_order
                        ) order by fs.sort_order
                    ), '[]'::jsonb)
                    from public.fc_formation_slots as fs
                    where fs.formation_code = f.code
                )
            )
            from public.fc_formations as f
            where f.code = v_squad.formation_code
        ),
        'slots', (
            select coalesce(jsonb_agg(
                jsonb_build_object(
                    'slot_type', sl.slot_type,
                    'slot_code', sl.slot_code,
                    'card', public._fc_card_json(c),
                    'chemistry', case when sl.slot_type = 'STARTING'
                        then (v_chem -> 'per_slot' -> sl.slot_code)
                        else null end,
                    'chemistry_sources', case when sl.slot_type = 'STARTING'
                        then (v_chem -> 'breakdown_per_slot' -> sl.slot_code)
                        else null end,
                    'position_eligible', case when sl.slot_type = 'STARTING'
                        then not (
                            coalesce(v_chem -> 'out_of_position_slots', '[]'::jsonb)
                            ? sl.slot_code
                        )
                        else true end
                ) order by sl.slot_type, sl.slot_code
            ), '[]'::jsonb)
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = p_squad_id
        ),
        'manager', (
            select jsonb_build_object(
                'id', m.id,
                'name', m.name,
                'image_url', m.image_url,
                'nation', case when n.id is null then null else jsonb_build_object(
                    'id', n.id, 'name', n.name, 'flag_image_url', n.flag_image_url
                ) end
            )
            from public.fc_managers as m
            left join public.fc_nations as n on n.id = m.nation_id
            where m.id = v_squad.manager_id
        ),
        'manager_league', (
            select jsonb_build_object('id', l.id, 'name', l.name,
                                      'logo_image_url', l.logo_image_url)
            from public.fc_leagues as l
            where l.id = v_squad.manager_league_id
        )
    ) into v_result;

    return v_result;
end;
$$;

create or replace function public.list_fc_squads()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return (
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'user_id', s.user_id,
                'name', s.name,
                'formation_code', s.formation_code,
                'is_default', s.is_default,
                'is_active', s.is_active,
                'starting_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'STARTING'
                ),
                'bench_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'BENCH'
                ),
                'reserve_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'RESERVE'
                ),
                'overall', (public._fc_squad_overall(s.id)) -> 'overall',
                'chemistry', coalesce(
                    (public._fc_squad_chemistry(s.id)) -> 'total', '0'::jsonb
                )
            ) order by s.is_default desc, s.created_at
        ), '[]'::jsonb)
        from public.fc_squads as s
        where s.user_id = (select auth.uid()) and s.is_active
    );
end;
$$;
