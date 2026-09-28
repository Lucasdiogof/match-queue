-- Schema inicial do projeto Supabase do eFootball (efootball-queue).
--
-- Este arquivo NAO e um replay das migrations do EA FC (fifa-queue). E uma
-- reconstrucao do ESTADO FINAL do que e core/generico, auditado direto do
-- conteudo real de supabase/migrations/ do fifa-queue (nao so pelos nomes
-- dos arquivos). Nada de fc_squads, fc_player_cards, fc_managers, chemistry,
-- playstyles, weekend_league_events, market -- isso continua exclusivo do
-- EA FC.
--
-- Diferencas deliberadas em relacao ao fifa-queue:
--   - game_mode e text LIVRE, sem CHECK contra WEEKEND_LEAGUE/DIVISION_RIVALS
--     (o eFootball ainda nao tem modos competitivos definidos).
--   - users.platforms / users.rivals_division nao existem (eram FC-specific).
--   - notification_type e app_notification_category nascem so com os
--     valores genericos (sem WEEKEND_LEAGUE_FINISHED/RIVALS_DIVISION_CHANGED
--     nem categorias WEEKEND_LEAGUE/RIVALS).
--   - user_public_profiles nao tem show_squad/show_weekend_league/show_rivals
--     (schema minimo; campos especificos do eFootball entram depois).
--   - game_matches e uma versao minima (sem weekend_league_event_id,
--     rivals_division, squad_snapshot, result, goals_for/against).
--
-- Ver docs/game_flavors.md (fifa-queue) para o contexto completo da
-- fundacao multi-game e a auditoria que gerou este arquivo.

-- =======================================================================
-- 1. users -- identidade complementar a auth.users
-- =======================================================================
create table public.users (
    id uuid primary key references auth.users (id) on delete cascade,
    display_name text not null,
    avatar_url text,
    locale text,
    last_active_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint users_display_name_not_blank
        check (btrim(display_name) <> ''),
    constraint users_display_name_length
        check (char_length(btrim(display_name)) between 2 and 32),
    constraint users_avatar_url_scheme
        check (avatar_url is null or avatar_url ~ '^https://'),
    constraint users_locale_format
        check (locale is null or locale ~ '^[a-z]{2}(-[A-Za-z0-9]{2,8})?$')
);

comment on table public.users is
    'Identidade complementar do jogador. 1:1 com auth.users. Sem e-mail.';

create index users_last_active_at_idx
    on public.users (last_active_at)
    where last_active_at is not null;

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create trigger users_set_updated_at
    before update on public.users
    for each row
    execute function public.set_updated_at();

alter table public.users enable row level security;

revoke all on table public.users from anon;
grant select, insert, update on table public.users to authenticated;

