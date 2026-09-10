-- Central (nova aba): PlayStyles vira modulo real de Mecanicas, com
-- associacao carta <-> PlayStyle vinda de DADO REAL. Auditoria antes de
-- implementar (pedido explicito do dono do produto): fc_player_cards ja tem
-- playstyles/playstyles_plus preenchidos pelo importer real desde a Etapa
-- 17B-2 (coluna fonte "player_traits" do pacote Wrexist) -- 8.113 das 17.873
-- cartas tem pelo menos 1 playstyle, 181 tem pelo menos 1 playstyle_plus.
-- Nao precisou de nenhum enriquecimento novo, so expor o que ja existia.
--
-- search_fc_player_cards ganha p_playstyle. DROP explicito antes: acrescentar
-- parametro num "create or replace" cria sobrecarga em vez de substituir
-- (mesmo problema documentado em 20261003100000).

drop function if exists public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text
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
    p_playstyle_plus_only boolean default false
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
    uuid[], uuid, text, text, boolean
) is
    'Busca no catalogo. p_playstyle filtra por playstyles OU playstyles_plus; p_playstyle_plus_only restringe so ao Plus.';

revoke execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean
) from public, anon;
grant execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text, text, boolean
) to authenticated;

-- ---------------------------------------------------------------------
-- Resumo de contagem real por PlayStyle -- o catalogo de nomes/categorias/
-- efeitos e conteudo estatico autorado no app (nao muda carta a carta), mas
-- "quantas cartas do NOSSO catalogo tem este PlayStyle" precisa ser real.
-- ---------------------------------------------------------------------
create function public.get_fc_playstyle_summary()
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
        with normal as (
            select unnest(playstyles) as style, count(*) as cnt
            from public.fc_player_cards
            where is_active
            group by style
        ), plus as (
            select unnest(playstyles_plus) as style, count(*) as cnt
            from public.fc_player_cards
            where is_active
            group by style
        )
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'style', coalesce(n.style, p.style),
                'card_count', coalesce(n.cnt, 0),
                'plus_card_count', coalesce(p.cnt, 0)
            )
            order by coalesce(n.cnt, 0) + coalesce(p.cnt, 0) desc
        ), '[]'::jsonb)
        from normal as n
        full outer join plus as p on n.style = p.style
    );
end;
$$;

comment on function public.get_fc_playstyle_summary() is
    'Contagem real de cartas ativas por PlayStyle (normal e Plus), pro modulo PlayStyles da Central.';

revoke execute on function public.get_fc_playstyle_summary() from public, anon;
grant execute on function public.get_fc_playstyle_summary() to authenticated;
