-- Busca do catalogo (o que o Player Picker e o Manager Picker consomem) e
-- exposicao do squad no pending match / historico.
--
-- Estas assinaturas sao o CONTRATO que a Etapa 11 precisa cumprir. Trocar a
-- fonte dos dados nao deve exigir mexer na UI: quem muda e quem POPULA
-- fc_player_cards / fc_managers, nunca quem le.

-- Cartas elegiveis para uma posicao. p_position null = sem filtro (o picker
-- filtra pela posicao do slot por padrao, item 43).
create function public.search_fc_player_cards(
    p_query text default null,
    p_position text default null,
    p_limit integer default 30,
    p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 30), 100));
    v_offset integer := greatest(0, coalesce(p_offset, 0));
    v_query text := nullif(btrim(coalesce(p_query, '')), '');
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return jsonb_build_object(
        'items', (
            select coalesce(jsonb_agg(item order by ord), '[]'::jsonb)
            from (
                select
                    row_number() over (
                        order by c.rating desc, c.player_name
                    ) as ord,
                    public._fc_card_json(c) as item
                from public.fc_player_cards as c
                where (
                        p_position is null
                        or c.primary_position = p_position
                        or p_position = any(c.alternative_positions)
                      )
                  and (
                        v_query is null
                        or c.player_name ilike '%' || v_query || '%'
                        or coalesce(c.common_name, '') ilike '%' || v_query || '%'
                      )
                order by c.rating desc, c.player_name
                limit v_limit offset v_offset
            ) as page
        ),
        'has_more', (
            select count(*) > v_offset + v_limit
            from public.fc_player_cards as c
            where (
                    p_position is null
                    or c.primary_position = p_position
                    or p_position = any(c.alternative_positions)
                  )
              and (
                    v_query is null
                    or c.player_name ilike '%' || v_query || '%'
                    or coalesce(c.common_name, '') ilike '%' || v_query || '%'
                  )
        )
    );
end;
$$;

revoke execute on function
    public.search_fc_player_cards(text, text, integer, integer)
    from public, anon;
grant execute on function
    public.search_fc_player_cards(text, text, integer, integer)
    to authenticated;

-- O fluxo do tecnico e pais -> tecnico -> liga (item 47), entao a busca e
-- sempre filtrada por nacao.
create function public.search_fc_managers(
    p_nation_id uuid default null,
    p_query text default null,
    p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
    v_query text := nullif(btrim(coalesce(p_query, '')), '');
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return (
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'id', m.id,
                'name', m.name,
                'image_url', m.image_url,
                'nation', case when n.id is null then null else jsonb_build_object(
                    'id', n.id, 'name', n.name,
                    'flag_image_url', n.flag_image_url
                ) end
            ) order by m.name
        ), '[]'::jsonb)
        from (
            select * from public.fc_managers
            where (p_nation_id is null or nation_id = p_nation_id)
              and (v_query is null or name ilike '%' || v_query || '%')
            order by name
            limit v_limit
        ) as m
        left join public.fc_nations as n on n.id = m.nation_id
    );
end;
$$;

revoke execute on function public.search_fc_managers(uuid, text, integer)
    from public, anon;
grant execute on function public.search_fc_managers(uuid, text, integer)
    to authenticated;

-- Pending match passa a carregar o squad usado. Le do SNAPSHOT, nao do squad
-- vivo: se o usuario editar o squad enquanto a partida corre, o card tem de
-- continuar mostrando com o que ele entrou em campo.
create or replace function public.get_pending_game_match()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
    v_event public.weekend_league_events;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._expire_stale_game_matches(v_user_id);

    select * into v_match
    from public.game_matches
    where user_id = v_user_id and status = 'IN_MATCH'
    order by started_at desc
    limit 1;

    if v_match.id is null then
        return jsonb_build_object('server_now', to_jsonb(now()), 'match', null);
    end if;

    if v_match.weekend_league_event_id is not null then
        select * into v_event from public.weekend_league_events
        where id = v_match.weekend_league_event_id;
    end if;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'match', jsonb_build_object(
            'id', v_match.id,
            'team_id', v_match.team_id,
            'game_mode', v_match.game_mode,
            'status', v_match.status,
            'started_at', to_jsonb(v_match.started_at),
            'weekend_league_event_id', v_match.weekend_league_event_id,
            'weekend_league_number', v_event.number,
            'fc_account_id', v_match.fc_account_id,
            'fc_account_name', (
                select name from public.user_fc_accounts
                where id = v_match.fc_account_id
            ),
            'fc_squad_id', v_match.fc_squad_id,
            'fc_squad_name', v_match.squad_snapshot ->> 'name',
            'fc_formation_code', v_match.squad_snapshot ->> 'formation'
        )
    );
end;
$$;

revoke execute on function public.get_pending_game_match() from public, anon;
grant execute on function public.get_pending_game_match() to authenticated;
