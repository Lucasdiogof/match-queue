-- Etapa 12: detalhamento de partida em 3 niveis (rapido/normal/completo),
-- todos opcionais, nunca bloqueando o fluxo. Continua o namespace FQ00x:
--   FQ036 payload de estatisticas invalido
--   FQ037 jogador nao pertence ao squad_snapshot desta partida
--   FQ038 partida sem squad_snapshot (nao da para detalhar por jogador)
--   FQ039 partida ainda nao finalizada (nao da para editar resultado)
--
-- Modelo agregado, nao evento-a-evento (item de decisao do dono do produto):
-- sem minuto do gol, sem chutes/posse/cartoes/xG. Gols/assistencias por
-- jogador SAO INDEPENDENTES do placar da partida -- nunca exigir que a soma
-- bata, o usuario pode preencher so uma parte.

create table public.game_match_player_stats (
    id uuid primary key default gen_random_uuid(),
    game_match_id uuid not null
        references public.game_matches (id) on delete cascade,
    -- Chave do jogador DENTRO do squad_snapshot congelado da partida. Hoje
    -- e sempre o card_id daquele momento (unico por squad, garantido por
    -- fc_squad_slots_unique_card_per_squad) -- guardado como texto porque o
    -- snapshot e jsonb e a chave pode, em tese, sobreviver a um card_id que
    -- deixou de existir no catalogo.
    snapshot_player_key text not null,
    -- Pode sumir se o catalogo for reimportado; nunca obrigatorio para ler
    -- o nome (player_name ja veio do snapshot no momento do upsert).
    player_card_id uuid,
    player_name text not null,
    position text,
    rating integer,
    goals integer not null default 0,
    assists integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    unique (game_match_id, snapshot_player_key),
    constraint game_match_player_stats_goals_range
        check (goals >= 0 and goals <= 99),
    constraint game_match_player_stats_assists_range
        check (assists >= 0 and assists <= 99)
);

comment on table public.game_match_player_stats is
    'Gols/assistencias agregados por jogador de uma partida, derivados do squad_snapshot congelado. Nunca confiar em nome/posicao vindo do client.';

create index game_match_player_stats_match_idx
    on public.game_match_player_stats (game_match_id);
create index game_match_player_stats_card_idx
    on public.game_match_player_stats (player_card_id)
    where player_card_id is not null;

create trigger game_match_player_stats_set_updated_at
    before update on public.game_match_player_stats
    for each row
    execute function public.set_updated_at();

alter table public.game_match_player_stats enable row level security;
revoke all on table public.game_match_player_stats
    from anon, authenticated, public;

-- Indice composto para os agregados por conta/modo/evento desta etapa
-- (get_fc_account_stats / get_weekend_league_account_stats /
-- get_rivals_account_stats fazem exatamente este filtro).
create index game_matches_fc_account_mode_status_idx
    on public.game_matches (fc_account_id, game_mode, status)
    where fc_account_id is not null;

-- ---------------------------------------------------------------------
-- Resultado editavel depois de finalizado, sem janela de tempo.
-- ---------------------------------------------------------------------
create function public.update_game_match_result(
    p_game_match_id uuid,
    p_result text default null,
    p_goals_for integer default null,
    p_goals_against integer default null
)
returns public.game_matches
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_result text;
    v_gf integer := p_goals_for;
    v_ga integer := p_goals_against;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_game_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;
    -- So faz sentido editar um resultado que ja existe. IN_MATCH usa
    -- finish_game_match; ABANDONED/EXPIRED nunca tiveram resultado.
    if v_match.status <> 'FINISHED' then
        raise exception 'only a finished match result can be edited'
            using errcode = 'FQ039';
    end if;

    if v_gf is not null or v_ga is not null then
        if v_gf is null or v_ga is null or v_gf < 0 or v_ga < 0 then
            raise exception 'invalid score' using errcode = 'FQ024';
        end if;
        if v_gf = v_ga then
            raise exception 'a draw is not a valid final result'
                using errcode = 'FQ024';
        end if;
        v_result := case when v_gf > v_ga then 'WIN' else 'LOSS' end;
    elsif p_result in ('WIN', 'LOSS') then
        v_result := p_result;
    else
        raise exception 'a result or a score is required' using errcode = 'FQ024';
    end if;

    update public.game_matches
    set result = v_result,
        goals_for = v_gf,
        goals_against = v_ga
    where id = v_match.id
    returning * into v_match;

    return v_match;
