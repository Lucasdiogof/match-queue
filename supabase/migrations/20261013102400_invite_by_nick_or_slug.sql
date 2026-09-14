-- Convite por nick OU slug: resolve_invite_target e invite_team_member agora
-- tentam primeiro pelo slug do perfil publico; se nao encontrar, tentam pelo
-- display_name (case-insensitive, match exato). Se o nick tiver duplicatas,
-- nenhum e retornado (ambiguidade) -- o usuario precisa usar o slug nesse caso.

create or replace function public.resolve_invite_target(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_input text := lower(btrim(coalesce(p_slug, '')));
    v_row public.user_public_profiles;
    v_display_name text;
    v_avatar_url text;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if v_input = '' then
        return jsonb_build_object('found', false);
    end if;

    -- 1) Tenta pelo slug
    select * into v_row
    from public.user_public_profiles
    where lower(slug) = v_input and is_enabled;

    -- 2) Fallback: display_name exato (case-insensitive), so se unico
    if v_row.user_id is null then
        begin
            select upp.* into strict v_row
            from public.user_public_profiles upp
            join public.profiles p on p.id = upp.user_id
            where lower(p.display_name) = v_input
              and upp.is_enabled;
        exception
            when no_data_found or too_many_rows then
                null;
        end;
    end if;

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


create or replace function public.invite_team_member(p_team_id uuid, p_slug text)
returns public.team_invitations
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_input text := lower(btrim(coalesce(p_slug, '')));
    v_target public.user_public_profiles;
    v_row public.team_invitations;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    -- 1) Tenta pelo slug
    select * into v_target
    from public.user_public_profiles
    where lower(slug) = v_input and is_enabled;

    -- 2) Fallback: display_name exato (case-insensitive), so se unico
    if v_target.user_id is null then
        begin
            select upp.* into strict v_target
            from public.user_public_profiles upp
            join public.profiles p on p.id = upp.user_id
            where lower(p.display_name) = v_input
              and upp.is_enabled;
        exception
            when no_data_found or too_many_rows then
                null;
        end;
    end if;

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
        raise exception 'duplicate invitation' using errcode = 'FQ055';
    end if;

    insert into public.team_invitations (team_id, inviter_id, invitee_user_id, fc_account_id)
    values (p_team_id, v_actor_id, v_target.user_id, v_target.fc_account_id)
    returning * into v_row;

    return v_row;
end;
$$;
