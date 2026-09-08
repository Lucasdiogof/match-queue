-- Etapa 14: dashboard esportivo do Time.
--
-- DEDUPE, que e o risco central desta etapa (itens 2/70). Uma busca de uma
-- Conta pode tocar VARIOS Times (match_search_session_teams), entao qualquer
-- caminho game_matches -> search_session -> session_teams multiplicaria a
-- mesma partida. Aqui nunca se faz esse join: o vinculo com o Time e sempre
-- um EXISTS sobre fc_account_teams, que filtra sem multiplicar linha. Cada
-- game_matches.id entra no maximo uma vez em cada agregado.
--
-- ESCOPO: partida entra no Time se (a) a Conta que jogou esta vinculada ao
-- Time e (b) o usuario dono dela AINDA e membro (item 58 -- quem saiu some do
-- dashboard, sem hall historico). Conta nao vinculada nunca aparece (item 5).
--
-- LIMITACAO CONHECIDA (item 6): fc_account_teams nao guarda historico
-- temporal do vinculo -- so (fc_account_id, team_id, created_at). Entao o
-- dashboard reflete as Contas vinculadas AGORA, inclusive para partidas
-- anteriores ao vinculo. Aceito para a V1; um vinculo com validade exigiria
-- versionar a tabela e nao ha demanda concreta ainda.
--
-- FONTE: so game_matches / game_match_player_stats / user_fc_accounts / WL /
-- rivals. match_search_sessions e match_search_queue NAO entram -- eles
-- descrevem STATUS de fila, nao desempenho esportivo (item 1).

-- Minimo de partidas para o membro disputar o ranking em pe de igualdade.
-- Existe para 1 jogo / 1 vitoria / 100% nao passar na frente de quem tem 50
-- jogos. Quem esta abaixo aparece do mesmo jeito, marcado e ordenado depois
-- (itens 14/45) -- nunca escondido.
create function public._team_ranking_min_matches()
returns integer language sql immutable set search_path = '' as $$
    select 5;
$$;

revoke execute on function public._team_ranking_min_matches() from public, anon;

