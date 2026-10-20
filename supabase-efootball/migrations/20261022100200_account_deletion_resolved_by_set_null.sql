-- Exclusao de conta: resolved_by (quem aprovou/recusou/aceitou um pedido ou
-- convite) referencia a tabela de usuarios sem ON DELETE, ou seja NO ACTION.
-- Quem ja tinha resolvido o pedido de outra pessoa nao conseguia excluir a
-- conta: auth.admin.deleteUser falhava na FK. A coluna e so auditoria, entao
-- passa a ficar nula quando a conta some, como game_matches.user_id e
-- team_invite_links.created_by ja fazem em delete_my_account().
--
-- Idempotente e valido nos dois esquemas: acha a FK pelo catalogo e a recria
-- apontando para a mesma tabela (public.profiles no EA FC, public.users no
-- eFootball), sem depender do nome.

do $$
declare
    v_table text;
    v_con record;
begin
    foreach v_table in array array['team_join_requests', 'team_invitations'] loop
        select c.conname, c.confrelid::regclass as target into v_con
        from pg_constraint c
        join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any (c.conkey)
        where c.contype = 'f'
          and c.conrelid = ('public.' || v_table)::regclass
          and a.attname = 'resolved_by';

        if v_con.conname is null then
            raise notice '% sem FK em resolved_by, nada a fazer', v_table;
            continue;
        end if;

        execute format('alter table public.%I drop constraint %I', v_table, v_con.conname);
        execute format(
            'alter table public.%I add constraint %I foreign key (resolved_by) references %s (id) on delete set null',
            v_table, v_table || '_resolved_by_fkey', v_con.target
        );
    end loop;
end
$$;
