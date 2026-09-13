-- Sinal de invalidacao para a tab Solicitacoes, no mesmo espirito de
-- team_matchmaking_revisions (Etapa 6): uma tabela "sino", sem dado de
-- negocio nenhum, so pra o Realtime avisar "algo mudou pra voce" e o
-- cliente re-buscar get_requests_inbox (que continua sendo a unica fonte
-- de verdade). Nunca guarda o pedido/convite em si.
--
-- E POR USUARIO, nao por time: quem precisa saber que mudou e (a) todo
-- OWNER/ADMIN de um time quando um pedido de entrada muda, e (b) o
-- convidado quando um convite direto muda. Uma linha por time nao serve
-- pra (a) porque teria que notificar so um subconjunto dos membros
-- (owner+managers), nao o time inteiro.
create table public.user_requests_revisions (
    user_id uuid primary key references public.profiles (id) on delete cascade,
    revision bigint not null default 1,
    updated_at timestamptz not null default now()
);

comment on table public.user_requests_revisions is
    'Sinal de invalidacao por usuario para a tab Solicitacoes. Nao guarda pedido/convite algum.';

alter table public.user_requests_revisions enable row level security;

create policy user_requests_revisions_select_own
    on public.user_requests_revisions
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_requests_revisions from anon;
grant select on table public.user_requests_revisions to authenticated;

alter publication supabase_realtime add table public.user_requests_revisions;

create function public._notify_user_requests_changed(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.user_requests_revisions as r (user_id, revision, updated_at)
    values (p_user_id, 1, now())
    on conflict (user_id) do update
        set revision = r.revision + 1,
            updated_at = now();
end;
$$;

comment on function public._notify_user_requests_changed(uuid) is
    'Incrementa a revisao do usuario para o Realtime avisar a tab Solicitacoes. So as RPCs de pedido/convite chamam.';

revoke execute on function public._notify_user_requests_changed(uuid)
    from public, anon, authenticated;

-- Notifica todo OWNER/ADMIN (gerente) do time -- quem de fato ve pedidos
-- de entrada daquele time na propria tab Solicitacoes.
create function public._notify_team_admins_requests_changed(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_admin_id uuid;
begin
    for v_admin_id in
        select user_id from public.team_members
        where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._notify_user_requests_changed(v_admin_id);
    end loop;
end;
$$;

comment on function public._notify_team_admins_requests_changed(uuid) is
    'Notifica cada OWNER/ADMIN do time -- usado quando um pedido de entrada e criado ou resolvido.';

revoke execute on function public._notify_team_admins_requests_changed(uuid)
    from public, anon, authenticated;

-- As 6 RPCs abaixo sao recriadas identicas as suas migrations originais,
-- so com uma chamada de notificacao adicionada logo antes do retorno.
-- Nenhuma regra de negocio muda.

create or replace function public.request_team_join(p_team_id uuid, p_fc_account_id uuid)
returns public.team_join_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (select 1 from public.teams where id = p_team_id) then
        raise exception 'team not found' using errcode = 'FQ053';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if public.is_team_member(p_team_id) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_join_requests
        where team_id = p_team_id
          and fc_account_id = p_fc_account_id
          and status = 'PENDING'
    ) then
        raise exception 'a pending request already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_join_requests (team_id, user_id, fc_account_id)
    values (p_team_id, v_user_id, p_fc_account_id)
    returning * into v_row;

    perform public._notify_team_admins_requests_changed(p_team_id);

    return v_row;
end;
$$;

create or replace function public.cancel_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and user_id = v_user_id and status = 'PENDING';

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    update public.team_join_requests
    set status = 'CANCELLED', resolved_at = now(), resolved_by = v_user_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);
end;
$$;

create or replace function public.approve_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and user_id = v_row.user_id
    ) then
        update public.team_join_requests
        set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
        where id = p_request_id;
        perform public._notify_team_admins_requests_changed(v_row.team_id);
        return;
    end if;

    insert into public.team_members (team_id, user_id, role)
    values (v_row.team_id, v_row.user_id, 'PLAYER');

    insert into public.fc_account_teams (fc_account_id, team_id)
    values (v_row.fc_account_id, v_row.team_id)
    on conflict (fc_account_id, team_id) do nothing;

    update public.team_join_requests
    set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);
end;
$$;

create or replace function public.reject_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    update public.team_join_requests
    set status = 'REJECTED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);
end;
$$;

create or replace function public.invite_team_member(p_team_id uuid, p_slug text)
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

    perform public._notify_user_requests_changed(v_target.user_id);

    return v_row;
end;
$$;

create or replace function public.revoke_team_invitation(p_invitation_id uuid)
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

    perform public._notify_user_requests_changed(v_row.invitee_user_id);
end;
$$;
