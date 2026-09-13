-- Convite direto de um time para um usuario (time -> usuario). Direcao
-- oposta de team_join_requests.
--
-- Descoberta do convidado e pelo slug do perfil publico (mesmo mecanismo de
-- /u/:slug ja existente), nunca por e-mail: e o unico identificador publico
-- e opt-in que o produto ja tem hoje. Quem nao habilitou perfil publico nao
-- pode ser convidado diretamente -- so pode entrar por pedido/codigo.
create table public.team_invitations (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    inviter_id uuid not null references public.profiles (id) on delete cascade,
    invitee_user_id uuid not null references public.profiles (id) on delete cascade,
    -- Elenco publico do convidado no momento do convite, so para exibicao
    -- (o Elenco de fato vinculado ao aceitar pode ser outro se o convidado
    -- trocar o Elenco do perfil publico antes de responder).
    fc_account_id uuid references public.user_fc_accounts (id) on delete set null,
    status text not null default 'PENDING'
        check (status in ('PENDING', 'ACCEPTED', 'REJECTED', 'REVOKED')),
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    resolved_by uuid references public.profiles (id)
);

comment on table public.team_invitations is
    'Convite direto de um time para um usuario, descoberto pelo slug do perfil publico. Aceitar cria team_members (PLAYER).';

create index team_invitations_invitee_pending_idx
    on public.team_invitations (invitee_user_id)
    where status = 'PENDING';

create index team_invitations_team_idx on public.team_invitations (team_id);

create unique index team_invitations_pending_unique_idx
    on public.team_invitations (team_id, invitee_user_id)
    where status = 'PENDING';

alter table public.team_invitations enable row level security;

create policy team_invitations_select_own_or_admin
    on public.team_invitations
    for select
    to authenticated
    using (
        invitee_user_id = (select auth.uid())
        or public.is_team_admin(team_id)
    );

revoke all on public.team_invitations from public, anon;
grant select on public.team_invitations to authenticated;

-- Preview do alvo antes de enviar o convite: so identidade minima, nunca o
-- payload completo de get_public_profile (que carrega stats/squad).
create function public.resolve_invite_target(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
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

    select * into v_row
    from public.user_public_profiles
    where lower(slug) = v_slug and is_enabled;

    if v_row.user_id is null then
        return jsonb_build_object('found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.profiles where id = v_row.user_id;

    return jsonb_build_object(
        'found', true,
        'user_id', v_row.user_id,
        'display_name', v_display_name,
        'avatar_url', v_avatar_url,
        'fc_account_name', (
            select name from public.user_fc_accounts
            where id = v_row.fc_account_id
        )
    );
end;
$$;

comment on function public.resolve_invite_target(text) is
    'Preview minimo do alvo de um convite direto, resolvido pelo slug do perfil publico. Nunca expõe stats/squad -- so identidade.';

-- Envia o convite. Re-resolve o slug no servidor (nunca confia num user_id
-- vindo do cliente) para evitar corrida entre o preview e o envio.
create function public.invite_team_member(p_team_id uuid, p_slug text)
returns public.team_invitations
language plpgsql
security definer
set search_path = ''
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

    select * into v_target
    from public.user_public_profiles
    where lower(slug) = v_slug and is_enabled;

    if v_target.user_id is null then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;

    if v_target.user_id = v_actor_id then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;

    if exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = v_target.user_id
    ) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_invitations
        where team_id = p_team_id
          and invitee_user_id = v_target.user_id
          and status = 'PENDING'
    ) then
        raise exception 'a pending invitation already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_invitations (
        team_id, inviter_id, invitee_user_id, fc_account_id
    ) values (
        p_team_id, v_actor_id, v_target.user_id, v_target.fc_account_id
    )
    returning * into v_row;

    return v_row;
end;
$$;

comment on function public.invite_team_member(uuid, text) is
    'OWNER/ADMIN convida um jogador pelo slug do perfil publico dele. Re-resolve o slug no servidor, nunca confia em identidade vinda do cliente.';

create function public.revoke_team_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_invitations;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_invitations
    where id = p_invitation_id and status = 'PENDING';

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

comment on function public.revoke_team_invitation(uuid) is
    'OWNER/ADMIN revoga um convite PENDING enviado pelo proprio time.';

create function public.respond_team_invitation(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_invitations;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_invitations
    where id = p_invitation_id
      and invitee_user_id = v_user_id
      and status = 'PENDING'
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
        select 1 from public.team_members
        where team_id = v_row.team_id and user_id = v_user_id
    ) then
        insert into public.team_members (team_id, user_id, role)
        values (v_row.team_id, v_user_id, 'PLAYER');

        if v_row.fc_account_id is not null then
            insert into public.fc_account_teams (fc_account_id, team_id)
            values (v_row.fc_account_id, v_row.team_id)
            on conflict (fc_account_id, team_id) do nothing;
        end if;
    end if;

    update public.team_invitations
    set status = 'ACCEPTED', resolved_at = now(), resolved_by = v_user_id
    where id = p_invitation_id;
end;
$$;

comment on function public.respond_team_invitation(uuid, boolean) is
    'So o proprio convidado responde. Aceitar cria team_members (PLAYER) e vincula o Elenco referenciado no convite, se houver, na mesma transacao. Recusar so fecha o convite.';

revoke execute on function public.resolve_invite_target(text) from public, anon;
revoke execute on function public.invite_team_member(uuid, text) from public, anon;
revoke execute on function public.revoke_team_invitation(uuid) from public, anon;
revoke execute on function public.respond_team_invitation(uuid, boolean) from public, anon;

grant execute on function public.resolve_invite_target(text) to authenticated;
grant execute on function public.invite_team_member(uuid, text) to authenticated;
grant execute on function public.revoke_team_invitation(uuid) to authenticated;
grant execute on function public.respond_team_invitation(uuid, boolean) to authenticated;
