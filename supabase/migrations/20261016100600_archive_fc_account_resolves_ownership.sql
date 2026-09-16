-- Excluir uma Conta FC (elenco) e um evento de "arrumacao pessoal", mas
-- pode deixar um time orfao de dono: se a pessoa e OWNER solo de algum
-- time, ninguem mais toma decisao por ele. Regra (pedido explicito):
--   - OWNER e unico membro do time -> dissolve o time junto.
--   - OWNER com outros membros -> ownership passa pro membro mais antigo
--     (menor joined_at); o time continua existindo, so a Conta FC some.
-- Roda pra QUALQUER exclusao de Conta FC, nao so a ultima da pessoa --
-- ownership de time e por PESSOA (team_members), nunca por Conta FC
-- (fc_account_teams e um vinculo N:N a parte, ver create_fc_accounts.sql).
--
-- team_members_protect_owner() bloqueia toda transferencia de dono (FQ005)
-- de proposito, desde a Etapa 3 -- so este caminho controlado (via GUC de
-- sessao) tem permissao de fazer o UPDATE de OWNER->PLAYER que a
-- transferencia exige.

create or replace function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'DELETE' then
        if old.role = 'OWNER'
            and exists (select 1 from public.teams where id = old.team_id)
            and coalesce(current_setting('app.allow_owner_transfer', true), '') <> 'on'
        then
            raise exception 'team owner cannot be removed'
                using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.user_id is distinct from old.user_id
    then
        raise exception 'team membership identity is immutable'
            using errcode = 'FQ004';
    end if;

    if old.role = 'OWNER' and new.role <> 'OWNER'
        and coalesce(current_setting('app.allow_owner_transfer', true), '') <> 'on'
    then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    new.joined_at := old.joined_at;
    return new;
end;
$$;

create or replace function public.archive_fc_account(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_updated integer;
    v_team record;
    v_successor uuid;
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

    -- Times que a pessoa possui: unico membro -> dissolve; com mais gente
    -- -> repassa a posse pro membro mais antigo. Feito num loop (nao um
    -- unico UPDATE em massa) porque cada time pode ter um sucessor
    -- diferente.
    for v_team in
        select team_id from public.team_members
        where user_id = v_user_id and role = 'OWNER'
    loop
        select user_id into v_successor
        from public.team_members
        where team_id = v_team.team_id and user_id <> v_user_id
        order by joined_at asc
        limit 1;

        if v_successor is null then
            delete from public.teams where id = v_team.team_id;
        else
            perform set_config('app.allow_owner_transfer', 'on', true);
            update public.team_members
                set role = 'PLAYER'
                where team_id = v_team.team_id and user_id = v_user_id;
            update public.team_members
                set role = 'OWNER'
                where team_id = v_team.team_id and user_id = v_successor;
            perform set_config('app.allow_owner_transfer', 'off', true);
        end if;
    end loop;
end;
$$;

comment on function public.archive_fc_account(uuid) is
    'Arquiva (is_active = false) a Conta FC do chamador. Tambem resolve times dos quais ele e OWNER: dissolve se for o unico membro, ou repassa a posse pro membro mais antigo se houver mais gente -- nunca deixa um time sem dono.';
