-- Remove por completo o conceito de resultado/placar por partida e o fluxo
-- de "partida pendente de resultado". Decisao do dono do produto: achar ou
-- cancelar uma busca nunca mais pede nada em seguida -- quem quiser registrar
-- vitoria/derrota entra em Rivals ou Champions e usa o contador manual que
-- ja existe la (fc_account_rivals_progress / fc_account_weekend_league_progress).
--
-- Isso encerra tres fluxos que dependiam de game_matches.result/goals_for/
-- goals_against ou de game_match_player_stats:
--   1. Tela de detalhe de partida (match details / editar resultado / gols e
--      assistencias por jogador) -- ja saiu do Flutter.
--   2. Fluxo de "partida pendente" (finalizar com placar, descartar, lista de
--      pendencias, cron de expiracao) -- ja saiu do Flutter.
--   3. Dashboard esportivo do Time (leaderboard de artilharia/assistencias,
--      notificacao de "novo artilheiro") -- nunca foi conectado a nenhuma
--      tela, 100% morto.
--
-- O que continua: os contadores manuais de Rivals/Champions (unica fonte de
-- vitorias/derrotas desde 20261013100000), a divisao de Rivals, e o historico
-- de buscas (achou/cancelou/expirou) no Historico.

-- ---------------------------------------------------------------------
-- 0. Idempotencia: derruba TODA sobrecarga das funcoes que esta migration
--    recria, por NOME, antes de qualquer create.
--
--    Por que por nome e nao por assinatura: o historico deste schema tem
--    varios `create or replace` que mudaram a lista de parametros -- o que
--    nao substitui, cria sobrecarga. Um `drop function if exists` com
--    assinatura fixa erra silenciosamente quando o banco real diverge, e o
--    `create` seguinte estoura com "already exists with same argument
--    types". Dropar por nome nao tem esse ponto cego, e deixa a migration
--    re-executavel (o SQL Editor do Supabase nao envolve o script numa
--    transacao, entao uma falha no meio deixa a primeira metade aplicada).
-- ---------------------------------------------------------------------
do $guard$
declare
    v_fn record;
begin
    for v_fn in
        select p.oid::regprocedure as sig
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname in (
              'get_weekend_league_account_stats',
              'get_rivals_account_stats',
              'list_my_fc_accounts',
              'get_team_member_profile',
              'get_public_team',
              '_dispatch_finished_weekend_league_notifications',
              'get_team_activity_history',
              'get_team_match_search_history'
          )
    loop
        execute 'drop function if exists ' || v_fn.sig || ' cascade';
    end loop;
end;
$guard$;

-- ---------------------------------------------------------------------
-- 1. Cron: sem mais "partida pendente", nada pra expirar lazily.
-- ---------------------------------------------------------------------
-- Idempotente de proposito: cron.unschedule() levanta erro quando o job nao
-- existe, e ele pode ja ter sido removido a mao (ou o pg_cron nem estar
-- instalado neste ambiente). Uma migration nao pode depender disso.
do $cron$
begin
    if exists (select 1 from cron.job where jobname = 'game-match-expire') then
        perform cron.unschedule('game-match-expire');
    end if;
exception
    when undefined_table or invalid_schema_name or undefined_function then
        null;
end;
$cron$;

-- ---------------------------------------------------------------------
-- 2. Fluxo de partida pendente (tela + RPCs) -- todo o Flutter que chamava
--    isso ja saiu.
-- ---------------------------------------------------------------------
drop function if exists public.finish_game_match(uuid, text, integer, integer);
drop function if exists public.discard_game_match(uuid);
drop function if exists public.list_pending_game_matches(integer);
drop function if exists public.dismiss_all_pending_game_matches();
drop function if exists public.get_pending_game_match();
drop function if exists public._expire_stale_game_matches(uuid);

-- ---------------------------------------------------------------------
-- 3. Tela de match details (detalhe/editar resultado/gols e assistencias).
-- ---------------------------------------------------------------------
drop function if exists public.get_game_match_details(uuid);
drop function if exists public.update_game_match_result(uuid, text, integer, integer);
drop function if exists public.upsert_game_match_player_stats(uuid, jsonb);

-- ---------------------------------------------------------------------
-- 4. Dashboard esportivo do Time -- nunca teve tela no Flutter.
-- ---------------------------------------------------------------------
drop function if exists public.get_team_sports_dashboard(uuid);
drop function if exists public.get_team_player_leaderboard(uuid, boolean, integer, integer);
drop function if exists public._team_player_leaderboard(uuid, boolean, integer, integer);
drop function if exists public._team_ranking_min_matches();
drop function if exists public._recompute_team_sports_leaders(uuid, uuid);
drop table if exists public.team_sports_leaders_state;

