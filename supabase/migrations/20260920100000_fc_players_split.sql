-- Separa identidade de JOGADOR (atleta base) de CARTA/ITEM (versao
-- especifica). Ate aqui fc_player_cards era card-centric: nao existia
-- nocao de "o mesmo atleta em varias cartas" (Mbappe Gold, Mbappe TOTW,
-- Mbappe TOTS...). Esta migration introduz fc_players como a entidade base,
-- provider-agnostic igual o resto do catalogo, sem tocar em nenhuma linha
-- ja escrita.
--
-- ESCOPO: so modelagem/importer. Nenhum coletor de rede novo -- o importer
-- continua so aceitando arquivo local (CSV/JSON), nunca acessando fut.gg/
-- futbin/futwiz/wefut. Decisao de nao usar WeFUT ja foi tomada e comunicada
-- (robots.txt desautoriza crawlers automatizados) e nao e reaberta aqui.

create table public.fc_players (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_player_id text,
    game_version text not null default 'FC27',
    name text not null,
    common_name text,
    nation_id uuid references public.fc_nations (id) on delete set null,
    club_id uuid references public.fc_clubs (id) on delete set null,
    league_id uuid references public.fc_leagues (id) on delete set null,
    primary_position text,
    alternative_positions text[] not null default '{}',
    image_url text,
    height_cm integer,
    preferred_foot text,
    weak_foot integer,
    skill_moves integer,
    raw_metadata jsonb,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    last_synced_at timestamptz,

    constraint fc_players_weak_foot_range
        check (weak_foot is null or weak_foot between 1 and 5),
    constraint fc_players_skill_moves_range
        check (skill_moves is null or skill_moves between 1 and 5),
    constraint fc_players_preferred_foot_check
        check (preferred_foot is null or preferred_foot in ('LEFT', 'RIGHT'))
);

comment on table public.fc_players is
    'Atleta base (Mbappe), independente de versao de carta. provider_player_id e a identidade externa; a mesma pessoa em fontes diferentes vira linha diferente ate que exista uma resolucao de identidade entre providers -- nao modelada nesta etapa.';

comment on column public.fc_players.provider_player_id is
    'Id do jogador na fonte externa (nao confundir com provider_card_id, que identifica a CARTA/versao especifica em fc_player_cards).';

-- Nula quando o provider nao distingue jogador de carta (ex.: dataset
-- estilo sofifa, uma linha = um jogador = uma carta base) -- mesmo padrao de
-- fc_nations/fc_leagues/fc_clubs/fc_managers, indice parcial.
create unique index fc_players_provider_idx
    on public.fc_players (provider, game_version, provider_player_id)
    where provider_player_id is not null;

create index fc_players_nation_idx on public.fc_players (nation_id);
create index fc_players_club_idx on public.fc_players (club_id);
create index fc_players_league_idx on public.fc_players (league_id);

create trigger fc_players_set_updated_at before update on public.fc_players
    for each row execute function public.set_updated_at();

alter table public.fc_players enable row level security;

-- Mesmo padrao do resto do catalogo: leitura para todo autenticado, escrita
-- so pelo importer server-side (secret key, ignora RLS). Nenhuma policy de
-- insert/update/delete -- o app nunca cria/edita jogador.
create policy fc_players_select_authenticated
    on public.fc_players for select to authenticated using (true);

revoke all on table public.fc_players from anon;
grant select on table public.fc_players to authenticated;

-- fc_player_cards ganha o vinculo com o atleta base. NULLABLE de proposito:
-- as 50 cartas provider=LOCAL (Etapa 10, ja is_active=false desde a Etapa
-- 11) nao ganham fc_players correspondente -- sao dado de dev, popular isso
-- so criaria 50 linhas de fc_players sem nenhum uso real. Squads/slots
-- existentes continuam intocados: fc_squad_slots referencia
-- fc_player_cards.id, que nao muda; game_matches.squad_snapshot e imutavel
-- por design (Etapa 10) e nunca e reescrito por esta ou nenhuma migration.
alter table public.fc_player_cards
    add column fc_player_id uuid references public.fc_players (id) on delete set null;

comment on column public.fc_player_cards.fc_player_id is
    'Atleta base desta carta, quando conhecido. Nulo para as 50 cartas provider=LOCAL da Etapa 10 (dev, ja is_active=false) -- decisao consciente de nao popular fc_players para dado de desenvolvimento.';

create index fc_player_cards_fc_player_idx
    on public.fc_player_cards (fc_player_id)
    where fc_player_id is not null;

-- Serializacao da carta ganha o atleta base como metadata adicional, aditivo
-- -- nenhum campo existente muda de nome/tipo. Mesma assinatura (nenhum
-- drop necessario), so o corpo muda.
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
        'card_type', p_card.card_type,
        'fc_player_id', p_card.fc_player_id,
        'fc_player', (
            select jsonb_build_object(
                'id', pl.id,
                'name', pl.name,
                'common_name', pl.common_name,
                'primary_position', pl.primary_position,
                'image_url', pl.image_url,
                'nation_name', (
                    select n.name from public.fc_nations as n where n.id = pl.nation_id
                ),
                'club_name', (
                    select cl.name from public.fc_clubs as cl where cl.id = pl.club_id
                ),
                'league_name', (
                    select l.name from public.fc_leagues as l where l.id = pl.league_id
                )
            )
            from public.fc_players as pl
            where pl.id = p_card.fc_player_id
        )
    );
$$;
