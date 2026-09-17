-- Cria o squad sem pedir nome nem formação: com um squad por usuário (já
-- garantido por fc_squads_one_default_per_account), nomear a escalação não
-- diz nada -- não há uma segunda pra distinguir dela. A formação passa a ser
-- escolhida (e trocada, ao vivo) dentro do próprio builder, que já sabe
-- fazer isso (set_fc_squad_formation).
--
-- A coluna fc_squads.name continua existindo (update_fc_squad ainda sabe
-- renomear, só não há mais tela que chame isso) -- só o valor inicial passa
-- a ser um default fixo em vez de pedido ao usuário.

drop function if exists public.create_fc_squad(text, text);

create function public.create_fc_squad()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_squad_id uuid;
    v_existing uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- Idempotente: o usuario ja tem squad, entao este e o squad dele.
    select id into v_existing
    from public.fc_squads
    where user_id = v_user_id and is_active
    limit 1;

    if v_existing is not null then
        return public.get_fc_squad_builder(v_existing);
    end if;

    if not exists (
        select 1 from public.fc_formations where code = '4-4-2' and is_active
    ) then
        raise exception 'default formation is unavailable' using errcode = 'FQ031';
    end if;

    insert into public.fc_squads (user_id, name, formation_code, is_default)
    values (v_user_id, 'Escalação', '4-4-2', true)
    returning id into v_squad_id;

    return public.get_fc_squad_builder(v_squad_id);
end;
$$;

comment on function public.create_fc_squad() is
    'Cria o squad do usuario com formacao padrao 4-4-2. Idempotente: se ja existir, devolve o existente. Sem nome/formacao pedidos -- o usuario escolhe a formacao no builder.';

revoke execute on function public.create_fc_squad() from public, anon;
grant execute on function public.create_fc_squad() to authenticated;
