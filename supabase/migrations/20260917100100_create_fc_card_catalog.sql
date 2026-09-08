-- Catalogo de cartas, tecnicos, nacoes e ligas.
--
-- PROVIDER-AGNOSTIC de proposito. Esta NAO e uma tabela "futbin_cards": a PK
-- e sempre nossa (uuid interno) e a origem fica em (provider,
-- provider_card_id). Trocar de fonte, ou combinar duas, vira uma linha nova
-- com outro provider -- nunca uma migracao de chave primaria. A Etapa 11 vai
-- popular isso; aqui so o formato existe.
--
-- Nada aqui e preenchido por esta migration. O app roda com um provider
-- Local/dev honesto ate a integracao real chegar.

create table public.fc_nations (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_nation_id text,
    name text not null,
    flag_image_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index fc_nations_provider_idx
    on public.fc_nations (provider, provider_nation_id)
    where provider_nation_id is not null;

create table public.fc_leagues (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_league_id text,
    name text not null,
    nation_id uuid references public.fc_nations (id) on delete set null,
    logo_image_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index fc_leagues_provider_idx
    on public.fc_leagues (provider, provider_league_id)
    where provider_league_id is not null;

create table public.fc_player_cards (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_card_id text,

    player_name text not null,
    common_name text,

    rating integer not null,
    primary_position text not null references public.fc_positions (code),
    -- Posicoes alternativas da carta. Array e nao tabela: a lista e curta,
    -- imutavel por carta e sempre lida junto -- normalizar so criaria join.
    alternative_positions text[] not null default '{}',

    pace integer,
    shooting integer,
    passing integer,
    dribbling integer,
    defending integer,
    physical integer,

    player_image_url text,
    card_image_url text,

    club_name text,
    league_name text,
    nation_name text,
    card_type text,

    -- O que o provider devolveu e ainda nao modelamos. Guardar cru evita
    -- perder informacao so porque a coluna nao existe hoje.
    raw_metadata jsonb,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint fc_player_cards_rating_range check (rating between 1 and 99)
);

create unique index fc_player_cards_provider_idx
    on public.fc_player_cards (provider, provider_card_id)
    where provider_card_id is not null;

create index fc_player_cards_search_idx
    on public.fc_player_cards (primary_position, rating desc);

create table public.fc_managers (
    id uuid primary key default gen_random_uuid(),
    provider text not null default 'LOCAL',
    provider_manager_id text,
    name text not null,
    nation_id uuid references public.fc_nations (id) on delete set null,
    image_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create unique index fc_managers_provider_idx
    on public.fc_managers (provider, provider_manager_id)
    where provider_manager_id is not null;

create index fc_managers_nation_idx on public.fc_managers (nation_id);

create trigger fc_nations_set_updated_at before update on public.fc_nations
    for each row execute function public.set_updated_at();
create trigger fc_leagues_set_updated_at before update on public.fc_leagues
    for each row execute function public.set_updated_at();
create trigger fc_player_cards_set_updated_at before update on public.fc_player_cards
    for each row execute function public.set_updated_at();
create trigger fc_managers_set_updated_at before update on public.fc_managers
    for each row execute function public.set_updated_at();

alter table public.fc_nations enable row level security;
alter table public.fc_leagues enable row level security;
alter table public.fc_player_cards enable row level security;
alter table public.fc_managers enable row level security;

-- Catalogo compartilhado: leitura para autenticado, escrita so por ingestao
-- server-side (service_role via Edge Function na Etapa 11). Sem policy de
-- insert/update: o app nunca cria carta.
create policy fc_nations_select_authenticated
    on public.fc_nations for select to authenticated using (true);
create policy fc_leagues_select_authenticated
    on public.fc_leagues for select to authenticated using (true);
create policy fc_player_cards_select_authenticated
    on public.fc_player_cards for select to authenticated using (true);
create policy fc_managers_select_authenticated
    on public.fc_managers for select to authenticated using (true);

revoke all on table public.fc_nations from anon;
revoke all on table public.fc_leagues from anon;
revoke all on table public.fc_player_cards from anon;
revoke all on table public.fc_managers from anon;

grant select on table public.fc_nations to authenticated;
grant select on table public.fc_leagues to authenticated;
grant select on table public.fc_player_cards to authenticated;
grant select on table public.fc_managers to authenticated;
