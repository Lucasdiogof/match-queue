-- Exclusao de Conta FC (o "Perfil" do dominio: a identidade operacional que
-- o login cria depois de autenticar) e transferencia de posse de time.
--
-- Contexto que ja existia antes desta migration:
--   - team_members tem PK (team_id, fc_account_id) desde
--     20261013103800: membership e ownership sao POR CONTA FC, nao por
--     login. user_id e coluna desnormalizada, sincronizada por trigger.
--   - team_members_single_owner_idx (unique parcial) garante no maximo um
--     OWNER por time.
--   - team_members_protect_owner() proibia QUALQUER saida de OWNER --
--     nem remover a linha, nem trocar o papel (FQ005).
--   - archive_fc_account() so fazia is_active = false, sem tocar em time:
--     arquivar o OWNER deixava o time preso a uma conta que nao existe
--     mais na UI.
--
-- O que muda aqui:
--   1. team_members_protect_owner() passa a permitir a saida do OWNER
--      quando -- e somente quando -- a operacao vem de um dos dois
--      caminhos controlados abaixo, sinalizado por um GUC de transacao.
--      Escrita direta (PostgREST/RLS) continua bloqueada como antes.
--   2. transfer_team_ownership(): transferencia manual, so o OWNER.
--   3. archive_fc_account(): resolve cada time da conta antes de arquivar
--      -- dissolve se ela era o unico membro, transfere a posse pro membro
--      mais antigo se havia mais gente, ou so sai do time se nao era OWNER.
--
-- Ordem de desempate da sucessao: joined_at asc, fc_account_id asc. Nunca
-- aleatoria -- dois membros com o mesmo joined_at (mesmo lote de convite)
-- ainda resolvem pro mesmo sucessor em qualquer replica.

-- ---------------------------------------------------------------------
-- 1. Trigger de protecao: mesma invariante, com uma porta controlada.
-- ---------------------------------------------------------------------
create or replace function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    -- Setado por set_config(..., true) = escopo de transacao, some sozinho
    -- no commit/rollback. Nenhum caminho client-facing consegue liga-lo:
    -- as RPCs abaixo sao security definer e so elas chamam set_config.
    v_transfer_allowed boolean :=
        coalesce(current_setting('app.allow_owner_transfer', true), '') = 'on';
begin
    if tg_op = 'DELETE' then
        if old.role = 'OWNER'
            and not v_transfer_allowed
            and exists (select 1 from public.teams where id = old.team_id)
        then
            raise exception 'team owner cannot be removed'
                using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.fc_account_id is distinct from old.fc_account_id
    then
        raise exception 'team membership identity is immutable'
            using errcode = 'FQ004';
    end if;

    if old.role = 'OWNER' and new.role <> 'OWNER' and not v_transfer_allowed then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    new.joined_at := old.joined_at;
    return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 2. Helper interno da troca de posse.
--
-- A ordem importa e nao e negociavel: team_members_single_owner_idx NAO e
-- deferrable, entao existir dois OWNER por um instante ja estoura. Rebaixa
-- o antigo primeiro (libera o slot do indice), promove o novo depois.
-- ---------------------------------------------------------------------
create function public._transfer_team_ownership(
    p_team_id uuid,
    p_from_fc_account_id uuid,
    p_to_fc_account_id uuid
)
returns void
language plpgsql
set search_path = ''
as $$
begin
    perform set_config('app.allow_owner_transfer', 'on', true);

    update public.team_members
    set role = 'PLAYER'
    where team_id = p_team_id and fc_account_id = p_from_fc_account_id;

    update public.team_members
    set role = 'OWNER'
    where team_id = p_team_id and fc_account_id = p_to_fc_account_id;

    perform set_config('app.allow_owner_transfer', 'off', true);
end;
$$;

comment on function public._transfer_team_ownership(uuid, uuid, uuid) is
    'Uso interno. Rebaixa o OWNER atual e promove o novo, nessa ordem (o indice unico de OWNER nao e deferrable). Nao valida permissao -- quem chama valida.';

