-- Notificacoes dos 5 eventos novos de Solicitacoes, usando o MESMO helper
-- _emit_user_notification da Etapa 15 (grava inbox + condicionalmente
-- outbox de push, idempotente por dedupe_key). Categoria TEAMS -- ja existe
-- o toggle teams_enabled, nenhuma categoria nova necessaria.
--
-- Cuidado de dedupe_key que o _recompute_team_sports_leaders NAO tem (fora
-- de escopo consertar aqui, ver item 42): o indice de dedupe e GLOBAL, nao
-- por usuario. Quando o mesmo evento vai para varias pessoas (um pedido
-- pode ter mais de um gerente pra avisar), o dedupe_key PRECISA incluir o
-- destinatario -- senao so a primeira chamada do loop insere e as demais
-- silenciosamente colidem no "on conflict do nothing".

create or replace function public._notification_allowed(
    p_user_id uuid,
    p_type public.notification_type
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select case p_type
        when 'YOUR_TURN' then coalesce(
            (select matchmaking_enabled and queue_turn_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRING' then coalesce(
            (select matchmaking_enabled and search_expiring_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRED' then coalesce(
            (select matchmaking_enabled and search_expired_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_MEMBER_JOINED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_LEADER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_SCORER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_ASSIST_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'WEEKEND_LEAGUE_FINISHED' then coalesce(
            (select weekend_league_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'RIVALS_DIVISION_CHANGED' then coalesce(
            (select rivals_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_RECEIVED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_APPROVED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_REJECTED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_INVITATION_RECEIVED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_INVITATION_ACCEPTED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        else true
    end;
$$;

revoke execute on function
    public._notification_allowed(uuid, public.notification_type)
    from public, anon, authenticated;

create or replace function public.request_team_join(p_team_id uuid, p_fc_account_id uuid)
returns public.team_join_requests
language plpgsql
security definer
set search_path = ''
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

    select display_name into v_requester_name
    from public.profiles where id = v_user_id;

    for v_admin in
        select user_id from public.team_members
        where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._emit_user_notification(
            v_admin.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_RECEIVED',
            'TEAM_JOIN_REQUEST_RECEIVED:' || v_row.id || ':' || v_admin.user_id,
            'notification_team_join_request_received',
            jsonb_build_object(
                'team_id', p_team_id,
                'requester_display_name', coalesce(v_requester_name, ''),
                'team_name', v_team_name
            ),
            'requests', jsonb_build_object('team_id', p_team_id)
        );
    end loop;

    return v_row;
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
    v_team_name text;
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

    select name into v_team_name from public.teams where id = v_row.team_id;

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

    perform public._emit_user_notification(
        v_row.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_APPROVED',
        'TEAM_JOIN_REQUEST_APPROVED:' || v_row.id,
        'notification_team_join_request_approved',
        jsonb_build_object('team_id', v_row.team_id, 'team_name', v_team_name),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
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
    v_team_name text;
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

    select name into v_team_name from public.teams where id = v_row.team_id;

    update public.team_join_requests
    set status = 'REJECTED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);

    perform public._emit_user_notification(
        v_row.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_REJECTED',
        'TEAM_JOIN_REQUEST_REJECTED:' || v_row.id,
        'notification_team_join_request_rejected',
        jsonb_build_object('team_id', v_row.team_id, 'team_name', v_team_name),
        null, '{}'::jsonb
    );
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
    v_team_name text;
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

    select name into v_team_name from public.teams where id = p_team_id;

    insert into public.team_invitations (
        team_id, inviter_id, invitee_user_id, fc_account_id
    ) values (
        p_team_id, v_actor_id, v_target.user_id, v_target.fc_account_id
    )
    returning * into v_row;

    perform public._notify_user_requests_changed(v_target.user_id);

    perform public._emit_user_notification(
        v_target.user_id, 'TEAMS', 'TEAM_INVITATION_RECEIVED',
        'TEAM_INVITATION_RECEIVED:' || v_row.id,
        'notification_team_invitation_received',
        jsonb_build_object('team_id', p_team_id, 'team_name', v_team_name),
        'requests', jsonb_build_object('team_id', p_team_id)
    );

    return v_row;
end;
$$;

create or replace function public.respond_team_invitation(p_invitation_id uuid, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
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

    select name into v_team_name from public.teams where id = v_row.team_id;
    select display_name into v_display_name from public.profiles where id = v_user_id;

    perform public._emit_user_notification(
        v_row.inviter_id, 'TEAMS', 'TEAM_INVITATION_ACCEPTED',
        'TEAM_INVITATION_ACCEPTED:' || v_row.id,
        'notification_team_invitation_accepted',
        jsonb_build_object(
            'team_id', v_row.team_id,
            'team_name', v_team_name,
            'display_name', coalesce(v_display_name, '')
        ),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;
