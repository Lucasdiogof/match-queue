-- O historico so contava a BUSCA (quando comecou, quanto durou, como
-- terminou). A PARTIDA que saiu dela -- conta usada, modalidade, resultado,
-- placar -- nunca chegava na tela, entao "achou partida" era o fim da
-- historia. Aqui a leitura ganha essa dimensao.
--
-- Duas correcoes de leitura, ambas conservadoras:
--
-- 1. Escopo do time. A busca de uma Conta toca N Times
--    (match_search_session_teams), mas a sessao guarda so o primeiro deles em
--    team_id. Filtrar por s.team_id escondia do Time B toda busca em que o
--    Time A entrou primeiro. Passa a ser um EXISTS sobre session_teams -- o
--    mesmo padrao ja obrigatorio no dashboard esportivo, justamente porque
--    filtra sem multiplicar linha.
--
-- 2. Um game_match por linha. Nao ha unique index em
--    game_matches.search_session_id, entao um join direto poderia duplicar a
--    sessao. O lateral com limit 1 fecha isso por construcao, sem depender
--    de uma garantia que o schema nao da.
--
-- result null nao e derrota: e "nao informado", e a UI precisa saber a
-- diferenca. Por isso match_status vai junto -- ABANDONED/EXPIRED sem
-- resultado sao desfechos legitimos, nao dado faltando.

create or replace function public.get_team_match_search_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_finished_at timestamptz default null,
    p_cursor_id uuid default null,
    p_status text default null,
    p_user_id uuid default null,
    p_from timestamptz default null,
    p_to timestamptz default null
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

    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (
                order by s.finished_at desc, s.id desc
            ) as ord,
            jsonb_build_object(
                'session_id', s.id,
                'user_id', s.user_id,
                'display_name', coalesce(p.display_name, ''),
                'avatar_url', p.avatar_url,
                'status', s.status,
                'finish_reason', s.finish_reason,
                'started_at', to_jsonb(s.started_at),
                'finished_at', to_jsonb(s.finished_at),
                'duration_seconds',
                    round(extract(epoch from (s.finished_at - s.started_at)))::int,
                'configured_duration_seconds',
                    round(extract(epoch from (s.expires_at - s.started_at)))::int,
                'game_mode', s.game_mode,
                'fc_account_id', s.fc_account_id,
                'fc_account_name', fa.name,
                'match_id', gm.id,
                'match_status', gm.status,
                'match_started_at', to_jsonb(gm.started_at),
                'result', gm.result,
                'goals_for', gm.goals_for,
                'goals_against', gm.goals_against
            ) as item
        from public.match_search_sessions as s
        left join public.profiles as p on p.id = s.user_id
        left join public.user_fc_accounts as fa on fa.id = s.fc_account_id
        left join lateral (
            select m.id, m.status, m.started_at, m.result,
                   m.goals_for, m.goals_against
            from public.game_matches as m
            where m.search_session_id = s.id
            order by m.started_at desc
            limit 1
        ) as gm on true
        where exists (
                  select 1
                  from public.match_search_session_teams as st
                  where st.search_session_id = s.id
                    and st.team_id = p_team_id
              )
          and s.finished_at is not null
          and (p_status is null or s.status = p_status)
          and (p_user_id is null or s.user_id = p_user_id)
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
          and (
              p_cursor_finished_at is null
              or p_cursor_id is null
              or (s.finished_at, s.id) < (p_cursor_finished_at, p_cursor_id)
          )
        order by s.finished_at desc, s.id desc
        limit v_limit + 1
    ) as page;

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
                'finished_at', v_items -> (v_limit - 1) -> 'finished_at',
                'id', v_items -> (v_limit - 1) -> 'session_id'
            )
            else null
        end
    );
end;
$$;

comment on function public.get_team_match_search_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) is
    'Historico de buscas do time com a partida resultante. Cursor keyset; escopo por session_teams.';

-- Suporta o EXISTS acima na direcao (sessao -> time) sem depender do indice
-- por team_id sozinho.
create index if not exists match_search_session_teams_team_session_idx
    on public.match_search_session_teams (team_id, search_session_id);
