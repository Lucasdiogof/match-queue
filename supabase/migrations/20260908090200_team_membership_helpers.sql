-- Helpers de membership usados pelas policies.
--
-- Sao security definer por um motivo especifico: uma policy de team_members
-- que consultasse team_members diretamente entraria em recursao infinita,
-- porque a subconsulta dispara a propria policy. Rodando como owner, a
-- consulta interna passa por fora da RLS e a recursao deixa de existir.
--
-- O que essas funcoes expoem e limitado de proposito: recebem um id e
-- devolvem um booleano sobre o proprio chamador. Nao ha como usa-las para ler
-- dado de ninguem -- no maximo para descobrir algo que o chamador ja sabe
-- sobre si mesmo.
--
-- Sao stable (nao volatile) para o planner avaliar uma vez por statement em
-- vez de uma vez por linha.

create function public.is_team_member(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.team_members
        where team_id = p_team_id
          and user_id = (select auth.uid())
    );
$$;

create function public.is_team_admin(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.team_members
        where team_id = p_team_id
          and user_id = (select auth.uid())
          and role in ('OWNER', 'ADMIN')
    );
$$;

create function public.is_team_owner(p_team_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.team_members
        where team_id = p_team_id
          and user_id = (select auth.uid())
          and role = 'OWNER'
    );
$$;

-- Base da visibilidade de profiles entre companheiros de time.
create function public.shares_team_with(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.team_members as mine
        join public.team_members as theirs
            on theirs.team_id = mine.team_id
        where mine.user_id = (select auth.uid())
          and theirs.user_id = p_user_id
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
