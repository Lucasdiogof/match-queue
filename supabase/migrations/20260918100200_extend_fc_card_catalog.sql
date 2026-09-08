-- Estende o catalogo de cartas para dados REAIS (Etapa 11, Parte E). O
-- schema da Etapa 10 ja era provider-agnostic de proposito -- aqui so
-- adiciona o que faltava para um provider de verdade: clube como entidade
-- (nao mais texto solto), versao do jogo, rastreio de sincronizacao,
-- is_active para nunca apagar carta ausente, e os campos que a Etapa 10
-- deixou de fora (GK stats corretos, skill moves, pe fraco, playstyles,
-- altura, pe preferido, papeis, raridade).
--
-- Decisao de pesquisa (docs/card_provider_research.md): o provider primario
-- e um dataset comunitario estatico (CSV/JSON versionado), nunca scraping ao
-- vivo de fut.gg/futbin/futwiz -- os tres exigiriam contornar Cloudflare/ToS
-- hoje, o que a regra dura desta etapa proibe.

create table public.fc_clubs (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_club_id text,
    name text not null,
    league_id uuid references public.fc_leagues (id) on delete set null,
    logo_image_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.fc_clubs is
    'Clube como entidade -- antes so existia como fc_player_cards.club_name em texto solto.';

create unique index fc_clubs_provider_idx
    on public.fc_clubs (provider, provider_club_id)
    where provider_club_id is not null;

create index fc_clubs_league_idx on public.fc_clubs (league_id);

create trigger fc_clubs_set_updated_at before update on public.fc_clubs
    for each row execute function public.set_updated_at();

alter table public.fc_clubs enable row level security;

create policy fc_clubs_select_authenticated
    on public.fc_clubs for select to authenticated using (true);

revoke all on table public.fc_clubs from anon;
grant select on table public.fc_clubs to authenticated;

-- Colunas novas em fc_player_cards. Tudo nullable/com default seguro --
-- aditivo, nao quebra as 50 linhas LOCAL existentes.
alter table public.fc_player_cards
    add column game_version text not null default 'FC27',
    add column is_active boolean not null default true,
    add column last_synced_at timestamptz,
    add column source_url text,
    add column club_id uuid references public.fc_clubs (id) on delete set null,
    add column nation_id uuid references public.fc_nations (id) on delete set null,
    add column league_id uuid references public.fc_leagues (id) on delete set null,
    -- GK stats. NUNCA mapeados para pace/shooting/passing/dribbling/
    -- defending/physical -- goleiro tem seu proprio conjunto, sempre.
    add column gk_diving integer,
    add column gk_handling integer,
    add column gk_kicking integer,
    add column gk_reflexes integer,
    add column gk_speed integer,
    add column gk_positioning integer,
    add column skill_moves integer,
    add column weak_foot integer,
    add column playstyles text[] not null default '{}',
    add column height_cm integer,
    add column preferred_foot text,
    add column player_roles text[] not null default '{}',
    add column rarity text;

comment on column public.fc_player_cards.is_active is
    'Ingestao nunca apaga carta ausente de um sync -- marca is_active=false. As 50 cartas provider=LOCAL da Etapa 10 tambem viram false aqui: continuam no banco para dev, fora de qualquer busca em producao.';

-- Corrige um bug conhecido do seed de dev da Etapa 10 (item 11 do pedido:
-- GK nunca pode ter pace/shooting/... preenchido): as 4 cartas GK
-- provider=LOCAL tinham os 6 stats de linha preenchidos por engano. Como
-- essas linhas ja vao virar is_active=false nesta mesma migration, e seguro
-- corrigir aqui em vez de arrastar o bug para a constraint nova abaixo.
update public.fc_player_cards
set pace = null, shooting = null, passing = null,
    dribbling = null, defending = null, physical = null
where primary_position = 'GK'
  and (pace is not null or shooting is not null or passing is not null
       or dribbling is not null or defending is not null or physical is not null);

alter table public.fc_player_cards
    add constraint fc_player_cards_skill_moves_range
        check (skill_moves is null or skill_moves between 1 and 5),
    add constraint fc_player_cards_weak_foot_range
        check (weak_foot is null or weak_foot between 1 and 5),
    add constraint fc_player_cards_preferred_foot_check
        check (preferred_foot is null or preferred_foot in ('LEFT', 'RIGHT')),
    -- GK e outfield stats sao conjuntos mutuamente exclusivos: uma carta
    -- de goleiro preenche gk_*, uma carta de linha preenche pace/shooting/
    -- passing/dribbling/defending/physical -- nunca os dois, nunca nenhum.
    add constraint fc_player_cards_gk_stats_only_for_gk
        check (
            (primary_position <> 'GK') or (
                pace is null and shooting is null and passing is null
                and dribbling is null and defending is null and physical is null
            )
        ),
    add constraint fc_player_cards_outfield_stats_not_for_gk
        check (
            (primary_position = 'GK') or (
                gk_diving is null and gk_handling is null and gk_kicking is null
                and gk_reflexes is null and gk_speed is null
                and gk_positioning is null
            )
        );

-- As 50 cartas de desenvolvimento da Etapa 10 nunca devem aparecer numa
-- busca real. is_active=false em vez de deletar (as linhas continuam uteis
-- para navegar sem dados reais em dev).
update public.fc_player_cards set is_active = false where provider = 'LOCAL';

create index fc_player_cards_search_active_idx
    on public.fc_player_cards (primary_position, rating desc)
    where is_active;

create index fc_player_cards_club_idx on public.fc_player_cards (club_id);
create index fc_player_cards_league_idx on public.fc_player_cards (league_id);
create index fc_player_cards_nation_idx on public.fc_player_cards (nation_id);

-- Serializacao da carta ganha os campos novos. Mesma funcao, ninguem que a
-- chama precisa mudar.
create or replace function public._fc_card_json(p_card public.fc_player_cards)
returns jsonb
language sql
stable
set search_path = ''
as $$
    select jsonb_build_object(
        'id', p_card.id,
        'provider', p_card.provider,
        'game_version', p_card.game_version,
        'player_name', p_card.player_name,
        'common_name', p_card.common_name,
        'rating', p_card.rating,
        'primary_position', p_card.primary_position,
        'alternative_positions', to_jsonb(p_card.alternative_positions),
        'pace', p_card.pace,
        'shooting', p_card.shooting,
        'passing', p_card.passing,
        'dribbling', p_card.dribbling,
        'defending', p_card.defending,
        'physical', p_card.physical,
        'gk_diving', p_card.gk_diving,
        'gk_handling', p_card.gk_handling,
        'gk_kicking', p_card.gk_kicking,
        'gk_reflexes', p_card.gk_reflexes,
        'gk_speed', p_card.gk_speed,
        'gk_positioning', p_card.gk_positioning,
        'skill_moves', p_card.skill_moves,
        'weak_foot', p_card.weak_foot,
        'playstyles', to_jsonb(p_card.playstyles),
        'height_cm', p_card.height_cm,
        'preferred_foot', p_card.preferred_foot,
        'player_roles', to_jsonb(p_card.player_roles),
        'rarity', p_card.rarity,
        'player_image_url', p_card.player_image_url,
        'card_image_url', p_card.card_image_url,
        'club_name', coalesce(
            (select cl.name from public.fc_clubs as cl where cl.id = p_card.club_id),
            p_card.club_name
        ),
        'league_name', coalesce(
            (select l.name from public.fc_leagues as l where l.id = p_card.league_id),
            p_card.league_name
        ),
        'nation_name', coalesce(
            (select n.name from public.fc_nations as n where n.id = p_card.nation_id),
            p_card.nation_name
        ),
        'card_type', p_card.card_type
    );
$$;

-- Busca do catalogo ganha filtros de posicao/rating/liga/clube/nacao/tipo, e
-- SEMPRE exclui is_active=false -- as 50 cartas LOCAL somem da busca por
-- causa disso, sem precisar de um segundo caminho "so producao". Assinatura
-- muda (4 args -> 10), mesmo padrao de drop+create ja usado no projeto
-- quando um parametro novo entra.
drop function if exists public.search_fc_player_cards(text, text, integer, integer);

create function public.search_fc_player_cards(
    p_query text default null,
    p_position text default null,
    p_limit integer default 30,
    p_offset integer default 0,
    p_min_rating integer default null,
    p_max_rating integer default null,
    -- Nome, nao id: PlayerCardQuery (Etapa 10) ja declarava
    -- leagueName/clubName/nationName sem uso ainda -- o contrato existente
    -- e o que manda, entao a RPC casa com ele em vez de pedir id.
    p_league_name text default null,
    p_club_name text default null,
    p_nation_name text default null,
    p_card_type text default null
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
        )
    );
end;
$$;

revoke execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text
) from public, anon;
grant execute on function public.search_fc_player_cards(
    text, text, integer, integer, integer, integer, text, text, text, text
) to authenticated;

-- Lista de clubes para o filtro do picker -- mesmo padrao de
-- get_nations/get_leagues que ja existiam (nome exato conferido no
-- repositorio Flutter antes de acoplar).
create function public.get_fc_clubs(p_league_id uuid default null)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', c.id, 'name', c.name, 'league_id', c.league_id,
            'logo_image_url', c.logo_image_url
        ) order by c.name
    ), '[]'::jsonb)
    from public.fc_clubs as c
    where p_league_id is null or c.league_id = p_league_id;
$$;

revoke execute on function public.get_fc_clubs(uuid) from public, anon;
grant execute on function public.get_fc_clubs(uuid) to authenticated;