-- ---------------------------------------------------------------------
-- 5. Estatisticas de conta computadas de partida real -- get_fc_account_stats
--    nunca teve chamador no Flutter (dead code desde a limpeza que tirou
--    sport_summary de get_team_member_profile). get_weekend_league_account_stats
--    e get_rivals_account_stats continuam existindo (weekend_league_detail_page
--    e rivals_detail_page ainda chamam), mas passam a devolver so o record
--    manual -- e a unica fonte que a UI le de qualquer forma.
-- ---------------------------------------------------------------------
drop function if exists public.get_fc_account_stats(uuid);
drop function if exists public._fc_account_player_leaderboard(uuid, text, uuid, boolean, integer);
drop function if exists public._fc_account_match_aggregate(uuid, text, uuid);

create or replace function public.get_weekend_league_account_stats(
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
        'manual', case when v_manual.manual_wins is null then null
            else jsonb_build_object('wins', v_manual.manual_wins, 'losses', v_manual.manual_losses)
        end
    );
end;
$$;

comment on function public.get_weekend_league_account_stats(uuid, uuid) is
    'Record manual (unica fonte) de WL de uma conta num evento.';

create or replace function public.get_rivals_account_stats(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_manual public.fc_account_rivals_progress;
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

    select * into v_manual from public.fc_account_rivals_progress
    where fc_account_id = p_fc_account_id;

    return jsonb_build_object(
        'manual', jsonb_build_object(
            'wins', coalesce(v_manual.manual_wins, 0),
            'losses', coalesce(v_manual.manual_losses, 0)
        )
    );
end;
$$;

comment on function public.get_rivals_account_stats(uuid) is
    'Record manual (unica fonte) de Rivals de uma conta. All-time.';

-- ---------------------------------------------------------------------
-- 6. list_my_fc_accounts perde o computado de WL (lia game_matches.result) --
--    o manual ja era a unica fonte que Profile.weekendLeagueRecord le.
-- ---------------------------------------------------------------------
create or replace function public.list_my_fc_accounts()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_event public.weekend_league_events;
    v_result jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_event := public.get_current_weekend_league_event();

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'name', a.name,
            'avatar_url', a.avatar_url,
            'is_active', a.is_active,
            'rivals_division', a.rivals_division,
            'platform', a.platform,
            'team_ids', coalesce((
                select jsonb_agg(t.team_id)
                from public.fc_account_teams t
                where t.fc_account_id = a.id
            ), '[]'::jsonb),
            'weekend_league_manual', (
                select jsonb_build_object('wins', p.manual_wins, 'losses', p.manual_losses)
                from public.fc_account_weekend_league_progress p
                where p.fc_account_id = a.id
                  and v_event.id is not null
                  and p.weekend_league_event_id = v_event.id
                  and p.manual_wins is not null
            ),
            'rivals_manual', (
                select jsonb_build_object('wins', r.manual_wins, 'losses', r.manual_losses)
                from public.fc_account_rivals_progress r
                where r.fc_account_id = a.id
            )
        )
        order by a.created_at
    ), '[]'::jsonb)
    into v_result
    from public.user_fc_accounts a
    where a.user_id = v_user_id and a.is_active;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'accounts', v_result,
        'weekend_league_event', case when v_event.id is null then null else jsonb_build_object(
            'id', v_event.id,
            'number', v_event.number,
            'starts_at', to_jsonb(v_event.starts_at),
            'ends_at', to_jsonb(v_event.ends_at)
        ) end
    );
end;
$$;