-- =======================================================================
-- 2. teams + team_members + roles + helpers
-- =======================================================================
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
    is_public boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint teams_name_not_blank check (btrim(name) <> ''),
    constraint teams_name_length check (char_length(btrim(name)) between 2 and 40),
    constraint teams_tag_format check (tag is null or tag ~ '^[A-Z0-9]{2,6}$'),
    constraint teams_logo_url_scheme check (logo_url is null or logo_url ~ '^https://'),
    constraint teams_primary_color_format check (primary_color is null or primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    constraint teams_secondary_color_format check (secondary_color is null or secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    constraint teams_search_duration_range check (default_search_duration_seconds between 30 and 600)
);

comment on table public.teams is
    'Time competitivo. O dono vem de team_members.role = OWNER, nao de uma coluna aqui.';

create index teams_public_created_idx
    on public.teams (created_at desc)
    where is_public;

create trigger teams_set_updated_at
    before update on public.teams
    for each row
    execute function public.set_updated_at();

create function public.teams_guard_immutable_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.id is distinct from old.id then
        raise exception 'team id is immutable' using errcode = 'FQ004';
    end if;
    new.created_at := old.created_at;
    return new;
end;
$$;

create trigger teams_guard_immutable_columns
    before update on public.teams
    for each row
    execute function public.teams_guard_immutable_columns();

create table public.team_members (
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.users (id) on delete restrict,
    role public.team_role not null default 'PLAYER',
    joined_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    primary key (team_id, user_id)
);

comment on table public.team_members is
    'Membros de um time. Linha presente = membro ativo.';

create index team_members_user_id_idx on public.team_members (user_id);

create unique index team_members_single_owner_idx
    on public.team_members (team_id)
    where role = 'OWNER';

create trigger team_members_set_updated_at
    before update on public.team_members
    for each row
    execute function public.set_updated_at();

-- Trigger de protecao do OWNER com porta controlada por GUC de transacao
-- (app.allow_owner_transfer), usada so por _transfer_team_ownership abaixo.
create function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    v_transfer_allowed boolean :=
        coalesce(current_setting('app.allow_owner_transfer', true), '') = 'on';
begin
    if tg_op = 'DELETE' then
        if old.role = 'OWNER'
            and not v_transfer_allowed
            and exists (select 1 from public.teams where id = old.team_id)
        then
            raise exception 'team owner cannot be removed' using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.user_id is distinct from old.user_id
    then
        raise exception 'team membership identity is immutable' using errcode = 'FQ004';
    end if;

    if old.role = 'OWNER' and new.role <> 'OWNER' and not v_transfer_allowed then
        raise exception 'team ownership transfer is not supported yet' using errcode = 'FQ005';
    end if;

    new.joined_at := old.joined_at;
    return new;
end;
$$;

create trigger team_members_protect_owner
    before update or delete on public.team_members
    for each row
    execute function public.team_members_protect_owner();

create function public._transfer_team_ownership(
    p_team_id uuid,
    p_from_user_id uuid,
    p_to_user_id uuid
)
returns void
language plpgsql
set search_path = ''
as $$
begin
    perform set_config('app.allow_owner_transfer', 'on', true);

    update public.team_members set role = 'PLAYER'
    where team_id = p_team_id and user_id = p_from_user_id;

    update public.team_members set role = 'OWNER'
    where team_id = p_team_id and user_id = p_to_user_id;

    perform set_config('app.allow_owner_transfer', 'off', true);
end;
$$;

comment on function public._transfer_team_ownership(uuid, uuid, uuid) is
    'Uso interno. Rebaixa o OWNER atual e promove o novo, nessa ordem (indice unico de OWNER nao e deferrable). Nao valida permissao.';

revoke execute on function public._transfer_team_ownership(uuid, uuid, uuid)
    from public, anon, authenticated;

-- Helpers de membership (security definer para nao recursar RLS).
create function public.is_team_member(p_team_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = (select auth.uid())
    );
$$;

create function public.is_team_admin(p_team_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = (select auth.uid())
          and role in ('OWNER', 'ADMIN')
    );
$$;

create function public.is_team_owner(p_team_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = (select auth.uid())
          and role = 'OWNER'
    );
$$;

create function public.shares_team_with(p_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select exists (
        select 1 from public.team_members as mine
        join public.team_members as theirs on theirs.team_id = mine.team_id
        where mine.user_id = (select auth.uid()) and theirs.user_id = p_user_id
    );
$$;

revoke execute on function public.is_team_member(uuid) from public, anon;
revoke execute on function public.is_team_admin(uuid) from public, anon;
revoke execute on function public.is_team_owner(uuid) from public, anon;
revoke execute on function public.shares_team_with(uuid) from public, anon;
grant execute on function public.is_team_member(uuid) to authenticated;
grant execute on function public.is_team_admin(uuid) to authenticated;
grant execute on function public.is_team_owner(uuid) to authenticated;
grant execute on function public.shares_team_with(uuid) to authenticated;

-- RLS: users, teams, team_members
create policy users_select_visible
    on public.users for select to authenticated
    using ((select auth.uid()) = id or public.shares_team_with(id));

create policy users_insert_own
    on public.users for insert to authenticated
    with check ((select auth.uid()) = id);

create policy users_update_own
    on public.users for update to authenticated
    using ((select auth.uid()) = id)
    with check ((select auth.uid()) = id);

alter table public.teams enable row level security;
alter table public.team_members enable row level security;

create policy teams_select_member
    on public.teams for select to authenticated
    using (public.is_team_member(id));

create policy teams_update_admin
    on public.teams for update to authenticated
    using (public.is_team_admin(id))
    with check (public.is_team_admin(id));

create policy team_members_select_member
    on public.team_members for select to authenticated
    using (public.is_team_member(team_id));

revoke all on table public.teams from anon;
revoke all on table public.team_members from anon;
grant select, update on table public.teams to authenticated;
grant select on table public.team_members to authenticated;

grant select on table public.team_members to service_role;
grant select on table public.teams to service_role;

-- RPCs de time
create function public.create_team(
    p_name text,
    p_tag text default null,
    p_default_search_duration_seconds integer default 180
)
returns public.teams
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_name text;
    v_tag text;
    v_duration integer;
    v_team public.teams;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (select 1 from public.users where id = v_user_id) then
        raise exception 'user profile is missing for the current user' using errcode = 'FQ006';
    end if;

    v_name := btrim(coalesce(p_name, ''));
    if char_length(v_name) < 2 or char_length(v_name) > 40 then
        raise exception 'team name must have between 2 and 40 characters' using errcode = 'FQ001';
    end if;

    v_tag := nullif(upper(btrim(coalesce(p_tag, ''))), '');
    if v_tag is not null and v_tag !~ '^[A-Z0-9]{2,6}$' then
        raise exception 'team tag must have 2 to 6 letters or digits' using errcode = 'FQ002';
    end if;

    v_duration := coalesce(p_default_search_duration_seconds, 180);
    if v_duration < 30 or v_duration > 600 then
        raise exception 'search duration must be between 30 and 600 seconds' using errcode = 'FQ007';
    end if;

    insert into public.teams (name, tag, default_search_duration_seconds)
    values (v_name, v_tag, v_duration)
    returning * into v_team;

    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_user_id, 'OWNER');

    return v_team;
end;
$$;

revoke execute on function public.create_team(text, text, integer) from public, anon;
grant execute on function public.create_team(text, text, integer) to authenticated;

create function public.remove_team_member(p_team_id uuid, p_target_user_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_actor_role public.team_role;
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select role into v_actor_role from public.team_members
    where team_id = p_team_id and user_id = v_actor_id;

    if v_actor_role is null or v_actor_role = 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team owner cannot be removed' using errcode = 'FQ005';
    end if;

    if v_actor_role = 'ADMIN' and v_target_role <> 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    delete from public.team_members where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

create function public.set_team_member_role(
    p_team_id uuid, p_target_user_id uuid, p_role public.team_role
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet' using errcode = 'FQ005';
    end if;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet' using errcode = 'FQ005';
    end if;

    update public.team_members set role = p_role
    where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

create function public.transfer_team_ownership(p_team_id uuid, p_target_user_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform 1 from public.team_members where team_id = p_team_id for update;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if p_target_user_id = v_user_id then
        raise exception 'target is already the owner' using errcode = 'FQ012';
    end if;

    select role into v_target_role from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    perform public._transfer_team_ownership(p_team_id, v_user_id, p_target_user_id);
end;
$$;

comment on function public.transfer_team_ownership(uuid, uuid) is
    'OWNER passa a posse do time pra outro membro. O OWNER antigo vira PLAYER e continua no time. Atomica.';

revoke execute on function public.remove_team_member(uuid, uuid) from public, anon;
revoke execute on function public.set_team_member_role(uuid, uuid, public.team_role) from public, anon;
revoke execute on function public.transfer_team_ownership(uuid, uuid) from public, anon;
grant execute on function public.remove_team_member(uuid, uuid) to authenticated;
grant execute on function public.set_team_member_role(uuid, uuid, public.team_role) to authenticated;
grant execute on function public.transfer_team_ownership(uuid, uuid) to authenticated;

-- Visibilidade publica de time
create function public.set_team_visibility(p_team_id uuid, p_is_public boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;
    update public.teams set is_public = p_is_public where id = p_team_id;
end;
$$;

create function public.list_public_teams(p_limit integer default 20)
returns setof public.teams
language sql stable security definer set search_path = ''
as $$
    select * from public.teams
    where is_public
    order by created_at desc
    limit greatest(1, least(coalesce(p_limit, 20), 50));
$$;

create function public.get_public_team(p_team_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_team public.teams;
    v_members jsonb;
begin
    select * into v_team from public.teams where id = p_team_id and is_public;
    if v_team.id is null then
        return jsonb_build_object('found', false);
    end if;

    select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', m.user_id,
        'display_name', u.display_name,
        'avatar_url', u.avatar_url,
        'role', m.role
    ) order by case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end, u.display_name),
    '[]'::jsonb)
    into v_members
    from public.team_members as m
    join public.users as u on u.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'found', true,
        'team', jsonb_build_object(
            'id', v_team.id, 'name', v_team.name, 'tag', v_team.tag,
            'logo_url', v_team.logo_url, 'primary_color', v_team.primary_color,
            'secondary_color', v_team.secondary_color
        ),
        'members', v_members
    );
end;
$$;

revoke execute on function public.set_team_visibility(uuid, boolean) from public, anon;
revoke execute on function public.list_public_teams(integer) from public;
revoke execute on function public.get_public_team(uuid) from public;
grant execute on function public.set_team_visibility(uuid, boolean) to authenticated;
grant execute on function public.list_public_teams(integer) to anon, authenticated;
grant execute on function public.get_public_team(uuid) to anon, authenticated;

-- get_team_player_statuses depende de game_matches/match_search_sessions/
-- match_search_queue -- criada mais abaixo, na secao 4. Ver secao 4b.

-- =======================================================================
-- 3. team_invite_links + RPCs
-- =======================================================================
create table public.team_invite_links (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    code text not null,
    created_by uuid references public.users (id) on delete set null,
    is_active boolean not null default true,
    expires_at timestamptz,
    max_uses integer,
    usage_count integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    revoked_at timestamptz,

    constraint team_invite_links_code_unique unique (code),
    constraint team_invite_links_code_format check (code ~ '^[A-Z0-9]{10,16}$'),
    constraint team_invite_links_max_uses_positive check (max_uses is null or max_uses > 0),
    constraint team_invite_links_usage_count_non_negative check (usage_count >= 0)
);

create index team_invite_links_team_id_idx on public.team_invite_links (team_id);
create unique index team_invite_links_one_active_per_team
    on public.team_invite_links (team_id) where is_active;

alter table public.team_invite_links enable row level security;
revoke all on table public.team_invite_links from anon, authenticated, public;

create function public._generate_invite_code()
returns text
language plpgsql security definer set search_path = ''
as $$
declare
    v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    v_length constant integer := 12;
    v_bytes bytea;
    v_code text := '';
    i integer;
begin
    v_bytes := extensions.gen_random_bytes(v_length);
    for i in 0..v_length - 1 loop
        v_code := v_code || substr(
            v_alphabet, (get_byte(v_bytes, i) % length(v_alphabet)) + 1, 1
        );
    end loop;
    return v_code;
end;
$$;

revoke execute on function public._generate_invite_code() from public, anon, authenticated;

create function public._ensure_active_team_invite(p_team_id uuid, p_actor_id uuid)
returns public.team_invite_links
language plpgsql security definer set search_path = ''
as $$
declare
    v_link public.team_invite_links;
    v_attempt integer := 0;
begin
    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    select * into v_link from public.team_invite_links
    where team_id = p_team_id and is_active limit 1;

    if v_link.id is not null then
        return v_link;
    end if;

    loop
        v_attempt := v_attempt + 1;
        begin
            insert into public.team_invite_links (team_id, code, created_by)
            values (p_team_id, public._generate_invite_code(), p_actor_id)
            returning * into v_link;
            return v_link;
        exception when unique_violation then
            if v_attempt >= 5 then
                raise exception 'could not generate a unique invite code' using errcode = 'FQ013';
            end if;
        end;
    end loop;
end;
$$;

revoke execute on function public._ensure_active_team_invite(uuid, uuid) from public, anon, authenticated;

create function public.resolve_team_invite(p_code text)
returns table (
    status text, team_id uuid, team_name text, team_tag text,
    team_logo_url text, member_count integer, is_already_member boolean
)
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_code text := upper(btrim(coalesce(p_code, '')));
    v_link public.team_invite_links;
    v_status text;
    v_is_member boolean;
begin
    select * into v_link from public.team_invite_links where code = v_code;

    if v_link.id is null then
        return query select 'invalid'::text, null::uuid, null::text, null::text,
            null::text, null::integer, null::boolean;
        return;
    end if;

    if not v_link.is_active then
        v_status := 'revoked';
    elsif v_link.expires_at is not null and v_link.expires_at < now() then
        v_status := 'expired';
    elsif v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        v_status := 'exhausted';
    else
        v_status := 'valid';
    end if;

    if v_user_id is not null then
        v_is_member := exists (
            select 1 from public.team_members as tm
            where tm.team_id = v_link.team_id and tm.user_id = v_user_id
        );
        if v_status = 'valid' and v_is_member then
            v_status := 'already_member';
        end if;
    else
        v_is_member := null;
    end if;

    return query
    select v_status, t.id, t.name, t.tag, t.logo_url,
        (select count(*)::integer from public.team_members as tm where tm.team_id = t.id),
        v_is_member
    from public.teams t where t.id = v_link.team_id;
end;
$$;

revoke execute on function public.resolve_team_invite(text) from public;
grant execute on function public.resolve_team_invite(text) to anon, authenticated;

create function public.join_team_by_invite(p_code text)
returns table (already_member boolean, team_id uuid, team_name text, team_tag text, role text)
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_code text := upper(btrim(coalesce(p_code, '')));
    v_link public.team_invite_links;
    v_existing public.team_members;
    v_team public.teams;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_link from public.team_invite_links where code = v_code for update;

    if v_link.id is null then
        raise exception 'invite not found' using errcode = 'FQ008';
    end if;
    if not v_link.is_active then
        raise exception 'invite is not active' using errcode = 'FQ009';
    end if;
    if v_link.expires_at is not null and v_link.expires_at < now() then
        raise exception 'invite has expired' using errcode = 'FQ010';
    end if;
    if v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        raise exception 'invite has been exhausted' using errcode = 'FQ011';
    end if;

    select * into v_existing from public.team_members as tm
    where tm.team_id = v_link.team_id and tm.user_id = v_user_id;

    if v_existing.team_id is not null then
        select * into v_team from public.teams where id = v_link.team_id;
        return query select true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end if;

    begin
        insert into public.team_members (team_id, user_id, role)
        values (v_link.team_id, v_user_id, 'PLAYER');
    exception when unique_violation then
        select * into v_existing from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.user_id = v_user_id;
        select * into v_team from public.teams where id = v_link.team_id;
        return query select true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end;

    update public.team_invite_links set usage_count = usage_count + 1 where id = v_link.id;
    select * into v_team from public.teams where id = v_link.team_id;

    return query select false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$$;

revoke execute on function public.join_team_by_invite(text) from public, anon;
grant execute on function public.join_team_by_invite(text) to authenticated;

create function public.get_or_create_team_invite(p_team_id uuid)
returns public.team_invite_links
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;
    return public._ensure_active_team_invite(p_team_id, v_user_id);
end;
$$;

create function public.rotate_team_invite(p_team_id uuid)
returns public.team_invite_links
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_new public.team_invite_links;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    update public.team_invite_links set is_active = false, revoked_at = now()
    where team_id = p_team_id and is_active;

    insert into public.team_invite_links (team_id, code, created_by)
    values (p_team_id, public._generate_invite_code(), v_user_id)
    returning * into v_new;

    return v_new;
end;
$$;

create function public.revoke_team_invite(p_team_id uuid)
returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_count integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    update public.team_invite_links set is_active = false, revoked_at = now()
    where team_id = p_team_id and is_active;

    get diagnostics v_count = row_count;
    return v_count > 0;
end;
$$;

revoke execute on function public.get_or_create_team_invite(uuid) from public, anon;
revoke execute on function public.rotate_team_invite(uuid) from public, anon;
revoke execute on function public.revoke_team_invite(uuid) from public, anon;
grant execute on function public.get_or_create_team_invite(uuid) to authenticated;
grant execute on function public.rotate_team_invite(uuid) to authenticated;
grant execute on function public.revoke_team_invite(uuid) to authenticated;

-- =======================================================================
-- 4. Matchmaking: game_matches, match_search_sessions, match_search_queue
-- =======================================================================

-- Versao MINIMA de game_matches: so o suficiente para o cooldown de 30s e
-- o status IN_MATCH funcionarem. Sem weekend_league_event_id, rivals_division,
-- squad_snapshot, result, goals_for/against (tudo isso e EA FC-specific ou
-- ja tinha sido descontinuado no fifa-queue).
create table public.game_matches (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.users (id) on delete set null,
    team_id uuid not null references public.teams (id) on delete cascade,
    search_session_id uuid,
    game_mode text,
    status text not null default 'IN_MATCH',
    started_at timestamptz not null default now(),
    ended_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint game_matches_status_check
        check (status in ('IN_MATCH', 'FINISHED', 'ABANDONED', 'EXPIRED')),
    constraint game_matches_ended_consistency
        check ((status = 'IN_MATCH') = (ended_at is null))
);

comment on table public.game_matches is
    'Partida real (jogo), separada da busca. Versao minima -- so cooldown/status. Escrita so por RPC.';

create unique index game_matches_one_in_match_per_user
    on public.game_matches (user_id) where status = 'IN_MATCH' and user_id is not null;
create index game_matches_user_status_idx on public.game_matches (user_id, status);
create index game_matches_team_started_idx on public.game_matches (team_id, started_at desc);

create trigger game_matches_set_updated_at
    before update on public.game_matches
    for each row execute function public.set_updated_at();

alter table public.game_matches enable row level security;
revoke all on table public.game_matches from anon, authenticated, public;

create table public.match_search_sessions (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid references public.users (id) on delete set null,

    status text not null,
    started_at timestamptz not null default now(),
    expires_at timestamptz not null,
    finished_at timestamptz,
    finish_reason text,
    -- Texto livre de proposito: o eFootball ainda nao tem modos definidos.
    -- Quando definirmos (pesquisa do produto), valida no app/RPC, nao aqui.
    game_mode text,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint match_search_sessions_status_check
        check (status in ('SEARCHING', 'MATCH_FOUND', 'CANCELLED', 'EXPIRED')),
    constraint match_search_sessions_finish_reason_check
        check (finish_reason is null or finish_reason in ('MATCH_FOUND', 'CANCELLED', 'EXPIRED')),
    constraint match_search_sessions_finished_consistency
        check ((status = 'SEARCHING') = (finished_at is null)),
    constraint match_search_sessions_finish_reason_consistency
        check ((status = 'SEARCHING') = (finish_reason is null)),
    constraint match_search_sessions_expires_after_started
        check (expires_at > started_at)
);

comment on table public.match_search_sessions is
    'Uma linha por tentativa real de busca. Nunca deletada -- historico.';

create index match_search_sessions_expiring_idx
    on public.match_search_sessions (expires_at) where status = 'SEARCHING';
create index match_search_sessions_history_idx
    on public.match_search_sessions (team_id, finished_at desc, id desc)
    where finished_at is not null;

create trigger match_search_sessions_set_updated_at
    before update on public.match_search_sessions
    for each row execute function public.set_updated_at();

create table public.match_search_queue (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid references public.users (id) on delete set null,
    sequence bigint generated always as identity,
    joined_at timestamptz not null default now(),
    game_mode text
);

comment on table public.match_search_queue is
    'Quem esta esperando a vez agora. Linha removida ao sair ou ser promovido.';

create unique index match_search_queue_unique_team_user_mode
    on public.match_search_queue (team_id, user_id, game_mode);
create index match_search_queue_team_sequence_idx
    on public.match_search_queue (team_id, sequence);

create function public._guard_no_double_matchmaking_participation()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
    if new.user_id is null then
        return new;
    end if;

    if tg_table_name = 'match_search_sessions' then
        if exists (
            select 1 from public.match_search_queue
            where team_id = new.team_id and user_id = new.user_id and game_mode = new.game_mode
        ) then
            raise exception 'user already queued for this team' using errcode = 'FQ017';
        end if;
    elsif tg_table_name = 'match_search_queue' then
        if exists (
            select 1 from public.match_search_sessions
            where team_id = new.team_id and user_id = new.user_id
              and game_mode = new.game_mode and status = 'SEARCHING'
        ) then
            raise exception 'user already searching for this team' using errcode = 'FQ017';
        end if;
    end if;
    return new;
end;
$$;

create trigger match_search_sessions_guard_participation
    before insert or update on public.match_search_sessions
    for each row when (new.status = 'SEARCHING')
    execute function public._guard_no_double_matchmaking_participation();

create trigger match_search_queue_guard_participation
    before insert on public.match_search_queue
    for each row
    execute function public._guard_no_double_matchmaking_participation();

alter table public.match_search_sessions enable row level security;
alter table public.match_search_queue enable row level security;
revoke all on table public.match_search_sessions from anon, authenticated, public;
revoke all on table public.match_search_queue from anon, authenticated, public;

-- Locks
create function public._lock_team_matchmaking(p_team_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    perform pg_advisory_xact_lock(hashtext('match_search:' || p_team_id::text));
end;
$$;

create function public._lock_user_matchmaking(p_user_id uuid)
returns void
language sql security definer set search_path = ''
as $$
    select pg_advisory_xact_lock(hashtextextended('user_matchmaking:' || p_user_id::text, 0));
$$;

create function public._lock_teams_matchmaking(p_team_ids uuid[])
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_team_id uuid;
begin
    foreach v_team_id in array p_team_ids loop
        perform public._lock_team_matchmaking(v_team_id);
    end loop;
end;
$$;

revoke execute on function public._lock_team_matchmaking(uuid) from public, anon, authenticated;
revoke execute on function public._lock_user_matchmaking(uuid) from public, anon, authenticated;
revoke execute on function public._lock_teams_matchmaking(uuid[]) from public, anon, authenticated;

create function public._user_globally_searching(p_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select exists (
        select 1 from public.match_search_sessions
        where user_id = p_user_id and status = 'SEARCHING'
    );
$$;

revoke execute on function public._user_globally_searching(uuid) from public, anon, authenticated;

create function public._team_free_for_search(p_team_id uuid, p_game_mode text)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select not exists (
        select 1 from public.match_search_sessions
        where team_id = p_team_id and game_mode is not distinct from p_game_mode
          and status = 'SEARCHING'
    );
$$;

revoke execute on function public._team_free_for_search(uuid, text) from public, anon, authenticated;

create function public._expire_team_search_if_needed(p_team_id uuid)
returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
    v_session public.match_search_sessions;
    v_expired_any boolean := false;
begin
    for v_session in
        select * from public.match_search_sessions
        where team_id = p_team_id and status = 'SEARCHING' and expires_at <= now()
    loop
        update public.match_search_sessions
        set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
        where id = v_session.id;

        perform public._enqueue_notification(
            v_session.user_id, 'SEARCH_EXPIRED', p_team_id, v_session.id, '{}'::jsonb
        );

        perform public._promote_next_queued_player_for_team(p_team_id, v_session.game_mode);
        perform public._notify_matchmaking_changed(p_team_id);

        if v_session.user_id is not null then
            perform public._retry_promotion_for_user_queues(v_session.user_id, p_team_id);
        end if;

        v_expired_any := true;
    end loop;

    return v_expired_any;
end;
$$;

revoke execute on function public._expire_team_search_if_needed(uuid) from public, anon, authenticated;

create function public._promote_next_queued_player_for_team(p_team_id uuid, p_game_mode text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_attempts_left integer;
    v_candidate public.match_search_queue;
    v_new_session public.match_search_sessions;
begin
    select count(*) into v_attempts_left
    from public.match_search_queue
    where team_id = p_team_id and game_mode is not distinct from p_game_mode;

    while v_attempts_left > 0 loop
        v_attempts_left := v_attempts_left - 1;

        select * into v_candidate from public.match_search_queue
        where team_id = p_team_id and game_mode is not distinct from p_game_mode
        order by sequence limit 1;

        exit when v_candidate.id is null;

        perform public._lock_user_matchmaking(v_candidate.user_id);

        if public._user_globally_searching(v_candidate.user_id) then
            delete from public.match_search_queue where id = v_candidate.id;
            insert into public.match_search_queue (team_id, user_id, game_mode)
            values (v_candidate.team_id, v_candidate.user_id, v_candidate.game_mode);
            continue;
        end if;

        delete from public.match_search_queue where id = v_candidate.id;

        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode)
        select p_team_id, v_candidate.user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            v_candidate.game_mode
        from public.teams as t where t.id = p_team_id
        returning * into v_new_session;

        perform public._enqueue_notification(
            v_new_session.user_id, 'YOUR_TURN', p_team_id, v_new_session.id,
            jsonb_build_object('expires_at', to_jsonb(v_new_session.expires_at))
        );
        return;
    end loop;
end;
$$;

revoke execute on function public._promote_next_queued_player_for_team(uuid, text)
    from public, anon, authenticated;

create function public._retry_promotion_for_user_queues(p_user_id uuid, p_exclude_team_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_pair record;
    v_team_ids uuid[];
begin
    if p_user_id is null then
        return;
    end if;

    select coalesce(array_agg(distinct team_id order by team_id), array[]::uuid[])
        into v_team_ids
    from public.match_search_queue
    where user_id = p_user_id and team_id <> p_exclude_team_id;

    if array_length(v_team_ids, 1) is null then
        return;
    end if;

    perform public._lock_teams_matchmaking(v_team_ids);

    for v_pair in
        select distinct team_id, game_mode from public.match_search_queue
        where user_id = p_user_id and team_id <> p_exclude_team_id
    loop
        if public._team_free_for_search(v_pair.team_id, v_pair.game_mode) then
            perform public._promote_next_queued_player_for_team(v_pair.team_id, v_pair.game_mode);
            perform public._notify_matchmaking_changed(v_pair.team_id);
        end if;
    end loop;
end;
$$;

revoke execute on function public._retry_promotion_for_user_queues(uuid, uuid)
    from public, anon, authenticated;

-- Ordem canonica de lock para cancel/report: times ordenados -> usuario,
-- igual a request_match_search (time -> usuario). Travar o usuario primeiro
-- e depois o time cruza com request e gera deadlock (40P01) sob
-- concorrencia -- regressao real no EA FC, corrigida la em
-- 20261021100000_matchmaking_lock_ordering_refix. O peek sem lock so decide
-- QUAIS times travar; a sessao devolvida e relida depois dos locks.
create function public._matchmaking_user_team_ids(p_user_id uuid, p_extra_team_id uuid)
returns uuid[]
language sql stable security definer set search_path = ''
as $$
    select coalesce(array_agg(distinct tid order by tid), array[]::uuid[])
    from (
        select p_extra_team_id as tid where p_extra_team_id is not null
        union
        select team_id from public.match_search_queue where user_id = p_user_id
    ) as teams(tid);
$$;

revoke execute on function public._matchmaking_user_team_ids(uuid, uuid)
    from public, anon, authenticated;

create function public._lock_user_search_for_update(p_user_id uuid)
returns public.match_search_sessions
language plpgsql security definer set search_path = ''
as $$
declare
    v_peek_team_id uuid;
    v_locked uuid[];
    v_fresh uuid[];
    v_missing uuid[];
    v_searching public.match_search_sessions;
begin
    select team_id into v_peek_team_id from public.match_search_sessions
    where user_id = p_user_id and status = 'SEARCHING'
    limit 1;

    v_locked := public._matchmaking_user_team_ids(p_user_id, v_peek_team_id);
    perform public._lock_teams_matchmaking(v_locked);
    perform public._lock_user_matchmaking(p_user_id);

    select * into v_searching from public.match_search_sessions
    where user_id = p_user_id and status = 'SEARCHING';

    -- Conjunto mudou entre o peek e o lock (raro): trava o que faltou.
    v_fresh := public._matchmaking_user_team_ids(p_user_id, v_searching.team_id);
    select coalesce(array_agg(t order by t), array[]::uuid[]) into v_missing
    from unnest(v_fresh) as t where not (t = any (v_locked));
    if array_length(v_missing, 1) is not null then
        perform public._lock_teams_matchmaking(v_missing);
    end if;

    return v_searching;
end;
$$;

revoke execute on function public._lock_user_search_for_update(uuid)
    from public, anon, authenticated;

-- RPCs publicas de matchmaking (sem p_fc_squad_id / fc_squad_id / checagem
-- de platforms -- tudo isso era EA FC-specific).
create function public.request_match_search(p_team_id uuid, p_game_mode text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_is_active boolean;
    v_already_session public.match_search_sessions;
    v_already_queue public.match_search_queue;
    v_queue_count integer;
    v_new_session public.match_search_sessions;
    v_new_queue public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._lock_user_matchmaking(v_user_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_already_session from public.match_search_sessions
    where team_id = p_team_id and user_id = v_user_id
      and game_mode is not distinct from p_game_mode and status = 'SEARCHING';
    if v_already_session.id is not null then
        return public.get_my_matchmaking_status(p_team_id, p_game_mode);
    end if;

    select * into v_already_queue from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id and game_mode is not distinct from p_game_mode;
    if v_already_queue.id is not null then
        return public.get_my_matchmaking_status(p_team_id, p_game_mode);
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id and game_mode is not distinct from p_game_mode
          and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    select count(*) into v_queue_count from public.match_search_queue
    where team_id = p_team_id and game_mode is not distinct from p_game_mode;

    if v_queue_count = 0
        and public._team_free_for_search(p_team_id, p_game_mode)
        and not public._user_globally_searching(v_user_id)
    then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode)
        select p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds), p_game_mode
        from public.teams as t where t.id = p_team_id
        returning * into v_new_session;
    else
        insert into public.match_search_queue (team_id, user_id, game_mode)
        values (p_team_id, v_user_id, p_game_mode)
        returning * into v_new_queue;
    end if;

    perform public._notify_matchmaking_changed(p_team_id);
    return public.get_my_matchmaking_status(p_team_id, p_game_mode);
end;
$$;

create function public.cancel_match_search()
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_team_id uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_searching := public._lock_user_search_for_update(v_user_id);

    if v_searching.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;

    update public.match_search_sessions
    set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player_for_team(v_team_id, v_searching.game_mode);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_searching.game_mode);
end;
$$;

create function public.leave_match_search_queue(p_team_id uuid, p_game_mode text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_entry public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._lock_team_matchmaking(p_team_id);

    select * into v_entry from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id and game_mode is not distinct from p_game_mode;

    if v_entry.id is null then
        raise exception 'not in this team queue' using errcode = 'FQ047';
    end if;

    delete from public.match_search_queue where id = v_entry.id;
    perform public._notify_matchmaking_changed(p_team_id);

    return public.get_my_matchmaking_status(p_team_id, p_game_mode);
end;
$$;

create function public.report_match_found_and_start_game()
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_team_id uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_searching := public._lock_user_search_for_update(v_user_id);

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;

    update public.match_search_sessions
    set status = 'MATCH_FOUND', finish_reason = 'MATCH_FOUND', finished_at = now()
    where id = v_searching.id;

    update public.game_matches
    set status = 'ABANDONED', ended_at = now()
    where user_id = v_user_id and status = 'IN_MATCH';

    insert into public.game_matches
        (user_id, team_id, search_session_id, game_mode, status, started_at)
    values
        (v_user_id, v_team_id, v_searching.id, v_searching.game_mode, 'IN_MATCH', now());

    perform public._promote_next_queued_player_for_team(v_team_id, v_searching.game_mode);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_searching.game_mode);
end;
$$;

create function public.get_my_matchmaking_status(p_team_id uuid, p_game_mode text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_duration integer;
    v_my_session public.match_search_sessions;
    v_my_queue public.match_search_queue;
    v_other_session public.match_search_sessions;
    v_elsewhere_session public.match_search_sessions;
    v_my_state text;
    v_my_position integer;
    v_queue jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select default_search_duration_seconds into v_duration from public.teams where id = p_team_id;

    select * into v_my_session from public.match_search_sessions
    where team_id = p_team_id and user_id = v_user_id
      and game_mode is not distinct from p_game_mode and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue from public.match_search_queue
        where team_id = p_team_id and user_id = v_user_id and game_mode is not distinct from p_game_mode;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(*) + 1 into v_my_position from public.match_search_queue
            where team_id = p_team_id and game_mode is not distinct from p_game_mode
              and sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;

        select * into v_other_session from public.match_search_sessions
        where team_id = p_team_id and game_mode is not distinct from p_game_mode and status = 'SEARCHING';

        select * into v_elsewhere_session from public.match_search_sessions
        where user_id = v_user_id and status = 'SEARCHING'
          and (team_id <> p_team_id or game_mode is distinct from p_game_mode);
    end if;

    select coalesce(jsonb_agg(jsonb_build_object(
        'position', ranked.position, 'user_id', ranked.user_id,
        'display_name', ranked.display_name, 'avatar_url', ranked.avatar_url,
        'game_mode', ranked.game_mode, 'joined_at', ranked.joined_at,
        'is_me', ranked.user_id = v_user_id
    ) order by ranked.position), '[]'::jsonb)
    into v_queue
    from (
        select q.user_id, q.game_mode, q.joined_at, u.display_name, u.avatar_url,
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.users as u on u.id = q.user_id
        where q.team_id = p_team_id and q.game_mode is not distinct from p_game_mode
    ) as ranked;

    return jsonb_build_object(
        'server_now', to_jsonb(now()), 'user_id', v_user_id, 'team_id', p_team_id,
        'game_mode', p_game_mode, 'search_duration_seconds', v_duration,
        'my_state', v_my_state, 'my_position', v_my_position,
        'searching', case when v_my_session.id is null then null else jsonb_build_object(
            'session_id', v_my_session.id, 'started_at', to_jsonb(v_my_session.started_at),
            'expires_at', to_jsonb(v_my_session.expires_at), 'game_mode', v_my_session.game_mode
        ) end,
        'blocking_search', case when v_other_session.id is null then null else jsonb_build_object(
            'user_id', v_other_session.user_id,
            'display_name', (select display_name from public.users where id = v_other_session.user_id),
            'avatar_url', (select avatar_url from public.users where id = v_other_session.user_id),
            'expires_at', to_jsonb(v_other_session.expires_at), 'game_mode', v_other_session.game_mode
        ) end,
        'elsewhere_search', case when v_elsewhere_session.id is null then null else jsonb_build_object(
            'team_id', v_elsewhere_session.team_id, 'game_mode', v_elsewhere_session.game_mode,
            'expires_at', to_jsonb(v_elsewhere_session.expires_at)
        ) end,
        'queue', v_queue
    );
end;
$$;

revoke execute on function public.request_match_search(uuid, text) from public, anon;
revoke execute on function public.cancel_match_search() from public, anon;
revoke execute on function public.leave_match_search_queue(uuid, text) from public, anon;
revoke execute on function public.report_match_found_and_start_game() from public, anon;
revoke execute on function public.get_my_matchmaking_status(uuid, text) from public, anon;
grant execute on function public.request_match_search(uuid, text) to authenticated;
grant execute on function public.cancel_match_search() to authenticated;
grant execute on function public.leave_match_search_queue(uuid, text) to authenticated;
grant execute on function public.report_match_found_and_start_game() to authenticated;
grant execute on function public.get_my_matchmaking_status(uuid, text) to authenticated;

-- Sinal de invalidacao para o Realtime.
create table public.team_matchmaking_revisions (
    team_id uuid primary key references public.teams (id) on delete cascade,
    revision bigint not null default 1,
    updated_at timestamptz not null default now()
);

alter table public.team_matchmaking_revisions enable row level security;

create policy team_matchmaking_revisions_select_member
    on public.team_matchmaking_revisions for select to authenticated
    using (public.is_team_member(team_id));

revoke all on table public.team_matchmaking_revisions from anon;
grant select on table public.team_matchmaking_revisions to authenticated;

alter publication supabase_realtime add table public.team_matchmaking_revisions;

create function public._notify_matchmaking_changed(p_team_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    insert into public.team_matchmaking_revisions as r (team_id, revision, updated_at)
    values (p_team_id, 1, now())
    on conflict (team_id) do update set revision = r.revision + 1, updated_at = now();
end;
$$;

revoke execute on function public._notify_matchmaking_changed(uuid) from public, anon, authenticated;

-- 4b. get_team_player_statuses (depende de game_matches/queue/sessions, por
-- isso so entra aqui, nao na secao 2).
create function public.get_team_player_statuses(p_team_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_members jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', m.user_id,
            'display_name', coalesce(u.display_name, ''),
            'avatar_url', u.avatar_url,
            'role', m.role,
            'last_active_at', to_jsonb(u.last_active_at),
            'status', case
                when exists (
                    select 1 from public.game_matches g
                    where g.user_id = m.user_id and g.status = 'IN_MATCH'
                ) then 'IN_MATCH'
                when exists (
                    select 1 from public.match_search_sessions s
                    where s.team_id = p_team_id and s.user_id = m.user_id and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    where q.team_id = p_team_id and q.user_id = m.user_id
                ) then 'QUEUED'
                when u.last_active_at is not null
                    and u.last_active_at >= now() - interval '60 minutes'
                    then 'RECENTLY_ACTIVE'
                else 'OFFLINE'
            end,
            'queue_position', (
                select row_number() over (order by q.sequence)
                from public.match_search_queue as q
                where q.team_id = p_team_id and q.user_id = m.user_id
            )
        )
        order by case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end,
            coalesce(u.display_name, '')
    ), '[]'::jsonb)
    into v_members
    from public.team_members as m
    join public.users as u on u.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object('server_now', to_jsonb(now()), 'team_id', p_team_id, 'members', v_members);
end;
$$;

revoke execute on function public.get_team_player_statuses(uuid) from public, anon;
grant execute on function public.get_team_player_statuses(uuid) to authenticated;

-- Historico/estatisticas
create function public.get_team_activity_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_finished_at timestamptz default null,
    p_cursor_id uuid default null
)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (order by s.finished_at desc, s.id desc) as ord,
            jsonb_build_object(
                'type', 'SEARCH', 'id', s.id, 'user_id', s.user_id,
                'display_name', u.display_name, 'avatar_url', u.avatar_url,
                'game_mode', s.game_mode, 'status', s.status,
                'started_at', to_jsonb(s.started_at), 'finished_at', to_jsonb(s.finished_at),
                'duration_seconds', extract(epoch from (s.finished_at - s.started_at))::integer
            ) as item,
            s.finished_at, s.id
        from public.match_search_sessions as s
        left join public.users as u on u.id = s.user_id
        where s.team_id = p_team_id and s.finished_at is not null
          and (
              p_cursor_finished_at is null or p_cursor_id is null
              or (s.finished_at, s.id) < (p_cursor_finished_at, p_cursor_id)
          )
        order by s.finished_at desc, s.id desc
        limit v_limit + 1
    ) as page;

    v_items := case when v_count > v_limit then
        (select jsonb_agg(value) from jsonb_array_elements(v_rows) with ordinality as t(value, i)
         where i <= v_limit)
        else v_rows end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()), 'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case when v_count > v_limit then jsonb_build_object(
            'finished_at', v_items -> (v_limit - 1) -> 'finished_at',
            'id', v_items -> (v_limit - 1) -> 'id'
        ) else null end
    );
