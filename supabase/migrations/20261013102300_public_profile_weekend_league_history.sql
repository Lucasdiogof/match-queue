-- Perfil publico ganha o mesmo historico de Champions por semana que o
-- perfil de um companheiro de time ja tem (get_team_member_profile) -- so o
-- placar da semana atual nao dava pra navegar pelas edicoes passadas.
-- Mesmo CTE de eventos recentes (15), gated por show_weekend_league igual
-- ao resto da secao.
create or replace function public.get_public_profile(p_identifier text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_row public.user_public_profiles;
    v_slug text := lower(btrim(coalesce(p_identifier, '')));
    v_display_name text;
    v_avatar_url text;
    v_account public.user_fc_accounts;
    v_squad public.fc_squads;
    v_current_event uuid;
    v_wl_manual public.fc_account_weekend_league_progress;
    v_rivals_manual public.fc_account_rivals_progress;
    v_wl_history jsonb;
    v_chem jsonb;
    v_overall jsonb;
    v_result jsonb;
begin
    if v_slug = '' then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select * into v_row
    from public.user_public_profiles
    where lower(slug) = v_slug and is_enabled;

    if v_row.user_id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.profiles where id = v_row.user_id;

    if v_row.fc_account_id is not null then
        select * into v_account
        from public.user_fc_accounts
        where id = v_row.fc_account_id and user_id = v_row.user_id;

        if v_account.id is not null and not v_account.is_active then
            -- Conta arquivada: nunca mostra dado desatualizado como atual.
            -- Autolimpa a selecao para o dono ver "Ativo" corretamente na
            -- propria tela de configuracao.
            update public.user_public_profiles
            set fc_account_id = null
            where user_id = v_row.user_id;
            v_account := null;
        end if;

        if v_account.id is null then
            v_row.fc_account_id := null;
        end if;
    end if;

    v_result := jsonb_build_object(
        'schema_version', 1,
        'found', true,
        'profile', jsonb_build_object(
            'display_name', v_display_name,
            'avatar_url', v_avatar_url
        ),
        'account', null,
        'stats', null,
        'weekend_league', null,
        'rivals', null,
        'squad', null
    );

    if v_account.id is null then
        return v_result;
    end if;

    v_result := jsonb_set(
        v_result, '{account}',
        jsonb_build_object(
            'name', v_account.name,
            'rivals_division', case
                when v_row.show_rivals then v_account.rivals_division
                else null
            end
        )
    );

    if v_row.show_stats then
        v_result := jsonb_set(
            v_result, '{stats}',
            public._fc_account_match_aggregate(v_account.id, null, null)
        );
    end if;

    if v_row.show_rivals then
        select * into v_rivals_manual
        from public.fc_account_rivals_progress
        where fc_account_id = v_account.id;

        v_result := jsonb_set(
            v_result, '{rivals}',
            jsonb_build_object(
                'aggregate', public._fc_account_match_aggregate(
                    v_account.id, 'DIVISION_RIVALS', null
                ),
                'manual', jsonb_build_object(
                    'wins', coalesce(v_rivals_manual.manual_wins, 0),
                    'losses', coalesce(v_rivals_manual.manual_losses, 0)
                )
            )
        );
    end if;

    if v_row.show_weekend_league then
        select id into v_current_event
        from public.weekend_league_events
        where is_active and now() between starts_at and ends_at
        order by starts_at desc
        limit 1;

        if v_current_event is not null then
            select * into v_wl_manual
            from public.fc_account_weekend_league_progress
            where fc_account_id = v_account.id
              and weekend_league_event_id = v_current_event;
        end if;

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
        into v_wl_history
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

        v_result := jsonb_set(
            v_result, '{weekend_league}',
            jsonb_build_object(
                'computed', public._fc_account_match_aggregate(
                    v_account.id, 'WEEKEND_LEAGUE', v_current_event
                ),
                'manual', jsonb_build_object(
                    'wins', coalesce(v_wl_manual.manual_wins, 0),
                    'losses', coalesce(v_wl_manual.manual_losses, 0)
                ),
                'history', coalesce(v_wl_history, '[]'::jsonb)
            )
        );
    end if;

    if v_row.show_squad then
        select * into v_squad
        from public.fc_squads
        where fc_account_id = v_account.id and is_default and is_active
        limit 1;

        if v_squad.id is not null then
            v_chem := public._fc_squad_chemistry(v_squad.id);
            v_overall := public._fc_squad_overall(v_squad.id);

            v_result := jsonb_set(
                v_result, '{squad}',
                jsonb_build_object(
                    'name', v_squad.name,
                    'formation_code', v_squad.formation_code,
                    'formation_display_name', (
                        select f.display_name from public.fc_formations as f
                        where f.code = v_squad.formation_code
                    ),
                    'overall', v_overall -> 'overall',
                    'chemistry', coalesce(v_chem -> 'total', '0'::jsonb),
                    'chemistry_rule_version', public._fc_chemistry_rule_version(),
                    'starters', (
                        select coalesce(jsonb_agg(
                            public._public_squad_card_json(
                                c, (v_chem -> 'per_slot' ->> sl.slot_code)::int
                            ) || jsonb_build_object('slot_code', sl.slot_code)
                            order by sl.slot_code
                        ), '[]'::jsonb)
                        from public.fc_squad_slots as sl
                        join public.fc_player_cards as c on c.id = sl.player_card_id
                        where sl.squad_id = v_squad.id and sl.slot_type = 'STARTING'
                    )
                )
            );
        end if;
    end if;

    return v_result;
end;
$$;

comment on function public.get_public_profile(text) is
    'Payload publico, montado campo a campo -- nunca select *. is_enabled=false e slug inexistente devolvem a mesma resposta (item 29). weekend_league traz manual/computed da semana atual mais history[] das ultimas 15 edicoes. Ver docs/handoff_etapa16.md.';
