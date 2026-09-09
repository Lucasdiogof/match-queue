-- Varias partidas podem ficar pendentes de resultado, e informar continua
-- opcional.
--
-- Antes: so existia UMA partida reportavel (a IN_MATCH). Comecar outra
-- marcava a anterior como ABANDONED e finish_game_match so aceitava
-- IN_MATCH, entao aquela partida ficava perdida para sempre -- nao informar
-- na hora era irreversivel, mesmo sem o usuario ter escolhido isso.
--
-- Agora "nao informar" e uma decisao explicita (result_dismissed), separada
-- de "como a partida terminou" (status). Isso preserva o significado de cada
-- status -- EXPIRED continua sendo o cron dizendo que ninguem respondeu,
-- ABANDONED continua sendo "comecou outra" -- e ainda permite reportar
-- depois qualquer partida que o dono nao dispensou.
--
-- Aditivo: default false faz todo historico existente nascer nao-dispensado.
-- Partidas antigas sem resultado voltam a ser reportaveis, que e exatamente
-- o comportamento pedido.

alter table public.game_matches
    add column if not exists result_dismissed boolean not null default false;

comment on column public.game_matches.result_dismissed is
    'Dono escolheu nao informar o resultado. Distinto de status: nao informar e decisao, nao desfecho.';

-- Uma partida so e pendente enquanto nao tem resultado e nao foi dispensada.
-- Indice parcial porque essa e a unica consulta que interessa.
create index if not exists game_matches_pending_result_idx
    on public.game_matches (user_id, started_at desc)
    where result is null and not result_dismissed;

-- ---------------------------------------------------------------------
-- finish_game_match: aceita qualquer partida ainda pendente, nao so a
-- IN_MATCH. FQ022 passa a significar "ja resolvida" (tem resultado ou foi
-- dispensada), que e a condicao honesta.
-- ---------------------------------------------------------------------
create or replace function public.finish_game_match(
    p_match_id uuid,
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
    v_team_id uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;
    if v_match.result is not null or v_match.result_dismissed then
        raise exception 'game match already finalized' using errcode = 'FQ022';
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
    set status = 'FINISHED',
        result = v_result,
        goals_for = v_gf,
        goals_against = v_ga,
        -- Reportar tarde nao reescreve QUANDO a partida acabou; so a que
        -- ainda estava em curso ganha o instante de agora.
        ended_at = coalesce(v_match.ended_at, now())
    where id = v_match.id
    returning * into v_match;

    perform public._notify_matchmaking_changed(v_match.team_id);

    if v_match.fc_account_id is not null then
        for v_team_id in
            select team_id from public.fc_account_teams
            where fc_account_id = v_match.fc_account_id
        loop
            perform public._recompute_team_sports_leaders(v_team_id, v_user_id);
        end loop;
    end if;

    return v_match;
end;
$$;

-- ---------------------------------------------------------------------
-- discard_game_match: marca a decisao. Se ainda estava em curso, encerra.
-- ---------------------------------------------------------------------
create or replace function public.discard_game_match(p_match_id uuid)
returns public.game_matches
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;
    if v_match.result is not null or v_match.result_dismissed then
        raise exception 'game match already finalized' using errcode = 'FQ022';
    end if;

    update public.game_matches
    set result_dismissed = true,
        status = case when v_match.status = 'IN_MATCH'
                      then 'ABANDONED' else v_match.status end,
        ended_at = coalesce(v_match.ended_at, now())
    where id = v_match.id
    returning * into v_match;

    perform public._notify_matchmaking_changed(v_match.team_id);

    return v_match;
end;
$$;

comment on function public.discard_game_match(uuid) is
    'Marca que o dono nao vai informar o resultado. Nunca vira derrota.';

-- ---------------------------------------------------------------------
-- Dispensar tudo de uma vez: o card da Home oferece isso em lote.
-- ---------------------------------------------------------------------
create function public.dismiss_all_pending_game_matches()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_count integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.game_matches
    set result_dismissed = true,
        status = case when status = 'IN_MATCH' then 'ABANDONED' else status end,
        ended_at = coalesce(ended_at, now())
    where user_id = v_user_id
      and result is null
      and not result_dismissed;

    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

comment on function public.dismiss_all_pending_game_matches() is
    'Dispensa todas as partidas pendentes do usuario. Nenhuma vira resultado.';

-- ---------------------------------------------------------------------
-- Lista de pendentes, mais recente primeiro.
-- ---------------------------------------------------------------------
create function public.list_pending_game_matches(p_limit integer default 50)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
    v_items jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._expire_stale_game_matches(v_user_id);

    select coalesce(jsonb_agg(item order by started_at desc), '[]'::jsonb)
    into v_items
    from (
        select
            m.started_at,
            jsonb_build_object(
                'id', m.id,
                'status', m.status,
                'game_mode', m.game_mode,
                'started_at', to_jsonb(m.started_at),
                'ended_at', to_jsonb(m.ended_at),
                'fc_account_id', m.fc_account_id,
                'fc_account_name', fa.name,
                'team_id', m.team_id,
                'team_name', t.name,
                'fc_squad_name', sq.name,
                'weekend_league_number', wl.number
            ) as item
        from public.game_matches as m
        left join public.user_fc_accounts as fa on fa.id = m.fc_account_id
        left join public.teams as t on t.id = m.team_id
        left join public.fc_squads as sq on sq.id = m.fc_squad_id
        left join public.weekend_league_events as wl
               on wl.id = m.weekend_league_event_id
        where m.user_id = v_user_id
          and m.result is null
          and not m.result_dismissed
        order by m.started_at desc
        limit v_limit
    ) as page;

    return jsonb_build_object('items', v_items);
end;
$$;

comment on function public.list_pending_game_matches(integer) is
    'Partidas do usuario sem resultado e nao dispensadas, mais recente primeiro.';

revoke execute on function public.dismiss_all_pending_game_matches()
    from public, anon;
grant execute on function public.dismiss_all_pending_game_matches()
    to authenticated;

revoke execute on function public.list_pending_game_matches(integer)
    from public, anon;
grant execute on function public.list_pending_game_matches(integer)
    to authenticated;
