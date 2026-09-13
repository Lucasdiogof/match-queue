-- Perfil do jogador (perfil de um MEMBRO DO MESMO TIME) ganha o campinho de
-- verdade em vez de "4/11 titulares" em texto -- reusa a MESMA forma de
-- formation/starters que get_fc_squad_builder ja devolve, pro cliente poder
-- desenhar com o mesmo SquadField do proprio builder (so leitura, sem
-- callback nenhum). Tambem devolve o placar manual de Rivals da conta
-- (antes so vinha a divisao) -- sem isso o card de Rivals do perfil nunca
-- teria vitorias/derrotas pra mostrar.
--
-- sport_summary sai do payload: nunca foi preenchido (nenhuma chamada real
-- setava essa chave), e o card que lia dele saiu do app na mesma leva que
-- tirou artilharia/assistencia -- nao ha por que continuar computando o que
-- nada mais le.
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
                select 1 from public.game_matches as gm
                where gm.fc_account_id = v_account.id
                  and gm.weekend_league_event_id = e.id
            ) or exists (
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
    'Perfil publico de um membro do time: conta vinculada aquele time, divisao+placar de Rivals, historico de WL por semana, escalacao principal completa (formacao+titulares). So membros do mesmo time podem chamar.';

revoke execute on function public.get_team_member_profile(uuid, uuid, uuid)
    from public, anon;
grant execute on function public.get_team_member_profile(uuid, uuid, uuid)
    to authenticated;
