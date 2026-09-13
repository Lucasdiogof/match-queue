-- Remover jogador do time e promover/rebaixar gerente (papel ADMIN no banco,
-- exibido como "Gerente" no app -- ver comentario em team_role.dart sobre por
-- que o enum do banco continua ADMIN em vez de renomear a coluna).
--
-- Ate aqui so existiam dois jeitos de uma linha entrar em team_members
-- (create_team e join_team_by_invite) e nenhum jeito de sair ou trocar de
-- papel -- team_members_rls.sql ja documentava isso como proxima etapa.
--
-- Toda a matriz de permissao mora aqui, no servidor, nunca so na UI:
-- OWNER remove PLAYER ou ADMIN; ADMIN remove so PLAYER; ninguem remove OWNER
-- (o trigger team_members_protect_owner ja garante isso na propria escrita).
-- Promover/rebaixar e OWNER-only.

create function public.remove_team_member(p_team_id uuid, p_target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_actor_role public.team_role;
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select role into v_actor_role
    from public.team_members
    where team_id = p_team_id and user_id = v_actor_id;

    if v_actor_role is null or v_actor_role = 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team owner cannot be removed' using errcode = 'FQ005';
    end if;

    -- ADMIN (gerente) so remove PLAYER: nunca outro gerente, nunca o dono.
    if v_actor_role = 'ADMIN' and v_target_role <> 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    delete from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

comment on function public.remove_team_member(uuid, uuid) is
    'OWNER remove PLAYER ou ADMIN; ADMIN remove so PLAYER. Nunca remove OWNER (trigger de protecao cobre isso tambem na propria escrita).';

create function public.set_team_member_role(
    p_team_id uuid,
    p_target_user_id uuid,
    p_role public.team_role
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    update public.team_members
    set role = p_role
    where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

comment on function public.set_team_member_role(uuid, uuid, public.team_role) is
    'Somente OWNER promove PLAYER->ADMIN ou rebaixa ADMIN->PLAYER. Nunca atribui OWNER (sem transferencia de dono nesta etapa).';

revoke execute on function public.remove_team_member(uuid, uuid) from public, anon;
revoke execute on function public.set_team_member_role(uuid, uuid, public.team_role) from public, anon;

grant execute on function public.remove_team_member(uuid, uuid) to authenticated;
grant execute on function public.set_team_member_role(uuid, uuid, public.team_role) to authenticated;
