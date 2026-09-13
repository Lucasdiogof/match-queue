-- Catalogo de cartas (Explorar cartas) passa a filtrar por GRUPO de posicao
-- (Goleiro/Defensor/Meio-campista/Atacante) em vez de 12 chips de codigo
-- cru (GK, CB, LB, RB...) -- decisao explicita do dono do produto. O grupo
-- e escolhido no cliente (ver cards_catalog_page.dart); aqui so precisa
-- aceitar VARIAS posicoes numa busca so.
--
-- p_position (singular) continua existindo e com o MESMO comportamento --
-- e o que o picker do Squad Builder usa pra elegibilidade de um slot
-- especifico, isso nao muda. p_positions (plural, novo) e so pra esse
-- filtro de grupo: casa se a carta jogar em QUALQUER uma das posicoes da
-- lista (primaria ou alternativa) -- mesma regra de elegibilidade de
-- sempre, so aplicada a mais de uma posicao ao mesmo tempo.
drop function if exists public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean
);

create function public.search_fc_player_cards(
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
    p_exclude_card_ids uuid[] default null,
    p_club_id uuid default null,
    p_gender text default null,
    p_playstyle text default null,
    p_playstyle_plus_only boolean default false,
    p_positions text[] default null
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
    v_total integer;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    with filtered as (
        select c.*
        from public.fc_player_cards as c
        left join public.fc_leagues as l on l.id = c.league_id
        where c.is_active
          and (
                p_position is null
                or c.primary_position = p_position
                or p_position = any(c.alternative_positions)
              )
          and (
                p_positions is null
                or c.primary_position = any(p_positions)
                or c.alternative_positions && p_positions
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
                or coalesce(l.name, c.league_name) = p_league_name
              )
          and (
                p_club_name is null
                or coalesce(
                    (select cl.name from public.fc_clubs as cl where cl.id = c.club_id),
                    c.club_name
                ) = p_club_name
              )
          and (p_club_id is null or c.club_id = p_club_id)
          and (p_gender is null or l.gender = p_gender)
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
          and (
                p_playstyle is null
                or (
                    not p_playstyle_plus_only
                    and p_playstyle = any(c.playstyles)
                )
                or p_playstyle = any(c.playstyles_plus)
              )
    )
    select count(*) into v_total from filtered;

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
                left join public.fc_leagues as l on l.id = c.league_id
                where c.is_active
                  and (
                        p_position is null
                        or c.primary_position = p_position
                        or p_position = any(c.alternative_positions)
                      )
                  and (
                        p_positions is null
                        or c.primary_position = any(p_positions)
                        or c.alternative_positions && p_positions
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
                        or coalesce(l.name, c.league_name) = p_league_name
                      )
                  and (
                        p_club_name is null
                        or coalesce(
                            (select cl.name from public.fc_clubs as cl where cl.id = c.club_id),
                            c.club_name
                        ) = p_club_name
                      )
                  and (p_club_id is null or c.club_id = p_club_id)
                  and (p_gender is null or l.gender = p_gender)
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
                  and (
                        p_playstyle is null
                        or (
                            not p_playstyle_plus_only
                            and p_playstyle = any(c.playstyles)
                        )
                        or p_playstyle = any(c.playstyles_plus)
                      )
                order by c.rating desc, c.player_name
                limit v_limit offset v_offset
            ) as page
        ),
        'has_more', v_total > v_offset + v_limit,
        'total', v_total
    );
end;
$$;

comment on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean, text[]
) is
    'Busca no catalogo. p_playstyle filtra por playstyles OU playstyles_plus; p_playstyle_plus_only restringe so ao Plus. p_positions filtra por qualquer posicao da lista (grupo); p_position continua sendo a posicao unica usada pelo picker do Squad Builder.';

revoke execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean, text[]
) from public, anon;
grant execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean, text[]
) to authenticated;