-- Critico: esta funcao liga o GUC que destranca o trigger de protecao do
-- OWNER e NAO valida permissao nenhuma. Sem este revoke ela nasceria
-- executavel por PUBLIC (padrao do Postgres) e viraria exatamente o
-- buraco que o trigger existe pra fechar: qualquer cliente autenticado
-- chamaria ela direto pra se promover a OWNER.
revoke execute on function public._transfer_team_ownership(uuid, uuid, uuid)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Transferencia manual: so o OWNER, so pra quem ja e membro do time.
-- ---------------------------------------------------------------------
create function public.transfer_team_ownership(
    p_team_id uuid,
    p_target_fc_account_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_owner_fc_account_id uuid;
    v_target_role public.team_role;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- Trava as linhas de membership deste time antes de decidir qualquer
    -- coisa: uma remocao/saida concorrente do alvo espera esta transacao,
    -- e quando rodar vai encontrar o alvo ja como OWNER (e recusar, que e
    -- o comportamento correto -- OWNER nao se remove).
    perform 1 from public.team_members
    where team_id = p_team_id
    for update;

    -- Quem manda e a CONTA que tem o papel OWNER, nao o login: o mesmo
    -- login pode ter outra conta como PLAYER no mesmo time.
    select m.fc_account_id into v_owner_fc_account_id
    from public.team_members as m
    join public.user_fc_accounts as a on a.id = m.fc_account_id
    where m.team_id = p_team_id
      and m.role = 'OWNER'
      and a.user_id = v_user_id;

    if v_owner_fc_account_id is null then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if p_target_fc_account_id = v_owner_fc_account_id then
        raise exception 'target is already the owner' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and fc_account_id = p_target_fc_account_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team'
            using errcode = 'FQ012';
    end if;

    perform public._transfer_team_ownership(
        p_team_id, v_owner_fc_account_id, p_target_fc_account_id
    );
end;
$$;

comment on function public.transfer_team_ownership(uuid, uuid) is
    'OWNER passa a posse do time pra outro membro (alvo e a Conta FC, nao o login). O OWNER antigo vira PLAYER e continua no time. Atomica.';

revoke execute on function public.transfer_team_ownership(uuid, uuid) from public, anon;
grant execute on function public.transfer_team_ownership(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 4. archive_fc_account: resolve os times antes de arquivar.
--
-- Uma conta pode estar em varios times com papeis diferentes, entao a
-- regra roda por time:
--   OWNER e unico membro  -> dissolve o time (cascade limpa o resto)
--   OWNER com mais gente  -> transfere pro mais antigo e sai
--   PLAYER/ADMIN          -> so sai
-- ---------------------------------------------------------------------
create or replace function public.archive_fc_account(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_updated integer;
    v_membership record;
    v_queue record;
    v_successor uuid;
    v_other_members integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    -- 1) Estado AO VIVO de matchmaking primeiro, pelo mesmo motivo (e na
    -- mesma ordem) de delete_my_account: as RPCs existentes promovem quem
    -- estava esperando na fila e notificam o time. Cancelar na mao aqui
    -- deixaria fila parada.
    begin
        perform public.cancel_match_search(p_id);
    exception
        when sqlstate 'FQ015' then
            null;
    end;

    for v_queue in
        select team_id, game_mode from public.match_search_queue
        where fc_account_id = p_id
    loop
        begin
            perform public.leave_match_search_queue(
                p_id, v_queue.team_id, v_queue.game_mode
            );
        exception
            when sqlstate 'FQ047' then
                null;
        end;
    end loop;

    -- 2) Times. Trava as memberships de cada time antes de decidir, pra
    -- nao escolher um sucessor que esta saindo agora numa transacao
    -- concorrente.
    for v_membership in
        select team_id, role from public.team_members where fc_account_id = p_id
    loop
        perform 1 from public.team_members
        where team_id = v_membership.team_id
        for update;

        select count(*) into v_other_members
        from public.team_members
        where team_id = v_membership.team_id and fc_account_id <> p_id;

        if v_membership.role = 'OWNER' and v_other_members = 0 then
            -- Unico membro: o time morre junto. Cascade limpa
            -- team_members/convites/filas/partidas daquele time -- ninguem
            -- mais tinha acesso a ele.
            delete from public.teams where id = v_membership.team_id;
        else
            if v_membership.role = 'OWNER' then
                select fc_account_id into v_successor
                from public.team_members
                where team_id = v_membership.team_id and fc_account_id <> p_id
                order by joined_at asc, fc_account_id asc
                limit 1;

                perform public._transfer_team_ownership(
                    v_membership.team_id, p_id, v_successor
                );
            end if;

            delete from public.team_members
            where team_id = v_membership.team_id and fc_account_id = p_id;
        end if;
    end loop;

    -- 3) Vinculo "esta conta joga por este time" (conceito separado de
    -- membership): sem ele a conta arquivada continuaria aparecendo como
    -- elenco disponivel do time.
    delete from public.fc_account_teams where fc_account_id = p_id;

    -- 4) Arquiva em vez de apagar (decisao original desta RPC): historico
    -- de partidas/buscas nunca perde a referencia.
    update public.user_fc_accounts
    set is_active = false
    where id = p_id and user_id = v_user_id;

    get diagnostics v_updated = row_count;
    if v_updated = 0 then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;
end;
$$;

comment on function public.archive_fc_account(uuid) is
    'Arquiva a Conta FC do chamador (is_active = false) e resolve os times dela: dissolve o time se era o unico membro, transfere a posse pro membro mais antigo (joined_at asc, fc_account_id asc) se era OWNER com mais gente, ou so sai do time. Cancela busca/fila ativa antes. Tudo numa transacao.';
