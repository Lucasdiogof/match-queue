-- Paginacao estavel do catalogo. A ordenacao era (rating desc, player_name):
-- cartas diferentes do MESMO jogador com o mesmo overall (versao base e
-- edicoes especiais) empatam nas duas chaves, e com limit/offset o Postgres
-- pode devolver os empatados em ordem diferente entre paginas -- uma carta
-- aparece duas vezes e outra some. c.id e o desempate deterministico.
-- Mesma assinatura e mesmos filtros da migration anterior; so muda a ordem.
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
                        order by c.rating desc, c.player_name, c.id
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
                order by c.rating desc, c.player_name, c.id
                limit v_limit offset v_offset
            ) as page
        ),
        'has_more', v_total > v_offset + v_limit,
        'total', v_total
    );
end;
$$;
