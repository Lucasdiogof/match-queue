-- RPCs do lado de quem gerencia o link de um time: obter o ativo (qualquer
-- membro), girar e desativar (somente OWNER/ADMIN, verificado aqui dentro
-- -- esconder o botao na UI nao basta).

-- Qualquer membro pode obter o link ativo do proprio time (para copiar ou
-- compartilhar); cria um na hora se o time ainda nao tiver nenhum --
-- cobre tanto os times novos quanto os que ja existiam antes desta etapa
-- e ainda nao passaram pelo backfill por algum motivo.
create function public.get_or_create_team_invite(p_team_id uuid)
returns public.team_invite_links
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied'
            using errcode = 'FQ012';
    end if;

    return public._ensure_active_team_invite(p_team_id, v_user_id);
end;
$$;

revoke execute on function public.get_or_create_team_invite(uuid) from public, anon;
grant execute on function public.get_or_create_team_invite(uuid) to authenticated;

-- Substitui o link ativo por um novo. O antigo nunca e apagado: vira
-- is_active=false com revoked_at preenchido, o novo nasce ativo. O
-- advisory lock (mesma chave usada por _ensure_active_team_invite) evita
-- que um rotate concorrente com outro rotate -- ou com um ensure lazy --
-- deixe o time com dois links ativos ou esbarre no indice unico parcial.
create function public.rotate_team_invite(p_team_id uuid)
returns public.team_invite_links
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_new public.team_invite_links;
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied'
            using errcode = 'FQ012';
    end if;

    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    update public.team_invite_links
    set is_active = false, revoked_at = now()
    where team_id = p_team_id and is_active;

    insert into public.team_invite_links (team_id, code, created_by)
    values (p_team_id, public._generate_invite_code(), v_user_id)
    returning * into v_new;

    return v_new;
end;
$$;

revoke execute on function public.rotate_team_invite(uuid) from public, anon;
grant execute on function public.rotate_team_invite(uuid) to authenticated;

-- Desativa o link ativo sem criar um novo. Devolve false (em vez de erro)
-- se o time ja nao tinha nenhum link ativo, para a chamada ser idempotente.
create function public.revoke_team_invite(p_team_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_count integer;
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied'
            using errcode = 'FQ012';
    end if;

    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    update public.team_invite_links
    set is_active = false, revoked_at = now()
    where team_id = p_team_id and is_active;

    get diagnostics v_count = row_count;
    return v_count > 0;
end;
$$;

revoke execute on function public.revoke_team_invite(uuid) from public, anon;
grant execute on function public.revoke_team_invite(uuid) to authenticated;
