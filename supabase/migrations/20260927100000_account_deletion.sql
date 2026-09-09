-- Fase A (bloqueadores de lancamento), item 2: exclusao de conta real.
--
-- Duas categorias de dado ligado ao usuario, tratadas de forma diferente:
--
-- 1. Dado pessoal exclusivo (nunca compartilhado): user_fc_accounts e tudo
--    que pendura nele (fc_squads, fc_account_teams,
--    fc_account_weekend_league_progress) -- DELETADO de verdade, ja cascade
--    desde que foram criados. team_members da propria pessoa -- removido
--    (ou o time inteiro dissolvido se ela for owner solo, ver a funcao).
--
-- 2. Dado historico COMPARTILHADO com o time (game_matches,
--    match_search_sessions -- esta ultima e "historico de busca", nao so
--    estado ao vivo): jamais deletado so por causa da exclusao de uma
--    conta, porque apagaria a partida/busca da visao dos outros membros do
--    time. Em vez disso, user_id/fc_account_id viram NULL (anonimizacao) --
--    por isso as 3 FKs abaixo trocam de RESTRICT para SET NULL. Toda leitura
--    client-facing que ja existe (get_team_activity_history,
--    get_team_sports_dashboard, etc.) ja usa coalesce(display_name, '') /
--    subquery correlacionada, que ja tolera null sem quebrar -- conferido
--    antes desta migration, nenhuma mudanca de RPC de leitura foi
--    necessaria.
--
-- team_invite_links.created_by segue o mesmo raciocinio de anonimizacao:
-- e so metadado de auditoria (nunca exposto a quem resolve o convite), e
-- travar a exclusao de conta pra sempre por causa de um link de convite
-- antigo (mesmo de um time que a pessoa ja nem participa mais) nao serve a
-- ninguem.
--
-- match_search_queue e propositalmente NAO alterada aqui: e estado
-- exclusivamente AO VIVO (fila atual, nunca historico), e a RPC
-- cancel_match_search ja existente remove a linha de verdade (nunca so
-- marca status) -- chamada para cada fc_account do usuario antes de
-- qualquer outro passo, entao nunca sobra linha pra violar a FK.

alter table public.game_matches
    drop constraint game_matches_user_id_fkey,
    alter column user_id drop not null,
    add constraint game_matches_user_id_fkey
        foreign key (user_id) references public.profiles (id) on delete set null,
    drop constraint game_matches_fc_account_id_fkey,
    add constraint game_matches_fc_account_id_fkey
        foreign key (fc_account_id) references public.user_fc_accounts (id) on delete set null;

alter table public.match_search_sessions
    drop constraint match_search_sessions_user_id_fkey,
    alter column user_id drop not null,
    add constraint match_search_sessions_user_id_fkey
        foreign key (user_id) references public.profiles (id) on delete set null,
    drop constraint match_search_sessions_fc_account_id_fkey,
    add constraint match_search_sessions_fc_account_id_fkey
        foreign key (fc_account_id) references public.user_fc_accounts (id) on delete set null;

alter table public.team_invite_links
    drop constraint team_invite_links_created_by_fkey,
    alter column created_by drop not null,
    add constraint team_invite_links_created_by_fkey
        foreign key (created_by) references public.profiles (id) on delete set null;

-- FQ044: exclusao de conta bloqueada porque a pessoa e OWNER solo-required
-- de um time com outros membros (transferencia de ownership nao existe
-- ainda -- team_members_protect_owner ja proibe isso desde a Etapa 3).
-- Regra escolhida (a mais simples e segura dentre as 3 do pedido): dissolve
-- o time automaticamente SE a pessoa for a unica integrante; bloqueia com
-- erro claro se houver mais gente, para o dono decidir manualmente
-- (remover os outros membros ou aguardar suporte a transferencia).
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_fc_account_id uuid;
    v_team record;
    v_other_members integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- 1) Falha rapido, antes de mexer em qualquer dado: se a pessoa e OWNER
    -- de algum time com outros membros, a exclusao nao pode prosseguir.
    -- Como tudo aqui roda numa unica transacao implicita, um raise depois
    -- desfaria qualquer mutacao ja feita de qualquer forma -- checar antes
    -- so evita trabalho a toa.
    for v_team in
        select team_id from public.team_members
        where user_id = v_user_id and role = 'OWNER'
    loop
        select count(*) into v_other_members
        from public.team_members
        where team_id = v_team.team_id and user_id <> v_user_id;

        if v_other_members > 0 then
            raise exception
                'cannot delete account while sole owner of a team with other members'
                using errcode = 'FQ044';
        end if;
    end loop;

    -- 2) Estado AO VIVO de matchmaking: cancela busca/sai da fila de cada
    -- elenco da pessoa antes de qualquer outra coisa (promove quem esperava
    -- na fila, nunca deixa "busca fantasma"). Ignora silenciosamente quando
    -- nao ha nada pra cancelar (FQ015) -- e o caminho comum.
    for v_fc_account_id in
        select id from public.user_fc_accounts where user_id = v_user_id
    loop
        begin
            perform public.cancel_match_search(v_fc_account_id);
        exception
            when sqlstate 'FQ015' then
                null;
        end;
    end loop;

    -- 3) Anonimiza historico compartilhado com o time (nunca deleta -- ver
    -- comentario do topo do arquivo).
    update public.game_matches
        set user_id = null, fc_account_id = null
        where user_id = v_user_id;

    update public.match_search_sessions
        set user_id = null, fc_account_id = null
        where user_id = v_user_id;

    update public.team_invite_links
        set created_by = null
        where created_by = v_user_id;

    -- 4) Times: dissolve os que a pessoa possui sozinha (cascade limpa
    -- team_members/team_invite_links/game_matches/etc. daquele time -- sem
    -- problema, ninguem mais tinha acesso a esse time). Nos demais, so sai
    -- (remove a propria linha de team_members).
    for v_team in
        select team_id, role from public.team_members where user_id = v_user_id
    loop
        if v_team.role = 'OWNER' then
            -- Ja confirmado no passo 1 que e o unico membro.
            delete from public.teams where id = v_team.team_id;
        else
            delete from public.team_members
                where team_id = v_team.team_id and user_id = v_user_id;
        end if;
    end loop;

    -- 5) Dado pessoal exclusivo: deletado de verdade. Cascade cuida de
    -- fc_squads/fc_squad_slots/fc_account_teams/
    -- fc_account_weekend_league_progress.
    delete from public.user_fc_accounts where user_id = v_user_id;

    -- 6) profiles, user_devices, notification_outbox,
    -- notification_preferences, user_notifications e user_public_profiles
    -- (que aponta direto pra auth.users) tudo com ON DELETE CASCADE desde
    -- que foram criados -- a Edge Function que chama esta RPC deleta o
    -- auth.users logo em seguida via admin API (service role), o que
    -- dispara essas cascatas. Esta funcao nao tem privilegio pra apagar
    -- auth.users diretamente, de proposito -- ver docs/handoff_fase_a_launch.md.
end;
$$;

comment on function public.delete_my_account() is
    'Prepara a conta do chamador para exclusao: cancela buscas ativas, anonimiza historico compartilhado, resolve/dissolve times, deleta elencos. Nao apaga auth.users -- isso e feito pela Edge Function delete-account via admin API, depois que esta funcao retornar com sucesso. Idempotente: rodar de novo sem ter mudado nada so repete os mesmos passos sem efeito (nada mais a cancelar/anonimizar/deletar).';

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
