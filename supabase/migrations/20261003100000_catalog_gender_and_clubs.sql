-- Catalogo navegavel: cartas e clubes, com genero explicito.
--
-- Por que genero vira coluna de LIGA e nao de carta:
--
-- O pacote FC27 traz genero por linha ("Men's Football"/"Women's Football"),
-- e o importador descartou esse campo. Medindo a fonte: 42 nomes de clube
-- existem nos DOIS generos (Arsenal, Liverpool, Real Madrid, Barcelona...),
-- mas ZERO ligas misturam genero. A liga e, portanto, o unico eixo em que a
-- separacao e limpa -- e e por ela que o dado ja esta correto no banco:
-- fc_clubs tem uma linha por (clube, liga), entao Arsenal da Premier League
-- e Arsenal da Barclays WSL ja sao dois clubes distintos.
--
-- O risco real nunca foi o dado e sim agregar por NOME. Por isso a busca
-- ganha p_club_id: filtrar clube por nome fundiria os dois Arsenais.
--
-- As 12 ligas femininas abaixo saem do proprio pacote, conferidas contra os
-- nomes exatos ja gravados em fc_leagues. Nenhuma foi inferida por heuristica
-- de nome ("Feminino", "Women") -- isso erraria em Sverige Liga, GPFBL e NWSL.

alter table public.fc_leagues
    add column if not exists gender text;

alter table public.fc_leagues
    drop constraint if exists fc_leagues_gender_check;
alter table public.fc_leagues
    add constraint fc_leagues_gender_check
    check (gender is null or gender in ('MALE', 'FEMALE'));

comment on column public.fc_leagues.gender is
    'Genero da competicao. Fonte: pacote FC27. Clube e carta herdam por aqui.';

update public.fc_leagues
set gender = 'FEMALE'
where name in (
    'Arkema PL',
    'Barclays WSL',
    'Calcio A Femminile',
    'Ceska Liga Žen',
    'GPFBL',
    'Liga F Moeve',
    'Liga Portugal Feminino',
    'NWSL',
    'Nederland Vrouwen Liga',
    'Schweizer Damen Liga',
    'Scottish Women''s League',
    'Sverige Liga'
);

update public.fc_leagues set gender = 'MALE' where gender is null;

create index if not exists fc_leagues_gender_idx on public.fc_leagues (gender);

-- ---------------------------------------------------------------------
-- search_fc_player_cards ganha p_club_id e p_gender.
--
-- DROP explicito antes: acrescentar parametro num "create or replace" cria
-- uma sobrecarga em vez de substituir, e foi exatamente isso que deixou o
-- Historico quebrado por semanas (ver 20261002100000). Como todos os
-- parametros tem default e o cliente chama por nome, as chamadas atuais
-- continuam validas contra a assinatura nova.
-- ---------------------------------------------------------------------
drop function if exists public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text, uuid[]
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
    p_gender text default null
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

    -- O total sai de uma CTE com o mesmo filtro da pagina. Repetido, sim --
    -- mas has_more calculado sobre um filtro diferente do da lista e como as
    -- paginacoes passam a mentir.
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
    uuid[], uuid, text
) is
    'Busca no catalogo. p_club_id evita fundir clubes homonimos de generos diferentes.';

revoke execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text
) from public, anon;
grant execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text,
    uuid[], uuid, text
) to authenticated;

-- ---------------------------------------------------------------------
-- Clubes: sempre por fc_clubs.id, nunca por nome. Ordem inicial e o overall
-- medio real das cartas ativas do clube -- nada de ranking fixo.
-- ---------------------------------------------------------------------
create function public.list_fc_clubs(
    p_query text default null,
    p_gender text default null,
    p_limit integer default 30,
    p_offset integer default 0
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

    select count(*) into v_total
    from public.fc_clubs as cl
    left join public.fc_leagues as l on l.id = cl.league_id
    where (v_query is null or cl.name ilike '%' || v_query || '%')
      and (p_gender is null or l.gender = p_gender)
      and exists (
          select 1 from public.fc_player_cards as c
          where c.club_id = cl.id and c.is_active
      );

    return jsonb_build_object(
        'items', (
            select coalesce(jsonb_agg(item order by ord), '[]'::jsonb)
            from (
                select
                    row_number() over (
                        order by avg(c.rating) desc, cl.name
                    ) as ord,
                    jsonb_build_object(
                        'id', cl.id,
                        'name', cl.name,
                        'league_name', l.name,
                        'gender', l.gender,
                        'cards_count', count(c.id),
                        'average_rating', round(avg(c.rating), 1),
                        'top_rating', max(c.rating),
                        'logo_image_url', cl.logo_image_url
                    ) as item
                from public.fc_clubs as cl
                left join public.fc_leagues as l on l.id = cl.league_id
                join public.fc_player_cards as c
                     on c.club_id = cl.id and c.is_active
                where (v_query is null or cl.name ilike '%' || v_query || '%')
                  and (p_gender is null or l.gender = p_gender)
                group by cl.id, cl.name, l.name, l.gender, cl.logo_image_url
                order by avg(c.rating) desc, cl.name
                limit v_limit offset v_offset
            ) as page
        ),
        'has_more', v_total > v_offset + v_limit,
        'total', v_total
    );
end;
$$;

comment on function public.list_fc_clubs(text, text, integer, integer) is
    'Clubes com >= 1 carta ativa, ordenados pelo overall medio real.';

create function public.get_fc_club_summary(p_club_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select jsonb_build_object(
        'id', cl.id,
        'name', cl.name,
        'league_name', l.name,
        'gender', l.gender,
        'cards_count', count(c.id),
        'average_rating', round(avg(c.rating), 1),
        'top_rating', max(c.rating),
        'logo_image_url', cl.logo_image_url
    )
    into v_result
    from public.fc_clubs as cl
    left join public.fc_leagues as l on l.id = cl.league_id
    left join public.fc_player_cards as c
           on c.club_id = cl.id and c.is_active
    where cl.id = p_club_id
    group by cl.id, cl.name, l.name, l.gender, cl.logo_image_url;

    if v_result is null then
        raise exception 'club not found' using errcode = 'FQ021';
    end if;

    return v_result;
end;
$$;

comment on function public.get_fc_club_summary(uuid) is
    'Resumo de um clube pelo id. Nunca por nome -- homonimos de generos diferentes.';

revoke execute on function public.list_fc_clubs(text, text, integer, integer)
    from public, anon;
grant execute on function public.list_fc_clubs(text, text, integer, integer)
    to authenticated;

revoke execute on function public.get_fc_club_summary(uuid) from public, anon;
grant execute on function public.get_fc_club_summary(uuid) to authenticated;