-- ---------------------------------------------------------------------
-- 7. get_team_member_profile: historico de WL passa a ser so manual (o
--    computado de partida real nunca era a fonte preferida mesmo).
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
    v_squad_json jsonb;
    v_rivals_manual public.fc_account_rivals_progress;
    v_wl jsonb;
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

        if v_squad.id is not null then
            select jsonb_build_object(
                'id', v_squad.id,
                'name', v_squad.name,
                'formation', (
                    select jsonb_build_object(
                        'code', f.code,
                        'display_name', f.display_name,
                        'slots', (
                            select coalesce(jsonb_agg(
                                jsonb_build_object(
                                    'slot_code', fs.slot_code,
                                    'position_code', fs.position_code,
                                    'x', fs.x,
                                    'y', fs.y,
                                    'sort_order', fs.sort_order
                                ) order by fs.sort_order
                            ), '[]'::jsonb)
                            from public.fc_formation_slots as fs
                            where fs.formation_code = f.code
                        )
                    )
                    from public.fc_formations as f
                    where f.code = v_squad.formation_code
                ),
                'starters', (
                    select coalesce(jsonb_agg(
                        jsonb_build_object(
                            'slot_code', sl.slot_code,
                            'card', public._fc_card_json(c)
                        )
                    ), '[]'::jsonb)
                    from public.fc_squad_slots as sl
                    join public.fc_player_cards as c on c.id = sl.player_card_id
                    where sl.squad_id = v_squad.id and sl.slot_type = 'STARTING'
                )
            ) into v_squad_json;
        end if;

        select * into v_rivals_manual
        from public.fc_account_rivals_progress
        where fc_account_id = v_account.id;

        with recent_events as (
            select e.*
            from public.weekend_league_events as e
            where exists (
                select 1 from public.fc_account_weekend_league_progress as p
                where p.fc_account_id = v_account.id
                  and p.weekend_league_event_id = e.id
            )
            order by e.starts_at desc
            limit 15
        )
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'event_id', re.id,
                'number', re.number,
                'season', re.season,
                'starts_at', to_jsonb(re.starts_at),
                'wins', coalesce(m.manual_wins, 0),
                'losses', coalesce(m.manual_losses, 0)
            ) order by re.starts_at desc
        ), '[]'::jsonb)
        into v_wl
        from recent_events as re
        left join public.fc_account_weekend_league_progress as m
            on m.fc_account_id = v_account.id and m.weekend_league_event_id = re.id;
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
            'rivals_division', v_account.rivals_division,
            'rivals_wins', coalesce(v_rivals_manual.manual_wins, 0),
            'rivals_losses', coalesce(v_rivals_manual.manual_losses, 0)
        ) end,
        'squad', v_squad_json,
        'weekend_league_history', coalesce(v_wl, '[]'::jsonb)
    );
end;
$$;

comment on function public.get_team_member_profile(uuid, uuid, uuid) is
    'Perfil publico de um membro do time: conta vinculada aquele time, divisao+placar manual de Rivals, historico manual de WL por semana, escalacao principal completa. So membros do mesmo time podem chamar.';

-- ---------------------------------------------------------------------
-- 8. get_public_team perde o record agregado de partida real -- nunca foi
--    lido pelo Flutter (parseado no model, nunca renderizado na pagina).
-- ---------------------------------------------------------------------
create or replace function public.get_public_team(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_team public.teams;
    v_members jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_team from public.teams where id = p_team_id and is_public;

    if v_team.id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'display_name', p.display_name,
            'avatar_url', p.avatar_url,
            'slug', upp.slug,
            'role', tm.role
        )
        order by tm.role, p.display_name
    ), '[]'::jsonb)
    into v_members
    from public.team_members as tm
    join public.profiles as p on p.id = tm.user_id
    join lateral (
        select prof.slug
        from public.user_public_profiles as prof
        left join public.fc_account_teams as fat
            on fat.fc_account_id = prof.fc_account_id and fat.team_id = v_team.id
        where prof.user_id = tm.user_id and prof.is_enabled
        order by (fat.team_id is not null) desc, prof.updated_at desc
        limit 1
    ) as upp on true
    where tm.team_id = v_team.id;

    return jsonb_build_object(
        'schema_version', 1,
        'found', true,
        'team', jsonb_build_object(
            'id', v_team.id,
            'name', v_team.name,
            'tag', v_team.tag,
            'logo_url', v_team.logo_url,
            'primary_color', v_team.primary_color,
            'secondary_color', v_team.secondary_color,
            'member_count', (
                select count(*) from public.team_members as tm
                where tm.team_id = v_team.id
            )
        ),
        'members', v_members
    );
end;
$$;

-- ---------------------------------------------------------------------
-- 9. _dispatch_finished_weekend_league_notifications: so conta manual --
--    nao ha mais "partida FINISHED" pra derivar vitorias/derrotas dela, e o
--    manual ja era a fonte preferida (coalesce) mesmo antes.
-- ---------------------------------------------------------------------
create or replace function public._dispatch_finished_weekend_league_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_event record;
    v_account record;
    v_team_id uuid;
    v_member record;
    v_wins integer;
    v_losses integer;
    v_count integer := 0;