end;
$$;

comment on function public.update_game_match_result(uuid, text, integer, integer) is
    'Edita resultado/placar de uma partida ja FINISHED, sem limite de tempo. So o dono.';

revoke execute on function public.update_game_match_result(uuid, text, integer, integer)
    from public, anon;
grant execute on function public.update_game_match_result(uuid, text, integer, integer)
    to authenticated;

-- ---------------------------------------------------------------------
-- Upsert atomico de gols/assistencias por jogador. O client manda so
-- {snapshot_player_key, goals, assists} -- nome/posicao/rating vem do
-- snapshot congelado, nunca do payload (item de seguranca mais enfatizado
-- pelo dono do produto).
-- ---------------------------------------------------------------------
create function public.upsert_game_match_player_stats(
    p_game_match_id uuid,
    p_stats jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_item jsonb;
    v_key text;
    v_goals integer;
    v_assists integer;
    v_player jsonb;
    v_saved integer := 0;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_game_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;

    if v_match.squad_snapshot is null then
        raise exception 'this match has no squad snapshot to detail'
            using errcode = 'FQ038';
    end if;

    if p_stats is null or jsonb_typeof(p_stats) <> 'array' then
        raise exception 'invalid stats payload' using errcode = 'FQ036';
    end if;

    -- Substituicao total: o Flutter sempre manda a lista inteira do
    -- squad_snapshot (titulares + banco), zerada onde nao houve gol/
    -- assistencia. Linha zerada nao precisa ser mantida.
    delete from public.game_match_player_stats
    where game_match_id = p_game_match_id;

    for v_item in select * from jsonb_array_elements(p_stats) loop
        v_key := v_item ->> 'snapshot_player_key';
        v_goals := coalesce((v_item ->> 'goals')::integer, 0);
        v_assists := coalesce((v_item ->> 'assists')::integer, 0);

        if v_key is null
            or v_goals < 0 or v_goals > 99
            or v_assists < 0 or v_assists > 99
        then
            raise exception 'invalid player stats entry' using errcode = 'FQ036';
        end if;

        -- A validacao que mais importa: o jogador precisa existir DENTRO
        -- do snapshot desta partida especifica (titular ou banco, ambos
        -- elegiveis). Nunca aceitar nome/posicao arbitrarios do client.
        select p into v_player
        from jsonb_array_elements(v_match.squad_snapshot -> 'players') as p
        where p ->> 'card_id' = v_key;

        if v_player is null then
            raise exception 'player is not part of this match squad'
                using errcode = 'FQ037';
        end if;

        if v_goals = 0 and v_assists = 0 then
            continue;
        end if;

        insert into public.game_match_player_stats
            (game_match_id, snapshot_player_key, player_card_id,
             player_name, position, rating, goals, assists)
        values (
            p_game_match_id,
            v_key,
            nullif(v_player ->> 'card_id', '')::uuid,
            coalesce(v_player ->> 'player_name', ''),
            v_player ->> 'position',
            nullif(v_player ->> 'rating', '')::integer,
            v_goals,
            v_assists
        );
        v_saved := v_saved + 1;
    end loop;

    return jsonb_build_object('saved_count', v_saved);
end;
$$;

comment on function public.upsert_game_match_player_stats(uuid, jsonb) is
    'Substitui os gols/assistencias por jogador de uma partida. Valida cada item contra o squad_snapshot congelado; deriva nome/posicao/rating server-side.';

revoke execute on function public.upsert_game_match_player_stats(uuid, jsonb)
    from public, anon;
grant execute on function public.upsert_game_match_player_stats(uuid, jsonb)
    to authenticated;

-- ---------------------------------------------------------------------
-- Detalhe de uma partida numa unica chamada (evita N+1 no Historico).
-- Leitura: dono ou membro do mesmo time (nunca escreve).
-- ---------------------------------------------------------------------
create function public.get_game_match_details(p_game_match_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_account public.user_fc_accounts;
    v_stats jsonb;
    v_is_owner boolean;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match from public.game_matches where id = p_game_match_id;
    if v_match.id is null then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;

    v_is_owner := v_match.user_id = v_user_id;
    if not v_is_owner and not public.is_team_member(v_match.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if v_match.fc_account_id is not null then
        select * into v_account
        from public.user_fc_accounts
        where id = v_match.fc_account_id;
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'snapshot_player_key', snapshot_player_key,
            'player_card_id', player_card_id,
            'player_name', player_name,
            'position', position,
            'rating', rating,
            'goals', goals,
            'assists', assists
        ) order by goals desc, assists desc, player_name asc
    ), '[]'::jsonb)
    into v_stats
    from public.game_match_player_stats
    where game_match_id = p_game_match_id;

    return jsonb_build_object(
        'match', jsonb_build_object(
            'id', v_match.id,
            'team_id', v_match.team_id,
            'game_mode', v_match.game_mode,
            'status', v_match.status,
            'result', v_match.result,
            'goals_for', v_match.goals_for,
            'goals_against', v_match.goals_against,
            'started_at', to_jsonb(v_match.started_at),
            'ended_at', to_jsonb(v_match.ended_at),
            'weekend_league_event_id', v_match.weekend_league_event_id,
            'fc_account_id', v_match.fc_account_id,
            'fc_account_name', v_account.name,
            'fc_squad_id', v_match.fc_squad_id,
            'squad_snapshot', v_match.squad_snapshot
        ),
        'player_stats', v_stats,
        'is_owner', v_is_owner
    );