end;
$$;

create function public.get_team_matchmaking_stats(
    p_team_id uuid, p_from timestamptz default null, p_to timestamptz default null
)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_from timestamptz := coalesce(p_from, now() - interval '30 days');
    v_to timestamptz := coalesce(p_to, now());
    v_result jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select jsonb_build_object(
        'total_searches', count(*),
        'matches_found', count(*) filter (where status = 'MATCH_FOUND'),
        'cancelled', count(*) filter (where status = 'CANCELLED'),
        'expired', count(*) filter (where status = 'EXPIRED'),
        'success_rate', case when count(*) > 0
            then round(count(*) filter (where status = 'MATCH_FOUND')::numeric / count(*), 2)
            else 0 end,
        'avg_duration_seconds', coalesce(avg(extract(epoch from (finished_at - started_at)))
            filter (where finished_at is not null), 0)
    )
    into v_result
    from public.match_search_sessions
    where team_id = p_team_id and started_at between v_from and v_to;

    return v_result;
end;
$$;

create function public.update_team_search_duration(p_team_id uuid, p_seconds integer)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;
    if p_seconds < 30 or p_seconds > 600 then
        raise exception 'search duration must be between 30 and 600 seconds' using errcode = 'FQ007';
    end if;

    update public.teams set default_search_duration_seconds = p_seconds where id = p_team_id;
