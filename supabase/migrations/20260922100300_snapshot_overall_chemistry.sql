-- Snapshot de partida passa a congelar tambem o overall e a quimica.
--
-- ADITIVO E SO PARA FRENTE (itens 53/54): nenhum snapshot ja gravado e
-- tocado. Partida antiga simplesmente nao tem estas chaves, e quem le tem de
-- tratar a ausencia -- e por isso que a UI so mostra o par quando existe.
--
-- Faz sentido congelar porque overall e quimica sao DERIVADOS da composicao
-- do squad: recalcular hoje o overall de uma partida de semana passada daria
-- o numero do squad de hoje, nao o do dia do jogo. O resto do snapshot ja
-- existia justamente por essa razao.
--
-- A versao da regra vai junto: sem ela, uma quimica de 27 gravada sob
-- FC_MODERN_V1 seria indistinguivel de 27 sob uma regra futura diferente.
create or replace function public._fc_squad_snapshot(p_squad_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'squad_id', s.id,
        'name', s.name,
        'formation', s.formation_code,
        'captured_at', to_jsonb(now()),
        'squad_overall', (public._fc_squad_overall(s.id)) -> 'overall',
        'squad_chemistry', (public._fc_squad_chemistry(s.id)) -> 'total',
        'chemistry_rule_version', public._fc_chemistry_rule_version(),
        'manager', (
            select jsonb_build_object('id', m.id, 'name', m.name)
            from public.fc_managers as m where m.id = s.manager_id
        ),
        'manager_league', (
            select jsonb_build_object('id', l.id, 'name', l.name)
            from public.fc_leagues as l where l.id = s.manager_league_id
        ),
        -- Nome/rating/posicao vao junto do id de proposito: a Etapa 11 pode
        -- reimportar o catalogo de cartas e trocar ids, e o historico tem de
        -- continuar legivel mesmo assim.
        'players', (
            select coalesce(jsonb_agg(
                jsonb_build_object(
                    'slot_type', sl.slot_type,
                    'slot', sl.slot_code,
                    'card_id', c.id,
                    'player_name', coalesce(c.common_name, c.player_name),
                    'rating', c.rating,
                    'position', c.primary_position
                ) order by sl.slot_type, sl.slot_code
            ), '[]'::jsonb)
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = s.id
        )
    )
    from public.fc_squads as s
    where s.id = p_squad_id;
$$;

revoke execute on function public._fc_squad_snapshot(uuid) from public, anon;
