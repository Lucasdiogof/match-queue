-- RPCs de elenco. Continuam o namespace FQ00x:
--   FQ025 elenco não encontrado, não é seu, ou está arquivado
--   FQ026 elenco não está vinculado ao time
--   FQ027 nome de elenco inválido
--   FQ028 divisão de Rivals inválida

create function public.create_fc_account(p_name text)
returns public.user_fc_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_name text;
    v_account public.user_fc_accounts;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_name := btrim(coalesce(p_name, ''));
    if char_length(v_name) < 2 or char_length(v_name) > 40 then
        raise exception 'account name must have between 2 and 40 characters'
            using errcode = 'FQ027';
    end if;

    insert into public.user_fc_accounts (user_id, name)
    values (v_user_id, v_name)
    returning * into v_account;

    return v_account;
end;
$$;

create function public.update_fc_account(p_id uuid, p_name text)
returns public.user_fc_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_name text;
    v_account public.user_fc_accounts;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_name := btrim(coalesce(p_name, ''));
    if char_length(v_name) < 2 or char_length(v_name) > 40 then
        raise exception 'account name must have between 2 and 40 characters'
            using errcode = 'FQ027';
    end if;

    update public.user_fc_accounts
    set name = v_name
    where id = p_id and user_id = v_user_id
    returning * into v_account;

    if v_account.id is null then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return v_account;
end;
$$;

-- Arquiva em vez de apagar (item 40) -- histórico de partidas/buscas nunca
-- perde a referência.
create function public.archive_fc_account(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_updated integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.user_fc_accounts
    set is_active = false
    where id = p_id and user_id = v_user_id;

    get diagnostics v_updated = row_count;
    if v_updated = 0 then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;
end;
$$;

create function public.update_rivals_division(p_id uuid, p_division text)
returns public.user_fc_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_account public.user_fc_accounts;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_division is not null and p_division not in (
        'DIV_10', 'DIV_9', 'DIV_8', 'DIV_7', 'DIV_6',
        'DIV_5', 'DIV_4', 'DIV_3', 'DIV_2', 'DIV_1', 'ELITE'
    ) then
        raise exception 'invalid rivals division' using errcode = 'FQ028';
    end if;

    update public.user_fc_accounts
    set rivals_division = p_division
    where id = p_id and user_id = v_user_id
    returning * into v_account;

    if v_account.id is null then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return v_account;
end;
$$;

-- Elenco -> Time. Exige: dono do elenco, elenco ativo, e o CHAMADOR (mesma
-- pessoa) é membro do time -- não dá pra vincular a um time que você não
-- participa, mesmo sendo dono do elenco.
create function public.link_fc_account_to_team(p_fc_account_id uuid, p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    insert into public.fc_account_teams (fc_account_id, team_id)
    values (p_fc_account_id, p_team_id)
    on conflict (fc_account_id, team_id) do nothing;
end;
$$;

create function public.unlink_fc_account_from_team(p_fc_account_id uuid, p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    delete from public.fc_account_teams
    where fc_account_id = p_fc_account_id
      and team_id = p_team_id
      and exists (
          select 1 from public.user_fc_accounts a
          where a.id = fc_account_teams.fc_account_id and a.user_id = v_user_id
      );
end;
$$;

revoke execute on function public.create_fc_account(text) from public, anon;
revoke execute on function public.update_fc_account(uuid, text) from public, anon;
revoke execute on function public.archive_fc_account(uuid) from public, anon;
revoke execute on function public.update_rivals_division(uuid, text) from public, anon;
revoke execute on function public.link_fc_account_to_team(uuid, uuid) from public, anon;
revoke execute on function public.unlink_fc_account_from_team(uuid, uuid) from public, anon;

grant execute on function public.create_fc_account(text) to authenticated;
grant execute on function public.update_fc_account(uuid, text) to authenticated;
grant execute on function public.archive_fc_account(uuid) to authenticated;
grant execute on function public.update_rivals_division(uuid, text) to authenticated;
grant execute on function public.link_fc_account_to_team(uuid, uuid) to authenticated;
grant execute on function public.unlink_fc_account_from_team(uuid, uuid) to authenticated;