end;
$$;

revoke execute on function public.get_team_activity_history(uuid, integer, timestamptz, uuid) from public, anon;
revoke execute on function public.get_team_matchmaking_stats(uuid, timestamptz, timestamptz) from public, anon;
revoke execute on function public.update_team_search_duration(uuid, integer) from public, anon;
grant execute on function public.get_team_activity_history(uuid, integer, timestamptz, uuid) to authenticated;
grant execute on function public.get_team_matchmaking_stats(uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.update_team_search_duration(uuid, integer) to authenticated;

-- =======================================================================
-- 5. Notificacoes: user_devices, notification_preferences, outbox, worker,
--    user_notifications
-- =======================================================================
create type public.device_platform as enum ('ANDROID', 'IOS', 'WEB');

create table public.user_devices (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    fcm_token text not null,
    platform public.device_platform not null,
    is_active boolean not null default true,
    last_seen_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint user_devices_token_not_blank check (btrim(fcm_token) <> '')
);

create unique index user_devices_fcm_token_key on public.user_devices (fcm_token);
create index user_devices_active_by_user_idx on public.user_devices (user_id) where is_active;

create trigger user_devices_set_updated_at
    before update on public.user_devices
    for each row execute function public.set_updated_at();

alter table public.user_devices enable row level security;

create policy user_devices_select_own
    on public.user_devices for select to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_devices from anon;
grant select on table public.user_devices to authenticated;

create function public.register_device(p_fcm_token text, p_platform public.device_platform)
returns public.user_devices
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_token text := btrim(coalesce(p_fcm_token, ''));
    v_device public.user_devices;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if v_token = '' then
        raise exception 'fcm token is required' using errcode = 'FQ019';
    end if;

    insert into public.user_devices as d (user_id, fcm_token, platform)
    values (v_user_id, v_token, p_platform)
    on conflict (fcm_token) do update
        set user_id = v_user_id, platform = p_platform, is_active = true, last_seen_at = now()
    returning * into v_device;

    return v_device;
end;
$$;

create function public.deactivate_device(p_fcm_token text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    update public.user_devices set is_active = false
    where fcm_token = btrim(coalesce(p_fcm_token, '')) and user_id = v_user_id;
end;
$$;

revoke execute on function public.register_device(text, public.device_platform) from public, anon;
revoke execute on function public.deactivate_device(text) from public, anon;
grant execute on function public.register_device(text, public.device_platform) to authenticated;
grant execute on function public.deactivate_device(text) to authenticated;

-- Preferencias: sem weekend_league_enabled/rivals_enabled (FC-specific).
create table public.notification_preferences (
    user_id uuid primary key references public.users (id) on delete cascade,
    queue_turn_enabled boolean not null default true,
    search_expiring_enabled boolean not null default true,
    search_expired_enabled boolean not null default true,
    matchmaking_enabled boolean not null default true,
    teams_enabled boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create trigger notification_preferences_set_updated_at
    before update on public.notification_preferences
    for each row execute function public.set_updated_at();

alter table public.notification_preferences enable row level security;

create policy notification_preferences_select_own
    on public.notification_preferences for select to authenticated
    using ((select auth.uid()) = user_id);
create policy notification_preferences_insert_own
    on public.notification_preferences for insert to authenticated
    with check ((select auth.uid()) = user_id);
create policy notification_preferences_update_own
    on public.notification_preferences for update to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

revoke all on table public.notification_preferences from anon;
grant select, insert, update on table public.notification_preferences to authenticated;

-- Enum so com valores genericos -- nada de WEEKEND_LEAGUE_FINISHED/
-- RIVALS_DIVISION_CHANGED.
create type public.notification_type as enum (
    'YOUR_TURN', 'SEARCH_EXPIRING', 'SEARCH_EXPIRED',
    'TEAM_MEMBER_JOINED', 'TEAM_LEADER_CHANGED',
    'TEAM_JOIN_REQUEST_RECEIVED', 'TEAM_JOIN_REQUEST_APPROVED', 'TEAM_JOIN_REQUEST_REJECTED',
    'TEAM_INVITATION_RECEIVED', 'TEAM_INVITATION_ACCEPTED'
);

create table public.notification_outbox (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    type public.notification_type not null,
    team_id uuid references public.teams (id) on delete cascade,
    session_id uuid,
    payload jsonb not null default '{}'::jsonb,
    dedupe_key text not null,
    created_at timestamptz not null default now(),
    available_at timestamptz not null default now(),
    processed_at timestamptz,
    attempt_count integer not null default 0,
    last_error text
);

-- Unique por (user_id, dedupe_key), nao dedupe_key sozinho -- mesmo evento
-- pode precisar notificar mais de um usuario (fan-out).
create unique index notification_outbox_user_dedupe_key_idx
    on public.notification_outbox (user_id, dedupe_key);
create index notification_outbox_pending_idx
    on public.notification_outbox (available_at) where processed_at is null;

alter table public.notification_outbox enable row level security;
revoke all on table public.notification_outbox from anon, authenticated;

create function public._enqueue_notification(
    p_user_id uuid, p_type public.notification_type, p_team_id uuid,
    p_session_id uuid, p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.notification_outbox (user_id, type, team_id, session_id, payload, dedupe_key)
    values (
        p_user_id, p_type, p_team_id, p_session_id, coalesce(p_payload, '{}'::jsonb),
        p_type::text || ':' || coalesce(p_session_id::text, gen_random_uuid()::text)
    )
    on conflict (user_id, dedupe_key) do nothing;
end;
$$;

revoke execute on function public._enqueue_notification(
    uuid, public.notification_type, uuid, uuid, jsonb
) from public, anon, authenticated;

-- user_notifications: categoria so com valores genericos.
create type public.app_notification_category as enum ('MATCHMAKING', 'TEAMS');

create table public.user_notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users (id) on delete cascade,
    category public.app_notification_category not null,
    type text not null,
    title_key text not null,
    params jsonb not null default '{}'::jsonb,
    deep_link_type text,
    deep_link_params jsonb not null default '{}'::jsonb,
    source_entity_type text,
    source_entity_id uuid,
    dedupe_key text not null,
    created_at timestamptz not null default now(),
    read_at timestamptz
);

create unique index user_notifications_user_dedupe_key_idx
    on public.user_notifications (user_id, dedupe_key);
create index user_notifications_user_created_idx
    on public.user_notifications (user_id, created_at desc, id desc);
create index user_notifications_unread_idx
    on public.user_notifications (user_id) where read_at is null;

alter table public.user_notifications enable row level security;

create policy user_notifications_select_own
    on public.user_notifications for select to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_notifications from anon, authenticated;
grant select on table public.user_notifications to authenticated;

create function public._emit_user_notification(
    p_user_id uuid,
    p_category public.app_notification_category,
    p_type text,
    p_dedupe_key text,
    p_title_key text,
    p_params jsonb default '{}'::jsonb,
    p_deep_link_type text default null,
    p_deep_link_params jsonb default '{}'::jsonb,
    p_source_entity_type text default null,
    p_source_entity_id uuid default null
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.user_notifications (
        user_id, category, type, title_key, params, deep_link_type, deep_link_params,
        source_entity_type, source_entity_id, dedupe_key
    )
    values (
        p_user_id, p_category, p_type, p_title_key, coalesce(p_params, '{}'::jsonb),
        p_deep_link_type, coalesce(p_deep_link_params, '{}'::jsonb),
        p_source_entity_type, p_source_entity_id, p_dedupe_key
    )
    on conflict (user_id, dedupe_key) do nothing;
end;
$$;

revoke execute on function public._emit_user_notification(
    uuid, public.app_notification_category, text, text, text, jsonb, text, jsonb, text, uuid
) from public, anon, authenticated;

create function public.list_my_notifications(
    p_limit integer default 20, p_cursor_created_at timestamptz default null, p_cursor_id uuid default null
)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 30));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (order by n.created_at desc, n.id desc) as ord,
            jsonb_build_object(
                'id', n.id, 'category', n.category, 'type', n.type, 'title_key', n.title_key,
                'params', n.params, 'deep_link_type', n.deep_link_type,
                'deep_link_params', n.deep_link_params,
                'created_at', to_jsonb(n.created_at), 'read_at', to_jsonb(n.read_at)
            ) as item,
            n.created_at, n.id
        from public.user_notifications as n
        where n.user_id = v_user_id
          and (p_cursor_created_at is null or p_cursor_id is null
               or (n.created_at, n.id) < (p_cursor_created_at, p_cursor_id))
        order by n.created_at desc, n.id desc
        limit v_limit + 1
    ) as page;

    v_items := case when v_count > v_limit then
        (select jsonb_agg(value) from jsonb_array_elements(v_rows) with ordinality as t(value, i)
         where i <= v_limit)
        else v_rows end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()), 'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case when v_count > v_limit then jsonb_build_object(
            'created_at', v_items -> (v_limit - 1) -> 'created_at',
            'id', v_items -> (v_limit - 1) -> 'id'
        ) else null end
    );