begin
    for v_event in
        select id, ends_at
        from public.weekend_league_events
        where ends_at < now() and notifications_dispatched_at is null
    loop
        -- So Contas com override manual pra este evento recebem o anuncio --
        -- ninguem "termina" um WL que nao registrou nada.
        for v_account in
            select distinct a.id as fc_account_id, a.name as account_name, a.user_id
            from public.user_fc_accounts as a
            where exists (
                select 1 from public.fc_account_weekend_league_progress as wl
                where wl.fc_account_id = a.id
                  and wl.weekend_league_event_id = v_event.id
                  and wl.manual_wins is not null
            )
        loop
            select coalesce(wl.manual_wins, 0), coalesce(wl.manual_losses, 0)
            into v_wins, v_losses
            from public.fc_account_weekend_league_progress as wl
            where wl.fc_account_id = v_account.fc_account_id
              and wl.weekend_league_event_id = v_event.id;

            for v_team_id in
                select team_id from public.fc_account_teams
                where fc_account_id = v_account.fc_account_id
            loop
                for v_member in
                    select tm.user_id
                    from public.team_members as tm
                    where tm.team_id = v_team_id
                      and tm.user_id <> v_account.user_id
                loop
                    perform public._emit_user_notification(
                        v_member.user_id, 'WEEKEND_LEAGUE', 'WEEKEND_LEAGUE_FINISHED',
                        'WEEKEND_LEAGUE_FINISHED:' || v_event.id || ':' || v_account.fc_account_id,
                        'notification_weekend_league_finished',
                        jsonb_build_object(
                            'team_id', v_team_id,
                            'event_id', v_event.id,
                            'fc_account_id', v_account.fc_account_id,
                            'account_name', v_account.account_name,
                            'user_id', v_account.user_id,
                            'display_name', (
                                select display_name from public.profiles
                                where id = v_account.user_id
                            ),
                            'wins', v_wins,
                            'losses', v_losses
                        ),
                        'team_weekend_league', jsonb_build_object('team_id', v_team_id),
                        'weekend_league_event', v_event.id
                    );
                end loop;
            end loop;

            v_count := v_count + 1;
        end loop;

        update public.weekend_league_events
        set notifications_dispatched_at = now()
        where id = v_event.id;
    end loop;

    return v_count;
end;
$$;

-- ---------------------------------------------------------------------
-- 10. get_team_match_search_history: RPC da versao antiga (pre-unificacao
--     busca+jogo) do Historico -- ja sem chamador no Flutter.
-- ---------------------------------------------------------------------
drop function if exists public.get_team_match_search_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
);

-- ---------------------------------------------------------------------
-- 11. get_team_activity_history perde o lado GAME por completo -- o
--     Historico so mostra buscas (achou/cancelou/expirou) agora.
-- ---------------------------------------------------------------------
drop function if exists public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, text, text, uuid, timestamptz, timestamptz, uuid
);

create or replace function public.get_team_activity_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_occurred_at timestamptz default null,
    p_cursor_id uuid default null,
    p_search_status text default null,
    p_user_id uuid default null,
    p_from timestamptz default null,
    p_to timestamptz default null,
    p_fc_account_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(item order by s.finished_at desc, s.id desc), '[]'::jsonb),
           count(*)
    into v_rows, v_count
    from (
        select
            s.finished_at, s.id,
            jsonb_build_object(
                'type', 'SEARCH',
                'id', s.id,
                'user_id', s.user_id,
                'display_name', coalesce(p.display_name, ''),
                'avatar_url', p.avatar_url,
                'game_mode', s.game_mode,
                'status', s.status,
                'started_at', to_jsonb(s.started_at),
                'finished_at', to_jsonb(s.finished_at),
                'duration_seconds',
                    round(extract(epoch from (s.finished_at - s.started_at)))::int,
                'fc_account_id', s.fc_account_id,
                'fc_account_name', a.name
            ) as item
        from public.match_search_sessions as s
        left join public.profiles as p on p.id = s.user_id
        left join public.user_fc_accounts as a on a.id = s.fc_account_id
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_search_status is null or s.status = p_search_status)
          and (p_user_id is null or s.user_id = p_user_id)
          and (p_fc_account_id is null or s.fc_account_id = p_fc_account_id)
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
          and (
              p_cursor_occurred_at is null or p_cursor_id is null
              or (s.finished_at, s.id) < (p_cursor_occurred_at, p_cursor_id)
          )
        order by s.finished_at desc, s.id desc
        limit v_limit + 1
    ) as s;

    v_items := case
        when v_count > v_limit then
            (select jsonb_agg(value)
             from jsonb_array_elements(v_rows) with ordinality as t(value, i)
             where i <= v_limit)
        else v_rows
    end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case
            when v_count > v_limit then jsonb_build_object(
                'occurred_at', v_items -> (v_limit - 1) ->> 'finished_at',
                'id', v_items -> (v_limit - 1) -> 'id'
            )
            else null
        end
    );
end;
$$;

comment on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz, uuid
) is
    'Historico de buscas do time (achou partida/cancelou/expirou), paginado. So o que match_search_sessions cobre -- sem conceito de partida/resultado.';

revoke execute on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz, uuid
) from public, anon;
grant execute on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz, uuid
) to authenticated;

-- ---------------------------------------------------------------------
-- 12. game_match_player_stats e as colunas de resultado/placar de
--     game_matches -- ninguem mais escreve ou le isso.
-- ---------------------------------------------------------------------
drop table if exists public.game_match_player_stats;

alter table public.game_matches
    drop column if exists result,
    drop column if exists goals_for,
    drop column if exists goals_against,
    drop column if exists result_dismissed;
