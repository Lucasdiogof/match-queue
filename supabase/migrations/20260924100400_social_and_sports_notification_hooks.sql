-- Liga os emissores de evento (item 53) aos 4 pontos de mutacao que
-- realmente importam. Nenhuma regra de negocio muda: mesmos locks, mesma
-- validacao, mesmos FQ00x. So passam a chamar _recompute_team_sports_leaders
-- ou _emit_user_notification depois de commitar o que ja commitavam.

-- ---------------------------------------------------------------------
-- finish_game_match: resultado nasce aqui pela primeira vez -- pode mudar
-- lider/artilheiro/assistente de todo Time vinculado a esta Conta.
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
    if v_match.status <> 'IN_MATCH' then
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
        ended_at = now()
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
-- upsert_game_match_player_stats: gols/assistencias por jogador podem
-- mudar artilharia/assistencias sem que o placar da partida tenha mudado
-- agora (a partida ja podia estar FINISHED havia tempo).
-- ---------------------------------------------------------------------
create or replace function public.upsert_game_match_player_stats(
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
    v_team_id uuid;
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

    if v_match.fc_account_id is not null then
        for v_team_id in
            select team_id from public.fc_account_teams
            where fc_account_id = v_match.fc_account_id
        loop
            perform public._recompute_team_sports_leaders(v_team_id, v_user_id);
        end loop;
    end if;

    return jsonb_build_object('saved_count', v_saved);
end;
$$;

-- ---------------------------------------------------------------------
-- join_team_by_invite: TEAM_MEMBER_JOINED para quem ja estava no Time
-- (item 19), nunca para quem acabou de entrar (item 16).
-- ---------------------------------------------------------------------
create or replace function public.join_team_by_invite(p_code text)
returns table (
    already_member boolean,
    team_id uuid,
    team_name text,
    team_tag text,
    role text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_code text := upper(btrim(coalesce(p_code, '')));
    v_link public.team_invite_links;
    v_existing public.team_members;
    v_team public.teams;
    v_joiner_name text;
    v_member record;
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    select * into v_link
    from public.team_invite_links
    where code = v_code
    for update;

    if v_link.id is null then
        raise exception 'invite not found'
            using errcode = 'FQ008';
    end if;

    if not v_link.is_active then
        raise exception 'invite is not active'
            using errcode = 'FQ009';
    end if;

    if v_link.expires_at is not null and v_link.expires_at < now() then
        raise exception 'invite has expired'
            using errcode = 'FQ010';
    end if;

    if v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        raise exception 'invite has been exhausted'
            using errcode = 'FQ011';
    end if;

    select * into v_existing
    from public.team_members as tm
    where tm.team_id = v_link.team_id and tm.user_id = v_user_id;

    if v_existing.team_id is not null then
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end if;

    begin
        insert into public.team_members (team_id, user_id, role)
        values (v_link.team_id, v_user_id, 'PLAYER');
    exception when unique_violation then
        select * into v_existing
        from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.user_id = v_user_id;
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end;

    update public.team_invite_links
    set usage_count = usage_count + 1
    where id = v_link.id;

    select * into v_team from public.teams where id = v_link.team_id;
    select display_name into v_joiner_name from public.profiles where id = v_user_id;

    for v_member in
        select tm.user_id
        from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.user_id <> v_user_id
    loop
        perform public._emit_user_notification(
            v_member.user_id, 'TEAMS', 'TEAM_MEMBER_JOINED',
            'TEAM_MEMBER_JOINED:' || v_link.team_id || ':' || v_user_id,
            'notification_team_member_joined',
            jsonb_build_object(
                'team_id', v_link.team_id,
                'team_name', v_team.name,
                'user_id', v_user_id,
                'display_name', coalesce(v_joiner_name, '')
            ),
            'team_detail', jsonb_build_object('team_id', v_link.team_id),
            'team', v_link.team_id
        );
    end loop;

    return query select
        false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$$;

comment on function public.join_team_by_invite(text) is
    'Entrada atomica no time via convite. Sempre role=PLAYER. Ja membro '
    'devolve already_member=true sem duplicar linha nem incrementar uso. '
    'Membros existentes recebem TEAM_MEMBER_JOINED; quem entrou, nao.';

revoke execute on function public.join_team_by_invite(text) from public, anon;

-- ---------------------------------------------------------------------
-- update_rivals_division: RIVALS_DIVISION_CHANGED para os OUTROS membros
-- de cada Time vinculado a esta Conta (item 13), nunca para o dono da
-- Conta (item 16 -- e a propria acao dele).
-- ---------------------------------------------------------------------
create or replace function public.update_rivals_division(p_id uuid, p_division text)
returns public.user_fc_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_account public.user_fc_accounts;
    v_old_division text;
    v_account_name text;
    v_team_id uuid;
    v_member record;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_division is not null and p_division not in (
        'DIV_10', 'DIV_9', 'DIV_8', 'DIV_7', 'DIV_6',
        'DIV_5', 'DIV_4', 'DIV_3', 'DIV_2', 'DIV_1', 'ELITE'
    ) then
        raise exception 'invalid rivals division' using errcode = 'FQ028';
    end if;

    select rivals_division, name into v_old_division, v_account_name
    from public.user_fc_accounts
    where id = p_id and user_id = v_user_id;

    update public.user_fc_accounts
    set rivals_division = p_division
    where id = p_id and user_id = v_user_id
    returning * into v_account;

    if v_account.id is null then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if p_division is not null and p_division is distinct from v_old_division then
        for v_team_id in
            select team_id from public.fc_account_teams
            where fc_account_id = p_id
        loop
            for v_member in
                select tm.user_id
                from public.team_members as tm
                where tm.team_id = v_team_id and tm.user_id <> v_user_id
            loop
                perform public._emit_user_notification(
                    v_member.user_id, 'RIVALS', 'RIVALS_DIVISION_CHANGED',
                    'RIVALS_DIVISION_CHANGED:' || v_team_id || ':' || p_id || ':' || p_division,
                    'notification_rivals_division_changed',
                    jsonb_build_object(
                        'team_id', v_team_id,
                        'fc_account_id', p_id,
                        'account_name', v_account_name,
                        'user_id', v_user_id,
                        'display_name', (
                            select display_name from public.profiles where id = v_user_id
                        ),
                        'division', p_division
                    ),
                    'team_rivals', jsonb_build_object('team_id', v_team_id),
                    'fc_account', p_id
                );
            end loop;
        end loop;
    end if;

    return v_account;
end;
$$;

revoke execute on function public.update_rivals_division(uuid, text) from public, anon;
grant execute on function public.update_rivals_division(uuid, text) to authenticated;