-- Artilharia / assistencias do Time.
--
-- Agrupado por (Conta, carta), nunca so por carta (itens 25/26): "Mbappe
-- Gold do Lucas" e "Mbappe Gold do Pedro" sao performances diferentes e
-- viram linhas diferentes. Juntar as duas apagaria de quem foi o gol.
--
-- Tambem NAO se consolidam versoes distintas da mesma pessoa (Gold vs TOTS,
-- item 22) -- a chave e a carta. fc_players existe e permitira isso depois,
-- quando houver decisao de produto sobre agrupar.
create function public._team_player_leaderboard(
    p_team_id uuid,
    p_by_assists boolean default false,
    p_limit integer default 10,
    p_offset integer default 0
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    with team_accounts as (
        select a.id as fc_account_id, a.name as account_name, a.user_id
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    agg as (
        select
            ta.fc_account_id,
            ta.account_name,
            ta.user_id,
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            (array_agg(s.player_name order by s.updated_at desc))[1] as player_name,
            (array_agg(s.player_card_id order by s.updated_at desc))[1] as player_card_id,
            sum(s.goals)::integer as goals,
            sum(s.assists)::integer as assists
        from public.game_match_player_stats as s
        join public.game_matches as m on m.id = s.game_match_id
        join team_accounts as ta on ta.fc_account_id = m.fc_account_id
        group by ta.fc_account_id, ta.account_name, ta.user_id, player_key
    )
    select coalesce(jsonb_agg(row_json order by ord), '[]'::jsonb)
    from (
        select
            row_number() over (
                order by
                    case when p_by_assists then a.assists else a.goals end desc,
                    case when p_by_assists then a.goals else a.assists end desc,
                    a.player_name asc
            ) as ord,
            jsonb_build_object(
                'player_key', a.player_key,
                'player_card_id', a.player_card_id,
                'player_name', a.player_name,
                'goals', a.goals,
                'assists', a.assists,
                'user_id', a.user_id,
                'display_name', coalesce(p.display_name, ''),
                'fc_account_id', a.fc_account_id,
                'account_name', a.account_name
            ) as row_json
        from agg as a
        left join public.profiles as p on p.id = a.user_id
        where (case when p_by_assists then a.assists else a.goals end) > 0
        order by
            case when p_by_assists then a.assists else a.goals end desc,
            case when p_by_assists then a.goals else a.assists end desc,
            a.player_name asc
        limit greatest(1, least(coalesce(p_limit, 10), 100))
        offset greatest(0, coalesce(p_offset, 0))
    ) as page;
$$;

revoke execute on function
    public._team_player_leaderboard(uuid, boolean, integer, integer)
    from public, anon, authenticated;

-- Lista completa, para o "Ver artilharia"/"Ver assistencias" (itens 42/43).
create function public.get_team_player_leaderboard(
    p_team_id uuid,
    p_by_assists boolean default false,
    p_limit integer default 50,
    p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    return public._team_player_leaderboard(
        p_team_id, p_by_assists, p_limit, p_offset);
end;
$$;

revoke execute on function
    public.get_team_player_leaderboard(uuid, boolean, integer, integer)
    from public, anon;
grant execute on function
    public.get_team_player_leaderboard(uuid, boolean, integer, integer)
    to authenticated;

-- Resumo + ranking + artilharia + assistencias + WL + Rivals + atividade numa
-- chamada so (item 40): a alternativa seriam 6 requests para a mesma tela, ou
-- pior, N membros x M consultas.
create function public.get_team_sports_dashboard(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_current_event uuid;
    v_result jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- So membro le o dashboard (item 36). Dono do Time nao tem privilegio
    -- nenhum aqui: administrar o Time nao da direito de editar stat alheia,
    -- e leitura e igual para todos os membros (item 37).
    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    select id into v_current_event
    from public.weekend_league_events
    where is_active and now() between starts_at and ends_at
    order by starts_at desc
    limit 1;

    with team_accounts as (
        select a.id as fc_account_id, a.name as account_name, a.user_id,
               a.rivals_division
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    -- Uma linha por partida. EXISTS, nunca join com session_teams.
    team_matches as (
        select m.id, m.user_id, m.fc_account_id, m.game_mode, m.status,
               m.result, m.goals_for, m.goals_against, m.ended_at,
               m.weekend_league_event_id, m.squad_snapshot
        from public.game_matches as m
        where exists (
            select 1 from team_accounts as ta
            where ta.fc_account_id = m.fc_account_id
        )
    ),
    finished as (
        select * from team_matches where status = 'FINISHED' and result is not null
    ),
    -- Gols/assistencias individuais contam mesmo sem placar registrado
    -- (item 69): sao registros proprios, nao derivados do placar.
    player_rows as (
        select
            s.game_match_id,
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            s.player_name, s.goals, s.assists, s.updated_at,
            tm.fc_account_id, tm.user_id
        from public.game_match_player_stats as s
        join team_matches as tm on tm.id = s.game_match_id
    ),
    per_user as (
        select
            ta.user_id,
            count(distinct ta.fc_account_id) as accounts_count,
            count(distinct f.id) as matches,
            count(distinct f.id) filter (where f.result = 'WIN') as wins,
            count(distinct f.id) filter (where f.result = 'LOSS') as losses,
            coalesce(sum(f.goals_for), 0) as goals_for,
            coalesce(sum(f.goals_against), 0) as goals_against
        from team_accounts as ta
        left join finished as f on f.fc_account_id = ta.fc_account_id
        group by ta.user_id
    ),
    per_user_players as (
        select user_id,
               coalesce(sum(goals), 0) as goals,
               coalesce(sum(assists), 0) as assists
        from player_rows group by user_id
    )
    select jsonb_build_object(
        'team_id', p_team_id,
        'server_now', to_jsonb(now()),
        'min_ranked_matches', public._team_ranking_min_matches(),
        'summary', (
            select jsonb_build_object(
                'members_count', (
                    select count(*) from public.team_members where team_id = p_team_id
                ),
                'accounts_count', (select count(*) from team_accounts),
                'matches', (select count(*) from finished),
                'wins', (select count(*) from finished where result = 'WIN'),
                'losses', (select count(*) from finished where result = 'LOSS'),
                'win_rate', (
                    select case when count(*) = 0 then null
                        else round(count(*) filter (where result = 'WIN')::numeric
                                   / count(*), 4) end
                    from finished
                ),
                -- Placar so soma onde existe: WIN/LOSS sem placar conta no
                -- record e nao fabrica gol (itens 67/68).
                'goals_for', (select coalesce(sum(goals_for), 0) from finished),
                'goals_against', (select coalesce(sum(goals_against), 0) from finished),
                'goal_difference', (
                    select coalesce(sum(goals_for), 0) - coalesce(sum(goals_against), 0)
                    from finished
                ),
                -- Artilharia individual e outro numero, de outra fonte: nao
                -- precisa bater com goals_for (item 8).
                'registered_player_goals', (select coalesce(sum(goals), 0) from player_rows),
                'registered_assists', (select coalesce(sum(assists), 0) from player_rows)
            )
        ),
        'ranking', (
            select coalesce(jsonb_agg(row_json order by ord), '[]'::jsonb)
            from (
                select
                    row_number() over (
                        order by
                            (pu.matches >= public._team_ranking_min_matches()) desc,
                            case when pu.matches = 0 then null
                                 else pu.wins::numeric / pu.matches end desc nulls last,
                            pu.wins desc,
                            pu.matches desc,
                            coalesce(p.display_name, '') asc
                    ) as ord,
                    jsonb_build_object(
                        'user_id', pu.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'avatar_url', p.avatar_url,
                        'accounts_count', pu.accounts_count,
                        'matches', pu.matches,
                        'wins', pu.wins,
                        'losses', pu.losses,
                        'win_rate', case when pu.matches = 0 then null
                            else round(pu.wins::numeric / pu.matches, 4) end,
                        'goals_for', pu.goals_for,
                        'goals_against', pu.goals_against,
                        'player_goals', coalesce(pup.goals, 0),
                        'player_assists', coalesce(pup.assists, 0),
                        'is_ranked', pu.matches >= public._team_ranking_min_matches()
                    ) as row_json
                from per_user as pu
                left join public.profiles as p on p.id = pu.user_id
                left join per_user_players as pup on pup.user_id = pu.user_id
            ) as ranked
        ),
        'top_scorers', public._team_player_leaderboard(p_team_id, false, 10, 0),
        'top_assists', public._team_player_leaderboard(p_team_id, true, 10, 0),
        'weekend_league', (
            select coalesce(jsonb_agg(row_json order by wins desc, losses asc, account_name asc), '[]'::jsonb)
            from (
                select
                    ta.account_name,
                    coalesce(wl.manual_wins,
                        (select count(*) from finished f
                         where f.fc_account_id = ta.fc_account_id
                           and f.game_mode = 'WEEKEND_LEAGUE'
                           and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                           and f.result = 'WIN')) as wins,
                    coalesce(wl.manual_losses,
                        (select count(*) from finished f
                         where f.fc_account_id = ta.fc_account_id
                           and f.game_mode = 'WEEKEND_LEAGUE'
                           and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                           and f.result = 'LOSS')) as losses,
                    jsonb_build_object(
                        'user_id', ta.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'fc_account_id', ta.fc_account_id,
                        'account_name', ta.account_name,
                        'event_id', v_current_event,
                        -- Record manual manda na exibicao de W/L, mas nunca
                        -- fabrica gol/assistencia (item 28).
                        'is_manual', wl.manual_wins is not null,
                        'wins', coalesce(wl.manual_wins,
                            (select count(*) from finished f
                             where f.fc_account_id = ta.fc_account_id
                               and f.game_mode = 'WEEKEND_LEAGUE'
                               and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                               and f.result = 'WIN')),
                        'losses', coalesce(wl.manual_losses,
                            (select count(*) from finished f
                             where f.fc_account_id = ta.fc_account_id
                               and f.game_mode = 'WEEKEND_LEAGUE'
                               and f.weekend_league_event_id = coalesce(v_current_event, f.weekend_league_event_id)
                               and f.result = 'LOSS'))
                    ) as row_json
                from team_accounts as ta
                left join public.profiles as p on p.id = ta.user_id
                left join public.fc_account_weekend_league_progress as wl
                    on wl.fc_account_id = ta.fc_account_id
                   and wl.weekend_league_event_id = v_current_event
            ) as wlrows
        ),
        'rivals', (
            select coalesce(jsonb_agg(row_json order by matches desc, account_name asc), '[]'::jsonb)
            from (
                select
                    ta.account_name,
                    (select count(*) from finished f
                     where f.fc_account_id = ta.fc_account_id
                       and f.game_mode = 'DIVISION_RIVALS') as matches,
                    jsonb_build_object(
                        'user_id', ta.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'fc_account_id', ta.fc_account_id,
                        'account_name', ta.account_name,
                        'division', ta.rivals_division,
                        'matches', (select count(*) from finished f
                            where f.fc_account_id = ta.fc_account_id
                              and f.game_mode = 'DIVISION_RIVALS'),
                        'wins', (select count(*) from finished f
                            where f.fc_account_id = ta.fc_account_id
                              and f.game_mode = 'DIVISION_RIVALS' and f.result = 'WIN'),
                        'losses', (select count(*) from finished f
                            where f.fc_account_id = ta.fc_account_id
                              and f.game_mode = 'DIVISION_RIVALS' and f.result = 'LOSS'),
                        'win_rate', (
                            select case when count(*) = 0 then null
                                else round(count(*) filter (where f.result = 'WIN')::numeric
                                           / count(*), 4) end
                            from finished f
                            where f.fc_account_id = ta.fc_account_id
                              and f.game_mode = 'DIVISION_RIVALS')
                    ) as row_json
                from team_accounts as ta
                left join public.profiles as p on p.id = ta.user_id
            ) as rrows
        ),
        -- Atividade derivada dos registros que ja existem (item 34): nenhuma
        -- tabela de eventos nova. So esportivo -- nada de "entrou na fila".
        'activity', (
            select coalesce(jsonb_agg(row_json order by ended_at desc), '[]'::jsonb)
            from (
                select
                    f.ended_at,
                    jsonb_build_object(
                        'type', 'MATCH_RESULT',
                        'occurred_at', to_jsonb(f.ended_at),
                        'user_id', f.user_id,
                        'display_name', coalesce(p.display_name, ''),
                        'avatar_url', p.avatar_url,
                        'fc_account_id', f.fc_account_id,
                        'account_name', ta.account_name,
                        'game_mode', f.game_mode,
                        'result', f.result,
                        'goals_for', f.goals_for,
                        'goals_against', f.goals_against,
                        'top_scorer', (
                            select jsonb_build_object(
                                'player_name', pr.player_name, 'goals', pr.goals)
                            from player_rows pr
                            where pr.game_match_id = f.id and pr.goals > 0
                            order by pr.goals desc, pr.player_name asc
                            limit 1
                        )
                    ) as row_json
                from finished as f
                join team_accounts as ta on ta.fc_account_id = f.fc_account_id
                left join public.profiles as p on p.id = f.user_id
                where f.ended_at is not null
                order by f.ended_at desc
                limit 20
            ) as act
        )
    ) into v_result;

    return v_result;
end;
$$;

revoke execute on function public.get_team_sports_dashboard(uuid) from public, anon;
grant execute on function public.get_team_sports_dashboard(uuid) to authenticated;
