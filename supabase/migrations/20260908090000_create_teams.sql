-- Um time do FIFA Queue.
--
-- NAO existe teams.owner_id de proposito. Ownership e derivada de
-- team_members.role = 'OWNER', que e a unica fonte de verdade. Guardar o dono
-- nos dois lugares abriria a porta para o estado inconsistente
-- (teams.owner_id = A enquanto o OWNER em team_members e B) e a unica forma
-- realmente robusta de impedir isso e nao ter o segundo lugar.
-- Ver docs/database.md.

create type public.team_role as enum ('OWNER', 'ADMIN', 'PLAYER');

create table public.teams (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    tag text,
    logo_url text,
    primary_color text,
    secondary_color text,
    default_search_duration_seconds integer not null default 180,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint teams_name_not_blank
        check (btrim(name) <> ''),
    constraint teams_name_length
        check (char_length(btrim(name)) between 2 and 40),
    constraint teams_tag_format
        check (tag is null or tag ~ '^[A-Z0-9]{2,6}$'),
    constraint teams_logo_url_scheme
        check (logo_url is null or logo_url ~ '^https://'),
    constraint teams_primary_color_format
        check (primary_color is null or primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    constraint teams_secondary_color_format
        check (secondary_color is null or secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    constraint teams_search_duration_range
        check (default_search_duration_seconds between 30 and 600)
);

comment on table public.teams is
    'Time competitivo. O dono vem de team_members.role = OWNER, nao de uma coluna aqui.';
comment on column public.teams.default_search_duration_seconds is
    'Duracao padrao da busca de partida, em segundos. Configuracao; o timer em si ainda nao existe.';
comment on column public.teams.is_active is
    'Soft disable. Nenhum fluxo desativa time ainda.';

create trigger teams_set_updated_at
    before update on public.teams
    for each row
    execute function public.set_updated_at();

-- id e created_at nao mudam. O update de teams e aberto para OWNER/ADMIN pela
-- RLS, entao vale travar estruturalmente o que nunca deveria ser editavel.
create function public.teams_guard_immutable_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.id is distinct from old.id then
        raise exception 'team id is immutable'
            using errcode = 'FQ004';
    end if;

    new.created_at := old.created_at;
    return new;
end;
$$;

create trigger teams_guard_immutable_columns
    before update on public.teams
    for each row
    execute function public.teams_guard_immutable_columns();