end;
$$;

create function public.get_my_unread_notification_count()
returns integer
language sql stable security definer set search_path = ''
as $$
    select count(*)::integer from public.user_notifications
    where user_id = (select auth.uid()) and read_at is null;
$$;

create function public.mark_notification_read(p_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    update public.user_notifications set read_at = now()
    where id = p_id and user_id = (select auth.uid()) and read_at is null;
end;
$$;

create function public.mark_all_notifications_read()
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    update public.user_notifications set read_at = now()
    where user_id = (select auth.uid()) and read_at is null;
end;
$$;

revoke execute on function public.list_my_notifications(integer, timestamptz, uuid) from public, anon;
revoke execute on function public.get_my_unread_notification_count() from public, anon;
revoke execute on function public.mark_notification_read(uuid) from public, anon;
revoke execute on function public.mark_all_notifications_read() from public, anon;
grant execute on function public.list_my_notifications(integer, timestamptz, uuid) to authenticated;
grant execute on function public.get_my_unread_notification_count() to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;

-- Worker do outbox (pg_net + Vault + cron). Precisa de pg_net/pg_cron
-- habilitadas no projeto (Database > Extensions) e dos secrets
-- notification_worker_url/notification_worker_secret no Vault antes de
-- funcionar de ponta a ponta -- sem isso, a outbox so acumula (comportamento
-- seguro, nada quebra).
create extension if not exists pg_net;

create function public._notification_worker_secret(p_name text)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
    v_value text;
begin
    select decrypted_secret into v_value from vault.decrypted_secrets where name = p_name limit 1;
    return v_value;
exception when others then
    return null;
end;
$$;

revoke execute on function public._notification_worker_secret(text) from public, anon, authenticated;

create function public._notify_worker()
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_url text := public._notification_worker_secret('notification_worker_url');
    v_secret text := public._notification_worker_secret('notification_worker_secret');
begin
    if v_url is null or v_secret is null then
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-worker-secret', v_secret),
        body := jsonb_build_object('trigger', 'outbox'),
        timeout_milliseconds := 5000
    );