end;
$$;

comment on function public.get_game_match_details(uuid) is
    'Partida + conta + squad_snapshot + player stats numa unica chamada. Dono ou membro do mesmo time pode ler.';

revoke execute on function public.get_game_match_details(uuid) from public, anon;
grant execute on function public.get_game_match_details(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Helpers internos de agregacao, reaproveitados por get_fc_account_stats,
-- get_weekend_league_account_stats, get_rivals_account_stats e pelo resumo
-- esportivo do get_team_member_profile. Sempre filtram por fc_account_id
-- direto em game_matches (que tem team_id singular por partida) -- nunca
-- fazem join com match_search_session_teams/queue_teams, entao nao ha risco
-- de duplicar por causa do matchmaking multi-time.
-- ---------------------------------------------------------------------
create function public._fc_account_match_aggregate(
    p_fc_account_id uuid,
    p_game_mode text default null,
    p_event_id uuid default null
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'matches_count', count(*) filter (where status = 'FINISHED'),
        'wins', count(*) filter (where status = 'FINISHED' and result = 'WIN'),
        'losses', count(*) filter (where status = 'FINISHED' and result = 'LOSS'),
        'goals_for', coalesce(sum(goals_for) filter (where status = 'FINISHED'), 0),
        'goals_against', coalesce(sum(goals_against) filter (where status = 'FINISHED'), 0),
        'goal_diff', coalesce(sum(goals_for) filter (where status = 'FINISHED'), 0)
            - coalesce(sum(goals_against) filter (where status = 'FINISHED'), 0)
    )
    from public.game_matches
    where fc_account_id = p_fc_account_id
      and (p_game_mode is null or game_mode = p_game_mode)
      and (p_event_id is null or weekend_league_event_id = p_event_id);
$$;

revoke execute on function public._fc_account_match_aggregate(uuid, text, uuid)
    from public, anon, authenticated;

create function public._fc_account_player_leaderboard(
    p_fc_account_id uuid,
    p_game_mode text default null,
    p_event_id uuid default null,
    p_by_assists boolean default false,
    p_limit integer default 10
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    with agg as (
        select
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            (array_agg(s.player_name order by s.updated_at desc))[1] as player_name,
            sum(s.goals)::integer as goals,
            sum(s.assists)::integer as assists
        from public.game_match_player_stats as s
        join public.game_matches as m on m.id = s.game_match_id
        where m.fc_account_id = p_fc_account_id
          and (p_game_mode is null or m.game_mode = p_game_mode)
          and (p_event_id is null or m.weekend_league_event_id = p_event_id)
        group by player_key
    ),
    ranked as (
        select * from agg
        order by
            case when p_by_assists then assists else goals end desc,
            case when p_by_assists then goals else assists end desc,
            player_name asc
        limit p_limit
    )
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'player_key', player_key,
            'player_name', player_name,
            'goals', goals,
            'assists', assists
        ) order by
            case when p_by_assists then assists else goals end desc,
            case when p_by_assists then goals else assists end desc,
            player_name asc
    ), '[]'::jsonb)
    from ranked;
