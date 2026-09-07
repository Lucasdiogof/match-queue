-- Times criados antes desta etapa nao tem link nenhum ainda. Gera um ativo
-- para cada um, atribuido ao OWNER do time (a pessoa mais correta para
-- "criou este link" quando ninguem pediu explicitamente).
--
-- create_team (Etapa 3) nao foi alterado para gerar o link na mesma
-- transacao -- ver decisao documentada no relatorio da Etapa 4. Times
-- novos recebem o link lazily via get_or_create_team_invite na primeira
-- vez que a tela Time abre; este backfill cobre soh quem ja existia.
do $$
declare
    v_team record;
begin
    for v_team in
        select t.id as team_id, tm.user_id as owner_id
        from public.teams t
        join public.team_members tm
            on tm.team_id = t.id and tm.role = 'OWNER'
        where not exists (
            select 1 from public.team_invite_links l
            where l.team_id = t.id and l.is_active
        )
    loop
        perform public._ensure_active_team_invite(v_team.team_id, v_team.owner_id);
    end loop;
end;
$$;
