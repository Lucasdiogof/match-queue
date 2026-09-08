-- Etapa 13: quimica ganha BREAKDOWN por fonte.
--
-- Aditivo puro: a regra FC_MODERN_V1 e os numeros nao mudam nada -- o que
-- muda e que agora da para EXPLICAR o 0-3 de cada titular (item 45), em vez
-- de so mostrar o numero. O total continua saindo do mesmo lugar.
--
-- Por que no backend e nao no Flutter: os thresholds moram na regra
-- versionada. Se o cliente recalculasse o "porque", a explicacao poderia
-- divergir do numero na proxima versao da regra -- exatamente o tipo de bug
-- silencioso que separar as duas implementacoes cria.

create or replace function public._fc_squad_chemistry(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_manager_nation_id uuid;
    v_manager_league_id uuid;
    v_result jsonb;
begin
    select m.nation_id, s.manager_league_id
    into v_manager_nation_id, v_manager_league_id
    from public.fc_squads as s
    left join public.fc_managers as m on m.id = s.manager_id
    where s.id = p_squad_id;

    with starters as (
        select
            sl.slot_code,
            coalesce(c.club_id::text, nullif(btrim(c.club_name), '')) as club_key,
            coalesce(c.league_id::text, nullif(btrim(c.league_name), '')) as league_key,
            coalesce(c.nation_id::text, nullif(btrim(c.nation_name), '')) as nation_key,
            (
                (v_manager_nation_id is not null and c.nation_id = v_manager_nation_id)
                or (v_manager_league_id is not null and c.league_id = v_manager_league_id)
            ) as manager_bonus,
            public._fc_card_can_play(c.id, fs.position_code) as eligible
        from public.fc_squad_slots as sl
        join public.fc_squads as sq on sq.id = sl.squad_id
        join public.fc_formation_slots as fs
            on fs.formation_code = sq.formation_code and fs.slot_code = sl.slot_code
        join public.fc_player_cards as c on c.id = sl.player_card_id
        where sl.squad_id = p_squad_id and sl.slot_type = 'STARTING'
    ),
    -- Pool de contagem: so quem esta NA posicao. Um jogador fora de posicao
    -- nunca soma para o link de outro titular (regra pesquisada).
    pool as (
        select * from starters where eligible
    ),
    counted as (
        select
            st.slot_code,
            st.eligible,
            st.manager_bonus,
            case when st.club_key is null then 0 else
                (select count(*) from pool where pool.club_key = st.club_key) end as club_count,
            case when st.league_key is null then 0 else
                (select count(*) from pool where pool.league_key = st.league_key) end as league_count,
            case when st.nation_key is null then 0 else
                (select count(*) from pool where pool.nation_key = st.nation_key) end as nation_count
        from starters as st
    ),
    scored as (
        select
            ct.slot_code,
            ct.eligible,
            case when not ct.eligible then 0
                when ct.club_count >= 7 then 3
                when ct.club_count >= 4 then 2
                when ct.club_count >= 2 then 1
                else 0 end as club_points,
            case when not ct.eligible then 0
                when ct.league_count >= 8 then 3
                when ct.league_count >= 5 then 2
                when ct.league_count >= 3 then 1
                else 0 end as league_points,
            case when not ct.eligible then 0
                when ct.nation_count >= 8 then 3
                when ct.nation_count >= 5 then 2
                when ct.nation_count >= 2 then 1
                else 0 end as nation_points,
            case when ct.eligible and ct.manager_bonus then 1 else 0 end as manager_points,
            ct.club_count,
            ct.league_count,
            ct.nation_count
        from counted as ct
    ),
    final as (
        select
            sc.*,
            -- Capa em 3 depois de somar: e a soma que estoura, nao cada
            -- componente. Guardar o bruto permite dizer no detalhe que o
            -- jogador ja estava no maximo.
            (sc.club_points + sc.league_points + sc.nation_points
                + sc.manager_points) as raw_points,
            least(3, sc.club_points + sc.league_points + sc.nation_points
                + sc.manager_points) as chemistry
        from scored as sc
    )
    select jsonb_build_object(
        'version', public._fc_chemistry_rule_version(),
        'total', coalesce((select sum(chemistry) from final), 0),
        'per_slot', coalesce(
            (select jsonb_object_agg(slot_code, chemistry) from final), '{}'::jsonb
        ),
        'out_of_position_slots', coalesce(
            (select jsonb_agg(slot_code) from final where not eligible), '[]'::jsonb
        ),
        'breakdown_per_slot', coalesce(
            (select jsonb_object_agg(slot_code, jsonb_build_object(
                'total', chemistry,
                'eligible', eligible,
                'capped', raw_points > chemistry,
                'club', club_points,
                'league', league_points,
                'nation', nation_points,
                'manager', manager_points,
                'club_count', club_count,
                'league_count', league_count,
                'nation_count', nation_count
            )) from final), '{}'::jsonb
        )
    ) into v_result;

    return v_result;
end;
$$;

comment on function public._fc_squad_chemistry(uuid) is
    'Regra FC_MODERN_V1 + breakdown por fonte. Ver docs/handoff_etapa13.md.';

revoke execute on function public._fc_squad_chemistry(uuid) from public, anon;

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
        'fc_account_id', v_squad.fc_account_id,
        'name', v_squad.name,
        'formation_code', v_squad.formation_code,
        'is_default', v_squad.is_default,
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
