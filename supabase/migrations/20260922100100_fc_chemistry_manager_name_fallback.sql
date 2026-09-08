-- Correcao: o bonus do tecnico so comparava IDs, enquanto clube, liga e
-- nacao ja caiam para o NOME quando o id nao existe.
--
-- Efeito pratico do bug: num catalogo importado por nome (CSV, que e
-- exatamente o caminho preparado para o FC27), os links de clube/liga/nacao
-- pontuavam normalmente e o tecnico nunca pontuava -- quimica silenciosamente
-- menor, sem erro nenhum aparecendo. Encontrado ao tentar testar o tecnico
-- com cartas de QA que so tinham nomes.
--
-- Nada mais muda: mesma regra FC_MODERN_V1, mesmos thresholds, mesmo cap.

create or replace function public._fc_squad_chemistry(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    -- Chaves do tecnico no MESMO formato das do jogador: id quando existe,
    -- nome quando nao. Comparar so por id faria o tecnico nunca pontuar num
    -- catalogo importado por nome (CSV), enquanto clube/liga/nacao ja
    -- pontuariam -- inconsistencia silenciosa.
    v_manager_nation_key text;
    v_manager_league_key text;
    v_result jsonb;
begin
    select
        coalesce(m.nation_id::text, nullif(btrim(n.name), '')),
        coalesce(s.manager_league_id::text, nullif(btrim(l.name), ''))
    into v_manager_nation_key, v_manager_league_key
    from public.fc_squads as s
    left join public.fc_managers as m on m.id = s.manager_id
    left join public.fc_nations as n on n.id = m.nation_id
    left join public.fc_leagues as l on l.id = s.manager_league_id
    where s.id = p_squad_id;

    with starters as (
        select
            sl.slot_code,
            coalesce(c.club_id::text, nullif(btrim(c.club_name), '')) as club_key,
            coalesce(c.league_id::text, nullif(btrim(c.league_name), '')) as league_key,
            coalesce(c.nation_id::text, nullif(btrim(c.nation_name), '')) as nation_key,
            (
                (v_manager_nation_key is not null
                 and coalesce(c.nation_id::text, nullif(btrim(c.nation_name), ''))
                     = v_manager_nation_key)
                or (v_manager_league_key is not null
                 and coalesce(c.league_id::text, nullif(btrim(c.league_name), ''))
                     = v_manager_league_key)
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

revoke execute on function public._fc_squad_chemistry(uuid) from public, anon;