exception when others then
    raise warning 'dispatch do worker de notificacao falhou: %', sqlerrm;
end;
$$;

create function public._dispatch_notification_worker()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
    perform public._notify_worker();
    return null;
end;
$$;

create trigger notification_outbox_dispatch
    after insert on public.notification_outbox
    for each statement execute function public._dispatch_notification_worker();

revoke execute on function public._notify_worker() from public, anon, authenticated;
revoke execute on function public._dispatch_notification_worker() from public, anon, authenticated;

create function public._notification_allowed(p_user_id uuid, p_type public.notification_type)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select case p_type
        when 'YOUR_TURN' then coalesce(
            (select queue_turn_enabled from public.notification_preferences where user_id = p_user_id), true)
        when 'SEARCH_EXPIRING' then coalesce(
            (select search_expiring_enabled from public.notification_preferences where user_id = p_user_id), true)
        when 'SEARCH_EXPIRED' then coalesce(
            (select search_expired_enabled from public.notification_preferences where user_id = p_user_id), true)
        else true
    end;
$$;

revoke execute on function public._notification_allowed(uuid, public.notification_type)
    from public, anon, authenticated;

create function public.claim_notification_batch(p_limit integer default 20)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
    v_ids uuid[];
    v_result jsonb;
begin
    with candidate as (
        select id from public.notification_outbox
        where processed_at is null and available_at <= now() and attempt_count < 5
        order by created_at
        limit greatest(1, least(coalesce(p_limit, 20), 100))
        for update skip locked
    ),
    claimed as (
        update public.notification_outbox o
        set attempt_count = o.attempt_count + 1,
            available_at = now() + make_interval(secs => 60 * (o.attempt_count + 1))
        from candidate c where o.id = c.id
        returning o.id
    )
    select coalesce(array_agg(id), array[]::uuid[]) into v_ids from claimed;

    if array_length(v_ids, 1) is null then
        return '[]'::jsonb;
    end if;

    update public.notification_outbox o
    set processed_at = now(), last_error = 'suppressed_by_preference'
    where o.id = any(v_ids) and o.processed_at is null
      and not public._notification_allowed(o.user_id, o.type);

    update public.notification_outbox o
    set processed_at = now(), last_error = 'no_active_device'
    where o.id = any(v_ids) and o.processed_at is null
      and not exists (select 1 from public.user_devices d where d.user_id = o.user_id and d.is_active);

    select coalesce(jsonb_agg(item), '[]'::jsonb) into v_result
    from (
        select jsonb_build_object(
            'id', o.id, 'type', o.type, 'team_id', o.team_id, 'session_id', o.session_id,
            'payload', o.payload, 'locale', coalesce(u.locale, 'en'),
            'tokens', (select coalesce(jsonb_agg(d.fcm_token), '[]'::jsonb)
                from public.user_devices d where d.user_id = o.user_id and d.is_active)
        ) as item
        from public.notification_outbox o
        join public.users u on u.id = o.user_id
        where o.id = any(v_ids) and o.processed_at is null
        order by o.created_at
    ) as rows;

    return v_result;
end;
$$;

create function public.complete_notification(p_id uuid, p_success boolean, p_error text default null)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if p_success then
        update public.notification_outbox set processed_at = now(), last_error = null where id = p_id;
        return;
    end if;

    update public.notification_outbox
    set last_error = p_error,
        processed_at = case when attempt_count >= 5 then now() else null end
    where id = p_id;
end;
$$;