$$;

revoke execute on function public._fc_account_player_leaderboard(uuid, text, uuid, boolean, integer)
    from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Estatisticas gerais da conta (todos os modos).
-- ---------------------------------------------------------------------
create function public.get_fc_account_stats(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
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
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return public._fc_account_match_aggregate(p_fc_account_id, null, null);
end;
$$;

comment on function public.get_fc_account_stats(uuid) is
    'Partidas registradas/W/L/gols pro-contra-saldo da conta, todos os modos.';

revoke execute on function public.get_fc_account_stats(uuid) from public, anon;
grant execute on function public.get_fc_account_stats(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Weekend League: record computado (das partidas reais) + manual (ja
-- existia) SEMPRE separados, nunca somados nem inventados; artilharia e
-- assistencias vindas de game_match_player_stats.
-- ---------------------------------------------------------------------
create function public.get_weekend_league_account_stats(
    p_fc_account_id uuid,
    p_weekend_league_event_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_manual public.fc_account_weekend_league_progress;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    select * into v_manual
    from public.fc_account_weekend_league_progress
    where fc_account_id = p_fc_account_id
      and weekend_league_event_id = p_weekend_league_event_id;

    return jsonb_build_object(
        'computed', public._fc_account_match_aggregate(
            p_fc_account_id, 'WEEKEND_LEAGUE', p_weekend_league_event_id
        ),
        'manual', case when v_manual.manual_wins is null then null
            else jsonb_build_object('wins', v_manual.manual_wins, 'losses', v_manual.manual_losses)
        end,
        'top_scorers', public._fc_account_player_leaderboard(
            p_fc_account_id, 'WEEKEND_LEAGUE', p_weekend_league_event_id, false, 10
        ),
        'top_assists', public._fc_account_player_leaderboard(
            p_fc_account_id, 'WEEKEND_LEAGUE', p_weekend_league_event_id, true, 10
        )
    );
end;
$$;

comment on function public.get_weekend_league_account_stats(uuid, uuid) is
    'Record computado x manual (nunca somados), artilharia e assistencias de WL de uma conta num evento.';

revoke execute on function public.get_weekend_league_account_stats(uuid, uuid)
    from public, anon;
grant execute on function public.get_weekend_league_account_stats(uuid, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- Division Rivals: sem season/semana modelada ainda (simplificacao
-- consciente desta etapa) -- e sempre "all-time" por conta.
-- ---------------------------------------------------------------------
create function public.get_rivals_account_stats(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
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
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return jsonb_build_object(
        'aggregate', public._fc_account_match_aggregate(p_fc_account_id, 'DIVISION_RIVALS', null),
        'top_scorers', public._fc_account_player_leaderboard(
            p_fc_account_id, 'DIVISION_RIVALS', null, false, 10
        ),
        'top_assists', public._fc_account_player_leaderboard(
            p_fc_account_id, 'DIVISION_RIVALS', null, true, 10
        )
    );
end;
$$;

comment on function public.get_rivals_account_stats(uuid) is
    'Partidas/record/gols/assistencias de Division Rivals de uma conta. All-time (sem season/semana modelada ainda).';

revoke execute on function public.get_rivals_account_stats(uuid) from public, anon;
grant execute on function public.get_rivals_account_stats(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_team_member_profile ganha um resumo esportivo (nunca timeline/busca).
-- Mesma assinatura, so o corpo muda.
-- ---------------------------------------------------------------------
create or replace function public.get_team_member_profile(
    p_team_id uuid,
    p_user_id uuid,
    p_fc_account_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_caller uuid := (select auth.uid());
    v_display_name text;
    v_avatar_url text;
    v_candidates jsonb;
    v_account public.user_fc_accounts;
    v_squad public.fc_squads;
    v_wl jsonb;
    v_sport_summary jsonb;
begin
    if v_caller is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if not exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = p_user_id
    ) then
        raise exception 'target is not a member of this team'
            using errcode = 'FQ012';
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.profiles
    where id = p_user_id;

    select coalesce(jsonb_agg(
        jsonb_build_object('id', a.id, 'name', a.name)
        order by a.name
    ), '[]'::jsonb)
    into v_candidates
    from public.user_fc_accounts as a
    join public.fc_account_teams as t on t.fc_account_id = a.id
    where a.user_id = p_user_id and t.team_id = p_team_id and a.is_active;

    if p_fc_account_id is not null then
        select a.* into v_account
        from public.user_fc_accounts as a
        join public.fc_account_teams as t on t.fc_account_id = a.id
        where a.id = p_fc_account_id
          and a.user_id = p_user_id
          and t.team_id = p_team_id;

        if v_account.id is null then
            raise exception 'fc account not found' using errcode = 'FQ025';
        end if;
    elsif jsonb_array_length(v_candidates) = 1 then
        select a.* into v_account
        from public.user_fc_accounts as a
        where a.id = (v_candidates -> 0 ->> 'id')::uuid;
    end if;

    if v_account.id is not null then
        select s.* into v_squad
        from public.fc_squads as s
        where s.fc_account_id = v_account.id and s.is_default and s.is_active;

        with recent_events as (
            select e.*
            from public.weekend_league_events as e
            where exists (
                select 1 from public.game_matches as gm
                where gm.fc_account_id = v_account.id
                  and gm.weekend_league_event_id = e.id
            ) or exists (
                select 1 from public.fc_account_weekend_league_progress as p
                where p.fc_account_id = v_account.id
                  and p.weekend_league_event_id = e.id
            )
            order by e.starts_at desc
            limit 10
        )
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'event_id', re.id,
                'number', re.number,
                'season', re.season,
                'starts_at', to_jsonb(re.starts_at),
                'wins', coalesce(m.manual_wins, g.wins, 0),
                'losses', coalesce(m.manual_losses, g.losses, 0)
            ) order by re.starts_at desc
        ), '[]'::jsonb)
        into v_wl
        from recent_events as re
        left join lateral (
            select
                count(*) filter (where result = 'WIN') as wins,
                count(*) filter (where result = 'LOSS') as losses
            from public.game_matches
            where fc_account_id = v_account.id
              and weekend_league_event_id = re.id
              and status = 'FINISHED'
        ) as g on true
        left join public.fc_account_weekend_league_progress as m
            on m.fc_account_id = v_account.id and m.weekend_league_event_id = re.id;

        -- Resumo esportivo: WL da campanha atual, Rivals all-time e ate 3
        -- lideres de gols/assistencias da conta. Nunca timeline/busca.
        v_sport_summary := jsonb_build_object(
            'rivals', public._fc_account_match_aggregate(v_account.id, 'DIVISION_RIVALS', null),
            'top_scorers', public._fc_account_player_leaderboard(v_account.id, null, null, false, 3),
            'top_assists', public._fc_account_player_leaderboard(v_account.id, null, null, true, 3)
        );
    end if;

    return jsonb_build_object(
        'user_id', p_user_id,
        'display_name', coalesce(v_display_name, ''),
        'avatar_url', v_avatar_url,
        'candidate_accounts', v_candidates,
        'needs_account_selection',
            p_fc_account_id is null and jsonb_array_length(v_candidates) > 1,
        'account', case when v_account.id is null then null else jsonb_build_object(
            'id', v_account.id,
            'name', v_account.name,
            'rivals_division', v_account.rivals_division
        ) end,
        'squad', case when v_squad.id is null then null else jsonb_build_object(
            'id', v_squad.id,
            'name', v_squad.name,
            'formation_code', v_squad.formation_code,
            'starting_count', (
                select count(*) from public.fc_squad_slots
                where squad_id = v_squad.id and slot_type = 'STARTING'
            ),
            'starting_total', (
                select count(*) from public.fc_formation_slots
                where formation_code = v_squad.formation_code
            )
        ) end,
        'weekend_league_history', coalesce(v_wl, '[]'::jsonb),
        'sport_summary', v_sport_summary
    );
end;
$$;

comment on function public.get_team_member_profile(uuid, uuid, uuid) is
    'Perfil publico de um membro do time: conta vinculada aquele time, divisao de Rivals, historico de WL, resumo do squad principal e resumo esportivo (WL/Rivals/lideres). So membros do mesmo time podem chamar.';

revoke execute on function public.get_team_member_profile(uuid, uuid, uuid)
    from public, anon;
grant execute on function public.get_team_member_profile(uuid, uuid, uuid)
    to authenticated;
