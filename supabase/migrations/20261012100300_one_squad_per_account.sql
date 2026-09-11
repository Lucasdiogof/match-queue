-- Uma Conta tem no maximo UM Elenco.
--
-- Ate aqui isso era so regra de produto: o schema permitia N elencos por
-- conta, e a UI oferecia uma lista. Auditoria em producao antes de aplicar:
-- 2 elencos, 2 ativos, 2 contas com elenco -- ou seja, ja era 1:1 de fato,
-- nenhuma conta com duplicidade, nada para reconciliar. Nenhuma linha foi
-- apagada nem mesclada para chegar a este estado.
--
-- O indice e PARCIAL em is_active de proposito. fc_squads nao tem delete: o
-- "arquivar" desliga is_active. Um unico total impediria a conta de ter um
-- elenco novo depois de arquivar o antigo, que e justamente um caminho
-- legitimo.
--
-- Numerado acima de 20261012100200 porque as migrations 20261012* ja
-- aplicadas estao a frente do relogio real; uma data de setembro ordenaria
-- antes delas e o `db push` recusaria.

create unique index if not exists fc_squads_one_active_per_account_idx
    on public.fc_squads (fc_account_id)
    where is_active;

comment on index public.fc_squads_one_active_per_account_idx is
    'Uma Conta = no maximo um Elenco ativo. Arquivar (is_active=false) libera a conta para um novo.';

-- ---------------------------------------------------------------------
-- create_fc_squad para de criar o segundo.
--
-- Sem isso o app receberia o erro cru de violacao de indice unico, que nao
-- diz nada a quem esta olhando a tela. Aqui a intencao vira explicita: se a
-- conta ja tem elenco, devolve O ELENCO EXISTENTE em vez de falhar. E o que
-- a UI quer -- "montar elenco" numa conta que ja tem elenco e, na pratica,
-- "editar aquele".
--
-- Mesma assinatura: "create or replace" com lista de parametros diferente
-- criaria sobrecarga em vez de substituir.
-- ---------------------------------------------------------------------
create or replace function public.create_fc_squad(
    p_fc_account_id uuid,
    p_name text,
    p_formation_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_name text := btrim(coalesce(p_name, ''));
    v_squad_id uuid;
    v_existing uuid;
begin
    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id
          and user_id = (select auth.uid())
          and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    -- Idempotente: a conta ja tem elenco, entao este e o elenco dela.
    select id into v_existing
    from public.fc_squads
    where fc_account_id = p_fc_account_id and is_active
    limit 1;

    if v_existing is not null then
        return public.get_fc_squad_builder(v_existing);
    end if;

    if char_length(v_name) < 1 or char_length(v_name) > 40 then
        raise exception 'invalid squad name' using errcode = 'FQ030';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    -- Elenco unico da conta: sempre o default, porque nao ha com quem
    -- disputar esse papel.
    insert into public.fc_squads
        (fc_account_id, name, formation_code, is_default)
    values (p_fc_account_id, v_name, p_formation_code, true)
    returning id into v_squad_id;

    return public.get_fc_squad_builder(v_squad_id);
end;
$$;

comment on function public.create_fc_squad(uuid, text, text) is
    'Cria o Elenco da Conta. Idempotente: se a conta ja tem um, devolve o existente.';

revoke execute on function public.create_fc_squad(uuid, text, text)
    from public, anon;
grant execute on function public.create_fc_squad(uuid, text, text)
    to authenticated;
