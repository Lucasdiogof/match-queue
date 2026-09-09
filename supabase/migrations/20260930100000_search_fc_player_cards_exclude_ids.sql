-- Gameplay flows refresh: o picker do Squad Builder nunca soube quais
-- cartas ja estao em outros slots do squad -- selecionar uma carta ja
-- usada simplesmente a realocava em silencio (set_fc_squad_slot faz
-- delete+insert). Fix de verdade e no nivel da query: quem chama passa os
-- ids ja ocupados e a busca para de oferece-los como opcao.
--
-- create or replace mantem a assinatura anterior utilizavel (o parametro
-- novo tem default null) -- nenhuma chamada existente quebra.
create or replace function public.search_fc_player_cards(
    p_query text default null,
    p_position text default null,
    p_limit integer default 30,
    p_offset integer default 0,
    p_min_rating integer default null,
    p_max_rating integer default null,
    p_league_name text default null,
    p_club_name text default null,
    p_nation_name text default null,
    p_card_type text default null,
    p_exclude_card_ids uuid[] default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
    v_offset integer := greatest(0, coalesce(p_offset, 0));
    v_query text := nullif(btrim(coalesce(p_query, '')), '');
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return jsonb_build_object(
        'items', (
            select coalesce(jsonb_agg(item order by ord), '[]'::jsonb)
            from (
                select
                    row_number() over (
                        order by c.rating desc, c.player_name
                    ) as ord,
                    public._fc_card_json(c) as item
                from public.fc_player_cards as c
                where c.is_active
                  and (
                        p_position is null
                        or c.primary_position = p_position
                        or p_position = any(c.alternative_positions)
                      )
                  and (
                        v_query is null
                        or c.player_name ilike '%' || v_query || '%'
                        or coalesce(c.common_name, '') ilike '%' || v_query || '%'
                      )
                  and (p_min_rating is null or c.rating >= p_min_rating)
                  and (p_max_rating is null or c.rating <= p_max_rating)
                  and (
                        p_league_name is null
                        or coalesce(
                            (select l.name from public.fc_leagues as l where l.id = c.league_id),
                            c.league_name
                        ) = p_league_name
                      )
                  and (
                        p_club_name is null
                        or coalesce(
                            (select cl.name from public.fc_clubs as cl where cl.id = c.club_id),
                            c.club_name
                        ) = p_club_name
                      )
                  and (
                        p_nation_name is null
                        or coalesce(
                            (select n.name from public.fc_nations as n where n.id = c.nation_id),
                            c.nation_name
                        ) = p_nation_name
                      )
                  and (p_card_type is null or c.card_type = p_card_type)
                  and (
                        p_exclude_card_ids is null
                        or c.id <> all (p_exclude_card_ids)
                      )
                order by c.rating desc, c.player_name
                limit v_limit offset v_offset
            ) as page
        ),
        'has_more', (
            select count(*) > v_offset + v_limit
            from public.fc_player_cards as c
            where c.is_active
              and (
                    p_position is null
                    or c.primary_position = p_position
                    or p_position = any(c.alternative_positions)
                  )
              and (
                    v_query is null
                    or c.player_name ilike '%' || v_query || '%'
                    or coalesce(c.common_name, '') ilike '%' || v_query || '%'
                  )
              and (p_min_rating is null or c.rating >= p_min_rating)
              and (p_max_rating is null or c.rating <= p_max_rating)
              and (
                    p_league_name is null
                    or coalesce(
                        (select l.name from public.fc_leagues as l where l.id = c.league_id),
                        c.league_name
                    ) = p_league_name
                  )
              and (
                    p_club_name is null
                    or coalesce(
                        (select cl.name from public.fc_clubs as cl where cl.id = c.club_id),
                        c.club_name
                    ) = p_club_name
                  )
              and (
                    p_nation_name is null
                    or coalesce(
                        (select n.name from public.fc_nations as n where n.id = c.nation_id),
                        c.nation_name
                    ) = p_nation_name
                  )
              and (p_card_type is null or c.card_type = p_card_type)
              and (
                    p_exclude_card_ids is null
                    or c.id <> all (p_exclude_card_ids)
                  )
        )
    );
end;
$$;

-- Assinatura antiga (10 parametros) some -- create or replace nao troca a
-- assinatura sozinho quando o numero de parametros muda, entao o Postgres
-- trata como funcao nova; a antiga precisa ser derrubada explicitamente
-- pra nao sobrar uma versao "fantasma" sem grant.
drop function if exists public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text
);

revoke execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text, uuid[]
) from public, anon;
grant execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text, uuid[]
) to authenticated;
