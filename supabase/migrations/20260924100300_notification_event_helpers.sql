-- Ponto unico de emissao para eventos sociais/esportivos (item 54): inbox +
-- outbox + dedupe + preferencia num so lugar, para nenhuma RPC de mutacao
-- reimplementar essa logica na mao.
--
-- Diferenca central para o _enqueue_notification da Etapa 7 (que continua
-- existindo, intocado, para YOUR_TURN/SEARCH_EXPIRING/SEARCH_EXPIRED): este
-- SEMPRE grava a inbox, e so DEPOIS decide se tambem enfileira push -- os
-- dois nunca compartilham a mesma condicao (item 22/25/26). O outro helper
-- so grava outbox, porque aqueles 3 tipos nunca tiveram inbox.
create function public._emit_user_notification(
    p_user_id uuid,
    p_category public.app_notification_category,
    p_type public.notification_type,
    p_dedupe_key text,
    p_title_key text,
    p_params jsonb default '{}'::jsonb,
    p_deep_link_type text default null,
    p_deep_link_params jsonb default '{}'::jsonb,
    p_source_entity_type text default null,
    p_source_entity_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_inbox_id uuid;
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.user_notifications (
        user_id, category, type, title_key, params,
        deep_link_type, deep_link_params,
        source_entity_type, source_entity_id, dedupe_key
    )
    values (
        p_user_id, p_category, p_type::text, p_title_key, coalesce(p_params, '{}'::jsonb),
        p_deep_link_type, coalesce(p_deep_link_params, '{}'::jsonb),
        p_source_entity_type, p_source_entity_id, p_dedupe_key
    )
    on conflict (dedupe_key) do nothing
    returning id into v_inbox_id;

    -- Retry que ja gravou a inbox no passado nao gera um segundo push
    -- (item 28): so ha o que entregar quando a linha e realmente nova.
    if v_inbox_id is null then
        return;
    end if;

    if not public._notification_allowed(p_user_id, p_type) then
        return;
    end if;

    -- Payload pequeno de proposito (item 44): so o suficiente para o
    -- worker montar o data payload do FCM. Texto de push continua sendo
    -- resolvido pelo worker a partir de type + locale, nunca gravado aqui.
    insert into public.notification_outbox (
        user_id, type, payload, dedupe_key
    )
    values (
        p_user_id, p_type,
        jsonb_build_object('notification_id', v_inbox_id) || coalesce(p_params, '{}'::jsonb),
        'inbox:' || p_dedupe_key
    )
    on conflict (dedupe_key) do nothing;
end;
$$;

revoke execute on function public._emit_user_notification(
    uuid, public.app_notification_category, public.notification_type,
    text, text, jsonb, text, jsonb, text, uuid
) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Baseline de "quem lidera hoje" por Time (itens 61-64). Sem isso, toda
-- RPC que muda resultado teria que reconstruir "quem era o lider antes" a
-- partir do historico inteiro -- fragil e caro. A tabela guarda so o
-- ultimo estado conhecido; a versao existe para o dedupe_key poder mudar a
-- cada troca real sem depender de timestamp (troca duas vezes no mesmo
-- segundo ainda gera dois eventos distintos).
-- ---------------------------------------------------------------------
create table public.team_sports_leaders_state (
    team_id uuid primary key references public.teams (id) on delete cascade,

    rank_leader_user_id uuid,
    rank_leader_version integer not null default 0,

    top_scorer_key text,
    top_scorer_version integer not null default 0,

    top_assist_key text,
    top_assist_version integer not null default 0,

    updated_at timestamptz not null default now()
);

comment on table public.team_sports_leaders_state is
    'Ultimo lider/artilheiro/assistente conhecido por Time -- baseline para so notificar troca real (item 61), nunca todo recalculo.';

alter table public.team_sports_leaders_state enable row level security;
revoke all on table public.team_sports_leaders_state from anon, authenticated, public;

-- Recalcula ranking + artilharia + assistencias do Time e emite evento
-- SOMENTE quando o primeiro lugar realmente muda de pessoa (itens 9/10/11).
-- Empate que so reordena por nome nao conta (item 64): o criterio de
-- desempate e o mesmo do dashboard (win_rate, wins, matches, nome), entao
-- "trocar" aqui sempre significa um novo user_id/chave em primeiro.
--
-- p_excluded_user_id: quem acabou de agir nao precisa ser avisado da
-- propria acao (item 16). Se o novo lider for outra pessoa, ela recebe
-- normalmente.
create function public._recompute_team_sports_leaders(
    p_team_id uuid,
    p_excluded_user_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_min_matches integer := public._team_ranking_min_matches();
    v_state public.team_sports_leaders_state;
    v_new_leader uuid;
    v_new_scorer_key text;
    v_new_scorer_name text;
    v_new_scorer_user uuid;
    v_new_assist_key text;
    v_new_assist_name text;
    v_new_assist_user uuid;
    v_member record;
begin
    select * into v_state
    from public.team_sports_leaders_state
    where team_id = p_team_id;

    -- Lider do ranking: mesma ordenacao do dashboard, restrita a quem ja
    -- bateu o minimo de partidas (item 45 -- nunca coroar quem tem 1 jogo).
    with team_accounts as (
        select a.id as fc_account_id, a.user_id
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    finished as (
        select m.user_id, m.fc_account_id, m.result
        from public.game_matches as m
        where m.status = 'FINISHED' and m.result is not null
          and exists (
              select 1 from team_accounts as ta
              where ta.fc_account_id = m.fc_account_id
          )
    ),
    per_user as (
        select
            ta.user_id,
            count(f.*) as matches,
            count(f.*) filter (where f.result = 'WIN') as wins
        from team_accounts as ta
        left join finished as f on f.fc_account_id = ta.fc_account_id
        group by ta.user_id
    )
    select pu.user_id into v_new_leader
    from per_user as pu
    left join public.profiles as p on p.id = pu.user_id
    where pu.matches >= v_min_matches
    order by
        case when pu.matches = 0 then null
             else pu.wins::numeric / pu.matches end desc nulls last,
        pu.wins desc,
        pu.matches desc,
        coalesce(p.display_name, '') asc
    limit 1;

    -- Artilheiro/assistente do Time: mesma chave (Conta + carta) do
    -- leaderboard (item 65) -- nunca consolidar por jogador base.
    with team_accounts as (
        select a.id as fc_account_id, a.user_id
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    agg as (
        select
            ta.fc_account_id,
            ta.user_id,
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            (array_agg(s.player_name order by s.updated_at desc))[1] as player_name,
            sum(s.goals)::integer as goals,
            sum(s.assists)::integer as assists
        from public.game_match_player_stats as s
        join public.game_matches as m on m.id = s.game_match_id
        join team_accounts as ta on ta.fc_account_id = m.fc_account_id
        group by ta.fc_account_id, ta.user_id, player_key
    )
    select
        a.fc_account_id || ':' || a.player_key, a.player_name, a.user_id
    into v_new_scorer_key, v_new_scorer_name, v_new_scorer_user
    from agg as a
    where a.goals > 0
    order by a.goals desc, a.player_name asc
    limit 1;

    with team_accounts as (
        select a.id as fc_account_id, a.user_id
        from public.fc_account_teams as fat
        join public.user_fc_accounts as a on a.id = fat.fc_account_id
        join public.team_members as tm
            on tm.team_id = fat.team_id and tm.user_id = a.user_id
        where fat.team_id = p_team_id
    ),
    agg as (
        select
            ta.fc_account_id,
            ta.user_id,
            coalesce(s.player_card_id::text, s.snapshot_player_key) as player_key,
            (array_agg(s.player_name order by s.updated_at desc))[1] as player_name,
            sum(s.assists)::integer as assists
        from public.game_match_player_stats as s
        join public.game_matches as m on m.id = s.game_match_id
        join team_accounts as ta on ta.fc_account_id = m.fc_account_id
        group by ta.fc_account_id, ta.user_id, player_key
    )
    select
        a.fc_account_id || ':' || a.player_key, a.player_name, a.user_id
    into v_new_assist_key, v_new_assist_name, v_new_assist_user
    from agg as a
    where a.assists > 0
    order by a.assists desc, a.player_name asc
    limit 1;

    if v_state.team_id is null then
        -- Primeira vez que este Time e observado: so grava baseline, nunca
        -- notifica (item 62) -- senao todo Time antigo "ganharia" um lider
        -- novo no dia em que a Etapa 15 for ligada.
        insert into public.team_sports_leaders_state (
            team_id, rank_leader_user_id, top_scorer_key, top_assist_key
        )
        values (p_team_id, v_new_leader, v_new_scorer_key, v_new_assist_key);
        return;
    end if;

    if v_new_leader is not null
        and v_new_leader is distinct from v_state.rank_leader_user_id
    then
        update public.team_sports_leaders_state
        set rank_leader_user_id = v_new_leader,
            rank_leader_version = rank_leader_version + 1,
            updated_at = now()
        where team_id = p_team_id
        returning * into v_state;

        for v_member in
            select tm.user_id
            from public.team_members as tm
            where tm.team_id = p_team_id
              and tm.user_id <> v_new_leader
              and tm.user_id is distinct from p_excluded_user_id
        loop
            perform public._emit_user_notification(
                v_member.user_id, 'RANKINGS', 'TEAM_LEADER_CHANGED',
                'TEAM_LEADER_CHANGED:' || p_team_id || ':' || v_state.rank_leader_version,
                'notification_team_leader_changed',
                jsonb_build_object(
                    'team_id', p_team_id,
                    'leader_user_id', v_new_leader,
                    'leader_display_name', (
                        select display_name from public.profiles where id = v_new_leader
                    )
                ),
                'team_ranking', jsonb_build_object('team_id', p_team_id),
                'team', p_team_id
            );
        end loop;

        -- O novo lider tambem merece saber, mesmo excluido do loop acima
        -- por engano nenhum: ele so entra no "exceto autor" se ele MESMO
        -- foi quem agiu (proprio jogo o levou ao topo).
        if v_new_leader is distinct from p_excluded_user_id then
            perform public._emit_user_notification(
                v_new_leader, 'RANKINGS', 'TEAM_LEADER_CHANGED',
                'TEAM_LEADER_CHANGED:' || p_team_id || ':' || v_state.rank_leader_version || ':self',
                'notification_you_are_team_leader',
                jsonb_build_object('team_id', p_team_id),
                'team_ranking', jsonb_build_object('team_id', p_team_id),
                'team', p_team_id
            );
        end if;
    end if;

    if v_new_scorer_key is not null
        and v_new_scorer_key is distinct from v_state.top_scorer_key
    then
        update public.team_sports_leaders_state
        set top_scorer_key = v_new_scorer_key,
            top_scorer_version = top_scorer_version + 1,
            updated_at = now()
        where team_id = p_team_id
        returning * into v_state;

        for v_member in
            select tm.user_id
            from public.team_members as tm
            where tm.team_id = p_team_id
              and tm.user_id is distinct from p_excluded_user_id
        loop
            perform public._emit_user_notification(
                v_member.user_id, 'RANKINGS', 'TEAM_TOP_SCORER_CHANGED',
                'TEAM_TOP_SCORER_CHANGED:' || p_team_id || ':' || v_state.top_scorer_version,
                'notification_team_top_scorer_changed',
                jsonb_build_object(
                    'team_id', p_team_id,
                    'player_name', v_new_scorer_name,
                    'user_id', v_new_scorer_user,
                    'display_name', (
                        select display_name from public.profiles where id = v_new_scorer_user
                    )
                ),
                'team_leaderboard', jsonb_build_object('team_id', p_team_id, 'by_assists', false),
                'team', p_team_id
            );
        end loop;
    end if;

    if v_new_assist_key is not null
        and v_new_assist_key is distinct from v_state.top_assist_key
    then
        update public.team_sports_leaders_state
        set top_assist_key = v_new_assist_key,
            top_assist_version = top_assist_version + 1,
            updated_at = now()
        where team_id = p_team_id;

        for v_member in
            select tm.user_id
            from public.team_members as tm
            where tm.team_id = p_team_id
              and tm.user_id is distinct from p_excluded_user_id
        loop
            perform public._emit_user_notification(
                v_member.user_id, 'RANKINGS', 'TEAM_TOP_ASSIST_CHANGED',
                'TEAM_TOP_ASSIST_CHANGED:' || p_team_id || ':' ||
                    (select top_assist_version from public.team_sports_leaders_state where team_id = p_team_id),
                'notification_team_top_assist_changed',
                jsonb_build_object(
                    'team_id', p_team_id,
                    'player_name', v_new_assist_name,
                    'user_id', v_new_assist_user,
                    'display_name', (
                        select display_name from public.profiles where id = v_new_assist_user
                    )
                ),
                'team_leaderboard', jsonb_build_object('team_id', p_team_id, 'by_assists', true),
                'team', p_team_id
            );
        end loop;
    end if;
end;
$$;

comment on function public._recompute_team_sports_leaders(uuid, uuid) is
    'Recalcula lider/artilheiro/assistente do Time e notifica so em troca real de pessoa. Chamada apos qualquer partida finalizada ou stat editado.';

revoke execute on function public._recompute_team_sports_leaders(uuid, uuid)
    from public, anon, authenticated;
