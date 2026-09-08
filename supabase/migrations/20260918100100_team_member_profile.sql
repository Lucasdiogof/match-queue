-- Perfil publico de jogador (Etapa 11, Parte B). Read model novo: qualquer
-- MEMBRO DO MESMO TIME pode ver display_name/avatar, a Conta vinculada
-- aquele time especificamente, divisao de Rivals atual, historico de
-- Weekend League e um resumo do squad principal. Nunca expoe: historico de
-- busca, buscas canceladas, outros times do usuario, dados de outras
-- contas. Fora do time, negado (FQ012, mesmo codigo de "nao e membro").
--
-- Ambiguidade deliberada: se o usuario tiver mais de uma Conta vinculada ao
-- MESMO time (raro, mas o modelo permite), a funcao nao escolhe sozinha --
-- devolve os candidatos e needs_account_selection=true, e a UI oferece um
-- seletor. Chamar de novo com p_fc_account_id resolve.
create function public.get_team_member_profile(
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
        'weekend_league_history', coalesce(v_wl, '[]'::jsonb)
    );
end;
$$;

comment on function public.get_team_member_profile(uuid, uuid, uuid) is
    'Perfil publico de um membro do time: conta vinculada aquele time, divisao de Rivals, historico de WL, resumo do squad principal. So membros do mesmo time podem chamar.';

revoke execute on function public.get_team_member_profile(uuid, uuid, uuid)
    from public, anon;
grant execute on function public.get_team_member_profile(uuid, uuid, uuid)
    to authenticated;