create function public.deactivate_device_token(p_fcm_token text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    update public.user_devices set is_active = false where fcm_token = p_fcm_token;
end;
$$;

revoke execute on function public.claim_notification_batch(integer) from public, anon, authenticated;
revoke execute on function public.complete_notification(uuid, boolean, text) from public, anon, authenticated;
revoke execute on function public.deactivate_device_token(text) from public, anon, authenticated;
grant execute on function public.claim_notification_batch(integer) to service_role;
grant execute on function public.complete_notification(uuid, boolean, text) to service_role;
grant execute on function public.deactivate_device_token(text) to service_role;

create function public.dispatch_pending_notifications()
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    if not exists (
        select 1 from public.notification_outbox where processed_at is null and available_at <= now()
    ) then
        return;
    end if;
    perform public._notify_worker();
end;
$$;

revoke execute on function public.dispatch_pending_notifications() from public, anon, authenticated;

-- pg_cron precisa estar habilitado no projeto (Database > Extensions) antes
-- desta linha funcionar -- se falhar, comente esta chamada, habilite a
-- extensao pelo dashboard, e rode so este select separadamente.
create extension if not exists pg_cron;
select cron.schedule(
    'notification-outbox-dispatch', '* * * * *',
    $$select public.dispatch_pending_notifications();$$
);

-- =======================================================================
-- 6. Solicitacoes de entrada (usuario -> time) e convites diretos
--    (time -> usuario)
-- =======================================================================
create table public.team_join_requests (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.users (id) on delete cascade,
    status text not null default 'PENDING'
        check (status in ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    resolved_by uuid references public.users (id)
);

create index team_join_requests_team_pending_idx
    on public.team_join_requests (team_id) where status = 'PENDING';
create index team_join_requests_user_idx on public.team_join_requests (user_id);
create unique index team_join_requests_pending_unique_idx
    on public.team_join_requests (team_id, user_id) where status = 'PENDING';

alter table public.team_join_requests enable row level security;

create policy team_join_requests_select_own_or_admin
    on public.team_join_requests for select to authenticated
    using (user_id = (select auth.uid()) or public.is_team_admin(team_id));

revoke all on public.team_join_requests from public, anon;
grant select on public.team_join_requests to authenticated;

create table public.team_invitations (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    inviter_id uuid not null references public.users (id) on delete cascade,
    invitee_user_id uuid not null references public.users (id) on delete cascade,
    status text not null default 'PENDING'
        check (status in ('PENDING', 'ACCEPTED', 'REJECTED', 'REVOKED')),
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    resolved_by uuid references public.users (id)
);

create index team_invitations_invitee_pending_idx
    on public.team_invitations (invitee_user_id) where status = 'PENDING';
create index team_invitations_team_idx on public.team_invitations (team_id);
create unique index team_invitations_pending_unique_idx
    on public.team_invitations (team_id, invitee_user_id) where status = 'PENDING';

alter table public.team_invitations enable row level security;

create policy team_invitations_select_own_or_admin
    on public.team_invitations for select to authenticated
    using (invitee_user_id = (select auth.uid()) or public.is_team_admin(team_id));

revoke all on public.team_invitations from public, anon;
grant select on public.team_invitations to authenticated;

-- Realtime de solicitacoes (mesmo padrao de team_matchmaking_revisions).
create table public.user_requests_revisions (
    user_id uuid primary key references public.users (id) on delete cascade,
    revision bigint not null default 1,
    updated_at timestamptz not null default now()
);

alter table public.user_requests_revisions enable row level security;

create policy user_requests_revisions_select_own
    on public.user_requests_revisions for select to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_requests_revisions from anon;
grant select on table public.user_requests_revisions to authenticated;

alter publication supabase_realtime add table public.user_requests_revisions;

create function public._notify_user_requests_changed(p_user_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
    insert into public.user_requests_revisions as r (user_id, revision, updated_at)
    values (p_user_id, 1, now())
    on conflict (user_id) do update set revision = r.revision + 1, updated_at = now();
end;
$$;

create function public._notify_team_admins_requests_changed(p_team_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_admin record;
begin
    for v_admin in
        select user_id from public.team_members where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._notify_user_requests_changed(v_admin.user_id);
    end loop;
end;
$$;

revoke execute on function public._notify_user_requests_changed(uuid) from public, anon, authenticated;
revoke execute on function public._notify_team_admins_requests_changed(uuid) from public, anon, authenticated;

-- RPCs de solicitacao/convite (sem fc_account_id, sem fc_account_teams --
-- versao final ja confirmada no fifa-queue depois do reform).
create function public.request_team_join(p_team_id uuid)
returns public.team_join_requests
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_requester_name text;
    v_team_name text;
    v_admin record;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select name into v_team_name from public.teams where id = p_team_id;
    if v_team_name is null then
        raise exception 'team not found' using errcode = 'FQ053';
    end if;

    if public.is_team_member(p_team_id) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_join_requests
        where team_id = p_team_id and user_id = v_user_id and status = 'PENDING'
    ) then
        raise exception 'a pending request already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_join_requests (team_id, user_id)
    values (p_team_id, v_user_id)
    returning * into v_row;

    perform public._notify_team_admins_requests_changed(p_team_id);

    select display_name into v_requester_name from public.users where id = v_user_id;

    for v_admin in
        select user_id from public.team_members where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._emit_user_notification(
            v_admin.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_RECEIVED',
            'TEAM_JOIN_REQUEST_RECEIVED:' || v_row.id || ':' || v_admin.user_id,
            'notification_team_join_request_received',
            jsonb_build_object(
                'team_id', p_team_id, 'requester_display_name', coalesce(v_requester_name, ''),
                'team_name', v_team_name
            ),
            'requests', jsonb_build_object('team_id', p_team_id)
        );
    end loop;

    return v_row;
end;
$$;

create function public.cancel_team_join_request(p_request_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row from public.team_join_requests
    where id = p_request_id and user_id = v_user_id and status = 'PENDING';

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    update public.team_join_requests
    set status = 'CANCELLED', resolved_at = now(), resolved_by = v_user_id
    where id = p_request_id;
end;
$$;

create function public.approve_team_join_request(p_request_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_team_name text;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row from public.team_join_requests
    where id = p_request_id and status = 'PENDING' for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select name into v_team_name from public.teams where id = v_row.team_id;

    if not exists (
        select 1 from public.team_members where team_id = v_row.team_id and user_id = v_row.user_id
    ) then
        insert into public.team_members (team_id, user_id, role)
        values (v_row.team_id, v_row.user_id, 'PLAYER');
    end if;

    update public.team_join_requests
    set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);

    perform public._emit_user_notification(
        v_row.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_APPROVED',
        'TEAM_JOIN_REQUEST_APPROVED:' || v_row.id,
        'notification_team_join_request_approved',
        jsonb_build_object('team_id', v_row.team_id, 'team_name', v_team_name),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;

create function public.reject_team_join_request(p_request_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row from public.team_join_requests
    where id = p_request_id and status = 'PENDING' for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    update public.team_join_requests
    set status = 'REJECTED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;
end;
$$;

create function public.respond_team_invitation(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_invitations;
    v_team_name text;
    v_display_name text;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row from public.team_invitations
    where id = p_invitation_id and invitee_user_id = v_user_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'invitation not found' using errcode = 'FQ056';
    end if;

    if not p_accept then
        update public.team_invitations
        set status = 'REJECTED', resolved_at = now(), resolved_by = v_user_id
        where id = p_invitation_id;
        return;
    end if;

    if not exists (
        select 1 from public.team_members where team_id = v_row.team_id and user_id = v_user_id
    ) then
        insert into public.team_members (team_id, user_id, role)
        values (v_row.team_id, v_user_id, 'PLAYER');
    end if;

    update public.team_invitations
    set status = 'ACCEPTED', resolved_at = now(), resolved_by = v_user_id
    where id = p_invitation_id;

    select name into v_team_name from public.teams where id = v_row.team_id;
    select display_name into v_display_name from public.users where id = v_user_id;

    perform public._emit_user_notification(
        v_row.inviter_id, 'TEAMS', 'TEAM_INVITATION_ACCEPTED',
        'TEAM_INVITATION_ACCEPTED:' || v_row.id,
        'notification_team_invitation_accepted',
        jsonb_build_object(
            'team_id', v_row.team_id, 'team_name', v_team_name,
            'display_name', coalesce(v_display_name, '')
        ),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;

create function public.get_requests_inbox()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_invitations jsonb;
    v_join_requests jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(jsonb_agg(jsonb_build_object(
        'id', i.id, 'team_id', i.team_id, 'team_name', t.name, 'team_tag', t.tag,
        'team_logo_url', t.logo_url,
        'member_count', (select count(*) from public.team_members m where m.team_id = t.id),
        'created_at', to_jsonb(i.created_at)
    ) order by i.created_at desc), '[]'::jsonb)
    into v_invitations
    from public.team_invitations as i
    join public.teams as t on t.id = i.team_id
    where i.invitee_user_id = v_user_id and i.status = 'PENDING';

    select coalesce(jsonb_agg(jsonb_build_object(
        'id', r.id, 'team_id', r.team_id, 'team_name', t.name,
        'requester_user_id', r.user_id, 'requester_display_name', u.display_name,
        'requester_avatar_url', u.avatar_url, 'created_at', to_jsonb(r.created_at)
    ) order by r.created_at desc), '[]'::jsonb)
    into v_join_requests
    from public.team_join_requests as r
    join public.teams as t on t.id = r.team_id
    join public.users as u on u.id = r.user_id
    where r.status = 'PENDING' and public.is_team_admin(r.team_id);

    return jsonb_build_object('invitations_received', v_invitations, 'join_requests_to_review', v_join_requests);
end;
$$;

revoke execute on function public.request_team_join(uuid) from public, anon;
revoke execute on function public.cancel_team_join_request(uuid) from public, anon;
revoke execute on function public.approve_team_join_request(uuid) from public, anon;
revoke execute on function public.reject_team_join_request(uuid) from public, anon;
revoke execute on function public.respond_team_invitation(uuid, boolean) from public, anon;
revoke execute on function public.get_requests_inbox() from public, anon;
grant execute on function public.request_team_join(uuid) to authenticated;
grant execute on function public.cancel_team_join_request(uuid) to authenticated;
grant execute on function public.approve_team_join_request(uuid) to authenticated;
grant execute on function public.reject_team_join_request(uuid) to authenticated;
grant execute on function public.respond_team_invitation(uuid, boolean) to authenticated;
grant execute on function public.get_requests_inbox() to authenticated;

-- =======================================================================
-- 7. Perfil publico (schema minimo -- campos especificos do eFootball
--    entram depois, quando a Central do eFootball existir)
-- =======================================================================
create table public.user_public_profiles (
    user_id uuid primary key references auth.users (id) on delete cascade,
    slug text unique,
    is_enabled boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint user_public_profiles_slug_format check (slug is null or slug ~ '^[a-z0-9_]{3,24}$')
);

create unique index user_public_profiles_slug_lower_idx
    on public.user_public_profiles (lower(slug)) where slug is not null;

create trigger user_public_profiles_set_updated_at
    before update on public.user_public_profiles
    for each row execute function public.set_updated_at();

alter table public.user_public_profiles enable row level security;

create policy user_public_profiles_select_own
    on public.user_public_profiles for select to authenticated
    using ((select auth.uid()) = user_id);
create policy user_public_profiles_insert_own
    on public.user_public_profiles for insert to authenticated
    with check ((select auth.uid()) = user_id);
create policy user_public_profiles_update_own
    on public.user_public_profiles for update to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

revoke all on table public.user_public_profiles from anon;
grant select, insert, update on table public.user_public_profiles to authenticated;

create function public._public_profile_reserved_slugs()
returns text[]
language sql immutable set search_path = ''
as $$
    select array['admin', 'api', 'app', 'support', 'help', 'settings', 'null', 'undefined'];
$$;

create function public.check_public_profile_slug_available(p_slug text)
returns boolean
language sql stable security definer set search_path = ''
as $$
    select
        p_slug ~ '^[a-z0-9_]{3,24}$'
        and not (lower(p_slug) = any (public._public_profile_reserved_slugs()))
        and not exists (
            select 1 from public.user_public_profiles
            where lower(slug) = lower(p_slug) and user_id <> coalesce((select auth.uid()), '00000000-0000-0000-0000-000000000000'::uuid)
        );
$$;

revoke execute on function public.check_public_profile_slug_available(text) from public;
grant execute on function public.check_public_profile_slug_available(text) to authenticated;

create function public.get_public_profile(p_slug text)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_slug text := lower(btrim(coalesce(p_slug, '')));
    v_row public.user_public_profiles;
    v_display_name text;
    v_avatar_url text;
begin
    if v_slug = '' then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select * into v_row from public.user_public_profiles
    where lower(slug) = v_slug and is_enabled;

    if v_row.user_id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.users where id = v_row.user_id;

    return jsonb_build_object(
        'schema_version', 1, 'found', true,
        'profile', jsonb_build_object('display_name', v_display_name, 'avatar_url', v_avatar_url)
    );
end;
$$;

revoke execute on function public.get_public_profile(text) from public;
grant execute on function public.get_public_profile(text) to anon, authenticated;

create function public.resolve_invite_target(p_slug text)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
    v_slug text := lower(btrim(coalesce(p_slug, '')));
    v_row public.user_public_profiles;
    v_display_name text;
    v_avatar_url text;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if v_slug = '' then
        return jsonb_build_object('found', false);
    end if;

    select * into v_row from public.user_public_profiles where lower(slug) = v_slug and is_enabled;

    if v_row.user_id is null then
        return jsonb_build_object('found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.users where id = v_row.user_id;

    return jsonb_build_object(
        'found', true, 'user_id', v_row.user_id,
        'display_name', v_display_name, 'avatar_url', v_avatar_url
    );
end;
$$;

create function public.invite_team_member(p_team_id uuid, p_slug text)
returns public.team_invitations
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_slug text := lower(btrim(coalesce(p_slug, '')));
    v_target public.user_public_profiles;
    v_row public.team_invitations;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select * into v_target from public.user_public_profiles where lower(slug) = v_slug and is_enabled;

    if v_target.user_id is null then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;
    if v_target.user_id = v_actor_id then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;
    if exists (
        select 1 from public.team_members where team_id = p_team_id and user_id = v_target.user_id
    ) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;
    if exists (
        select 1 from public.team_invitations
        where team_id = p_team_id and invitee_user_id = v_target.user_id and status = 'PENDING'
    ) then
        raise exception 'a pending invitation already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_invitations (team_id, inviter_id, invitee_user_id)
    values (p_team_id, v_actor_id, v_target.user_id)
    returning * into v_row;

    return v_row;
end;
$$;

create function public.revoke_team_invitation(p_invitation_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_invitations;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row from public.team_invitations where id = p_invitation_id and status = 'PENDING';

    if v_row.id is null then
        raise exception 'invitation not found' using errcode = 'FQ056';
    end if;
    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    update public.team_invitations
    set status = 'REVOKED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_invitation_id;
end;
$$;

revoke execute on function public.resolve_invite_target(text) from public, anon;
revoke execute on function public.invite_team_member(uuid, text) from public, anon;
revoke execute on function public.revoke_team_invitation(uuid) from public, anon;
grant execute on function public.resolve_invite_target(text) to authenticated;
grant execute on function public.invite_team_member(uuid, text) to authenticated;
grant execute on function public.revoke_team_invitation(uuid) to authenticated;

-- =======================================================================
-- 8. Auto-criacao de conta (trigger em auth.users) + exclusao de conta
-- =======================================================================
create function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
    candidate text;
begin
    candidate := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
    if candidate = '' then
        candidate := btrim(coalesce(new.raw_user_meta_data ->> 'name', ''));
    end if;
    if candidate = '' then
        candidate := btrim(split_part(coalesce(new.email, ''), '@', 1));
    end if;
    candidate := left(candidate, 32);
    if char_length(candidate) < 2 then
        candidate := 'Jogador';
    end if;

    insert into public.users (id, display_name) values (new.id, candidate)
    on conflict (id) do nothing;

    insert into public.notification_preferences (user_id) values (new.id)
    on conflict (user_id) do nothing;

    return new;
exception when others then
    raise warning 'handle_new_user falhou para % (%): %', new.id, sqlstate, sqlerrm;
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

create function public.delete_my_account()
returns void
language plpgsql security definer set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_membership record;
    v_queue record;
    v_successor uuid;
    v_other_members integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- 1) Estado ao vivo de matchmaking primeiro.
    begin
        perform public.cancel_match_search();
    exception when sqlstate 'FQ015' then
        null;
    end;

    for v_queue in
        select team_id, game_mode from public.match_search_queue where user_id = v_user_id
    loop
        begin
            perform public.leave_match_search_queue(v_queue.team_id, v_queue.game_mode);
        exception when sqlstate 'FQ047' then
            null;
        end;
    end loop;

    -- 2) Anonimiza historico compartilhado com o time (nunca deleta).
    update public.game_matches set user_id = null where user_id = v_user_id;
    update public.match_search_sessions set user_id = null where user_id = v_user_id;
    update public.team_invite_links set created_by = null where created_by = v_user_id;

    -- 3) Times: dissolve se OWNER unico, transfere pro mais antigo se houver
    -- mais gente, ou so sai.
    for v_membership in
        select team_id, role from public.team_members where user_id = v_user_id
    loop
        perform 1 from public.team_members where team_id = v_membership.team_id for update;

        select count(*) into v_other_members from public.team_members
        where team_id = v_membership.team_id and user_id <> v_user_id;

        if v_membership.role = 'OWNER' and v_other_members = 0 then
            delete from public.teams where id = v_membership.team_id;
        else
            if v_membership.role = 'OWNER' then
                select user_id into v_successor from public.team_members
                where team_id = v_membership.team_id and user_id <> v_user_id
                order by joined_at asc, user_id asc limit 1;

                perform public._transfer_team_ownership(v_membership.team_id, v_user_id, v_successor);
            end if;

            delete from public.team_members
            where team_id = v_membership.team_id and user_id = v_user_id;
        end if;
    end loop;

    -- 4) Dado pessoal exclusivo: cascade cuida de user_devices,
    -- notification_outbox, notification_preferences, user_notifications,
    -- user_public_profiles, users. auth.users e apagado depois pela Edge
    -- Function delete-account via admin API (esta funcao nao tem privilegio
    -- pra isso).
end;
$$;

comment on function public.delete_my_account() is
    'Prepara a conta do chamador para exclusao: cancela buscas ativas, anonimiza historico compartilhado, resolve/dissolve times. Nao apaga auth.users -- isso e feito pela Edge Function delete-account via admin API.';

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- =======================================================================
-- 9. Storage: logo de time (bucket compartilhavel, mesmo nome do fifa-queue
--    -- projetos Supabase diferentes, sem colisao)
-- =======================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('team-logos', 'team-logos', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy team_logos_select_public
    on storage.objects for select to anon, authenticated
    using (bucket_id = 'team-logos');

create policy team_logos_insert_owner_only
    on storage.objects for insert to authenticated
    with check (bucket_id = 'team-logos' and public.is_team_owner(((storage.foldername(name))[1])::uuid));

create policy team_logos_update_owner_only
    on storage.objects for update to authenticated
    using (bucket_id = 'team-logos' and public.is_team_owner(((storage.foldername(name))[1])::uuid))
    with check (bucket_id = 'team-logos' and public.is_team_owner(((storage.foldername(name))[1])::uuid));

create policy team_logos_delete_owner_only
    on storage.objects for delete to authenticated
    using (bucket_id = 'team-logos' and public.is_team_owner(((storage.foldername(name))[1])::uuid));

create function public.teams_guard_logo_owner_only()
returns trigger
language plpgsql set search_path = ''
as $$
begin
    if new.logo_url is distinct from old.logo_url and not public.is_team_owner(old.id) then
        raise exception 'only the team owner can change the logo' using errcode = 'FQ012';
    end if;
    return new;
end;
$$;

create trigger teams_guard_logo_owner_only
    before update on public.teams
    for each row execute function public.teams_guard_logo_owner_only();
