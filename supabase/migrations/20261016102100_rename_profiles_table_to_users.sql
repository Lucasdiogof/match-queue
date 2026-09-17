-- =====================================================================
-- Rename public.profiles -> public.users.
--
-- "profiles" era resíduo do conceito de Perfil que já foi eliminado
-- (20261016102000_eliminate_profile_concept.sql): a tabela é 1:1 com
-- auth.users e sempre foi "o usuário", não um Profile reaproveitado.
--
-- ALTER TABLE ... RENAME cuida sozinho de FKs, da tabela em si e do
-- vínculo dos índices/constraints com o novo nome -- mas NÃO reescreve
-- corpo de função plpgsql, e NÃO renomeia constraints/índices/policies/
-- triggers que carregam "profiles" no próprio nome. Por isso o resto
-- desta migration existe: foi montada em cima da saída real do banco
-- (dump_profiles_refs.sql), não da leitura de migrations anteriores.
--
-- Idempotente: cada passo confere o estado atual antes de agir, então
-- pode rodar de novo sem erro se for reaplicada.
-- =====================================================================

-- 1. A tabela ------------------------------------------------------------
alter table if exists public.profiles rename to users;

-- 2. Constraints próprias (pkey, fkey pra auth.users, checks) ------------
-- Renomear a constraint de PK também renomeia o índice que a sustenta
-- (profiles_pkey / index e constraint são o mesmo objeto), por isso o
-- índice "profiles_pkey" do dump não aparece de novo no passo 3.
do $$
begin
    if exists (select 1 from pg_constraint where conname = 'profiles_pkey' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_pkey to users_pkey;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_id_fkey' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_id_fkey to users_id_fkey;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_avatar_url_scheme' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_avatar_url_scheme to users_avatar_url_scheme;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_display_name_length' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_display_name_length to users_display_name_length;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_display_name_not_blank' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_display_name_not_blank to users_display_name_not_blank;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_locale_format' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_locale_format to users_locale_format;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_platforms_valid' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_platforms_valid to users_platforms_valid;
    end if;
    if exists (select 1 from pg_constraint where conname = 'profiles_rivals_division_valid' and conrelid = 'public.users'::regclass) then
        alter table public.users rename constraint profiles_rivals_division_valid to users_rivals_division_valid;
    end if;
end $$;

-- 3. Índice próprio (não ligado a nenhuma constraint) ---------------------
alter index if exists public.profiles_last_active_at_idx rename to users_last_active_at_idx;

-- 4. Policies --------------------------------------------------------------
-- ALTER POLICY só renomeia; USING/WITH CHECK ficam intactos e nenhum dos
-- três cita "profiles" no corpo (conferido no dump: shares_team_with(id),
-- auth.uid() = id) -- então não há nada além do nome pra trocar aqui.
do $$
begin
    if exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'users' and policyname = 'profiles_insert_own') then
        alter policy profiles_insert_own on public.users rename to users_insert_own;
    end if;
    if exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'users' and policyname = 'profiles_select_visible') then
        alter policy profiles_select_visible on public.users rename to users_select_visible;
    end if;
    if exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'users' and policyname = 'profiles_update_own') then
        alter policy profiles_update_own on public.users rename to users_update_own;
    end if;
end $$;

-- 5. Trigger -----------------------------------------------------------------
do $$
begin
    if exists (select 1 from pg_trigger where tgname = 'profiles_set_updated_at' and tgrelid = 'public.users'::regclass) then
        alter trigger profiles_set_updated_at on public.users rename to users_set_updated_at;
    end if;
end $$;

-- 6. As 23 funções cujo corpo cita public.profiles ---------------------------
-- Recriadas por inteiro (CREATE OR REPLACE), com public.profiles trocado por
-- public.users -- texto gerado a partir de pg_get_functiondef() do banco
-- real, não reescrito de memória.

-- _dispatch_finished_weekend_league_notifications()
CREATE OR REPLACE FUNCTION public._dispatch_finished_weekend_league_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_event record;
    v_player record;
    v_team_id uuid;
    v_member record;
    v_count integer := 0;
begin
    for v_event in
        select id, ends_at
        from public.weekend_league_events
        where ends_at < now() and notifications_dispatched_at is null
    loop
        for v_player in
            select wl.user_id,
                   coalesce(wl.manual_wins, 0) as wins,
                   coalesce(wl.manual_losses, 0) as losses,
                   p.display_name
            from public.user_weekend_league_progress as wl
            join public.users as p on p.id = wl.user_id
            where wl.weekend_league_event_id = v_event.id
              and wl.manual_wins is not null
        loop
            for v_team_id in
                select team_id from public.team_members
                where user_id = v_player.user_id
            loop
                for v_member in
                    select tm.user_id
                    from public.team_members as tm
                    where tm.team_id = v_team_id
                      and tm.user_id <> v_player.user_id
                loop
                    perform public._emit_user_notification(
                        v_member.user_id, 'WEEKEND_LEAGUE', 'WEEKEND_LEAGUE_FINISHED',
                        'WEEKEND_LEAGUE_FINISHED:' || v_event.id || ':' || v_player.user_id,
                        'notification_weekend_league_finished',
                        jsonb_build_object(
                            'team_id', v_team_id,
                            'event_id', v_event.id,
                            'user_id', v_player.user_id,
                            'display_name', v_player.display_name,
                            'wins', v_player.wins,
                            'losses', v_player.losses
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
$function$;

-- claim_notification_batch(integer)
CREATE OR REPLACE FUNCTION public.claim_notification_batch(p_limit integer DEFAULT 20)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_ids uuid[];
    v_result jsonb;
begin
    with candidate as (
        select id
        from public.notification_outbox
        where processed_at is null
          and available_at <= now()
          and attempt_count < 5
        order by created_at
        limit greatest(1, least(coalesce(p_limit, 20), 100))
        for update skip locked
    ),
    claimed as (
        update public.notification_outbox o
        set attempt_count = o.attempt_count + 1,
            available_at = now()
                + make_interval(secs => 60 * (o.attempt_count + 1))
        from candidate c
        where o.id = c.id
        returning o.id
    )
    select coalesce(array_agg(id), array[]::uuid[]) into v_ids from claimed;

    if array_length(v_ids, 1) is null then
        return '[]'::jsonb;
    end if;

    update public.notification_outbox o
    set processed_at = now(), last_error = 'suppressed_by_preference'
    where o.id = any(v_ids)
      and o.processed_at is null
      and not public._notification_allowed(o.user_id, o.type);

    update public.notification_outbox o
    set processed_at = now(), last_error = 'no_active_device'
    where o.id = any(v_ids)
      and o.processed_at is null
      and not exists (
          select 1 from public.user_devices d
          where d.user_id = o.user_id and d.is_active
      );

    -- O texto nao vem daqui: o worker resolve PT/EN/ES a partir do type e do
    -- locale. Guardar frase pronta na outbox impediria localizar.
    select coalesce(jsonb_agg(item), '[]'::jsonb) into v_result
    from (
        select jsonb_build_object(
            'id', o.id,
            'type', o.type,
            'team_id', o.team_id,
            'session_id', o.session_id,
            'payload', o.payload,
            'locale', coalesce(p.locale, 'en'),
            'tokens', (
                select coalesce(jsonb_agg(d.fcm_token), '[]'::jsonb)
                from public.user_devices d
                where d.user_id = o.user_id and d.is_active
            )
        ) as item
        from public.notification_outbox o
        join public.users p on p.id = o.user_id
        where o.id = any(v_ids) and o.processed_at is null
        order by o.created_at
    ) as rows;

    return v_result;
end;
$function$;

-- create_team(text,text,integer)
CREATE OR REPLACE FUNCTION public.create_team(p_name text, p_tag text DEFAULT NULL::text, p_default_search_duration_seconds integer DEFAULT 180)
 RETURNS teams
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_name text;
    v_tag text;
    v_duration integer;
    v_team public.teams;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (select 1 from public.users where id = v_user_id) then
        raise exception 'profile is missing for the current user' using errcode = 'FQ006';
    end if;

    v_name := btrim(coalesce(p_name, ''));
    if char_length(v_name) < 2 or char_length(v_name) > 40 then
        raise exception 'team name must have between 2 and 40 characters' using errcode = 'FQ001';
    end if;

    v_tag := nullif(upper(btrim(coalesce(p_tag, ''))), '');
    if v_tag is not null and v_tag !~ '^[A-Z0-9]{2,6}$' then
        raise exception 'team tag must have 2 to 6 letters or digits' using errcode = 'FQ002';
    end if;

    v_duration := coalesce(p_default_search_duration_seconds, 180);
    if v_duration < 30 or v_duration > 600 then
        raise exception 'search duration must be between 30 and 600 seconds' using errcode = 'FQ007';
    end if;

    insert into public.teams (name, tag, default_search_duration_seconds)
    values (v_name, v_tag, v_duration)
    returning * into v_team;

    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_user_id, 'OWNER');

    return v_team;
end;
$function$;

-- get_my_account()
CREATE OR REPLACE FUNCTION public.get_my_account()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_profile public.users;
    v_event public.weekend_league_events;
    v_wl_manual public.user_weekend_league_progress;
    v_rivals_manual public.user_rivals_progress;
    v_team_ids jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_profile from public.users where id = v_user_id;
    v_event := public.get_current_weekend_league_event();

    if v_event.id is not null then
        select * into v_wl_manual
        from public.user_weekend_league_progress
        where user_id = v_user_id and weekend_league_event_id = v_event.id;
    end if;

    select * into v_rivals_manual
    from public.user_rivals_progress where user_id = v_user_id;

    select coalesce(jsonb_agg(team_id), '[]'::jsonb) into v_team_ids
    from public.team_members where user_id = v_user_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'id', v_profile.id,
        'display_name', v_profile.display_name,
        'avatar_url', v_profile.avatar_url,
        'platforms', to_jsonb(v_profile.platforms),
        'rivals_division', v_profile.rivals_division,
        'team_ids', v_team_ids,
        'weekend_league_manual', case when v_wl_manual.user_id is null then null
            else jsonb_build_object('wins', v_wl_manual.manual_wins, 'losses', v_wl_manual.manual_losses)
        end,
        'rivals_manual', jsonb_build_object(
            'wins', coalesce(v_rivals_manual.manual_wins, 0),
            'losses', coalesce(v_rivals_manual.manual_losses, 0)
        ),
        'weekend_league_event', case when v_event.id is null then null else jsonb_build_object(
            'id', v_event.id,
            'number', v_event.number,
            'starts_at', to_jsonb(v_event.starts_at),
            'ends_at', to_jsonb(v_event.ends_at)
        ) end
    );
end;
$function$;

-- get_my_matchmaking_status(uuid,text)
CREATE OR REPLACE FUNCTION public.get_my_matchmaking_status(p_team_id uuid, p_game_mode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_duration integer;
    v_my_session public.match_search_sessions;
    v_my_queue public.match_search_queue;
    v_other_session public.match_search_sessions;
    v_elsewhere_session public.match_search_sessions;
    v_my_state text;
    v_my_position integer;
    v_queue jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select default_search_duration_seconds into v_duration
    from public.teams where id = p_team_id;

    select * into v_my_session
    from public.match_search_sessions
    where team_id = p_team_id and user_id = v_user_id
      and game_mode = p_game_mode and status = 'SEARCHING';

    if v_my_session.id is not null then
        v_my_state := 'SEARCHING';
    else
        select * into v_my_queue
        from public.match_search_queue
        where team_id = p_team_id and user_id = v_user_id
          and game_mode = p_game_mode;

        if v_my_queue.id is not null then
            v_my_state := 'QUEUED';
            select count(*) + 1 into v_my_position
            from public.match_search_queue
            where team_id = p_team_id and game_mode = p_game_mode
              and sequence < v_my_queue.sequence;
        else
            v_my_state := 'NONE';
        end if;

        select * into v_other_session
        from public.match_search_sessions
        where team_id = p_team_id and game_mode = p_game_mode
          and status = 'SEARCHING';

        select * into v_elsewhere_session
        from public.match_search_sessions
        where user_id = v_user_id and status = 'SEARCHING'
          and (team_id <> p_team_id or game_mode <> p_game_mode);
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'position', ranked.position,
            'user_id', ranked.user_id,
            'display_name', ranked.display_name,
            'avatar_url', ranked.avatar_url,
            'game_mode', ranked.game_mode,
            'joined_at', ranked.joined_at,
            'is_me', ranked.user_id = v_user_id
        ) order by ranked.position
    ), '[]'::jsonb)
    into v_queue
    from (
        select
            q.user_id, q.game_mode, q.joined_at,
            p.display_name, p.avatar_url,
            row_number() over (order by q.sequence) as position
        from public.match_search_queue as q
        join public.users as p on p.id = q.user_id
        where q.team_id = p_team_id and q.game_mode = p_game_mode
    ) as ranked;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'user_id', v_user_id,
        'team_id', p_team_id,
        'game_mode', p_game_mode,
        'search_duration_seconds', v_duration,
        'my_state', v_my_state,
        'my_position', v_my_position,
        'searching', case when v_my_session.id is null then null else jsonb_build_object(
            'session_id', v_my_session.id,
            'started_at', to_jsonb(v_my_session.started_at),
            'expires_at', to_jsonb(v_my_session.expires_at),
            'game_mode', v_my_session.game_mode,
            'fc_squad_id', v_my_session.fc_squad_id,
            'fc_squad_name', (
                select name from public.fc_squads where id = v_my_session.fc_squad_id
            )
        ) end,
        'blocking_search', case when v_other_session.id is null then null else jsonb_build_object(
            'user_id', v_other_session.user_id,
            'display_name', (select display_name from public.users where id = v_other_session.user_id),
            'avatar_url', (select avatar_url from public.users where id = v_other_session.user_id),
            'expires_at', to_jsonb(v_other_session.expires_at),
            'game_mode', v_other_session.game_mode
        ) end,
        'searching_elsewhere', case when v_elsewhere_session.id is null then null else jsonb_build_object(
            'team_id', v_elsewhere_session.team_id,
            'team_name', (select name from public.teams where id = v_elsewhere_session.team_id),
            'expires_at', to_jsonb(v_elsewhere_session.expires_at)
        ) end,
        'queue', v_queue
    );
end;
$function$;

-- get_public_profile(text)
CREATE OR REPLACE FUNCTION public.get_public_profile(p_identifier text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_row public.user_public_profiles;
    v_slug text := lower(btrim(coalesce(p_identifier, '')));
    v_display_name text;
    v_avatar_url text;
    v_rivals_division text;
    v_squad public.fc_squads;
    v_current_event uuid;
    v_wl_manual public.user_weekend_league_progress;
    v_rivals_manual public.user_rivals_progress;
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

    select display_name, avatar_url, rivals_division
    into v_display_name, v_avatar_url, v_rivals_division
    from public.users where id = v_row.user_id;

    v_result := jsonb_build_object(
        'schema_version', 1,
        'found', true,
        'profile', jsonb_build_object(
            'display_name', v_display_name,
            'avatar_url', v_avatar_url,
            'rivals_division', case when v_row.show_rivals then v_rivals_division else null end
        ),
        'weekend_league', null,
        'rivals', null,
        'squad', null
    );

    if v_row.show_rivals then
        select * into v_rivals_manual
        from public.user_rivals_progress where user_id = v_row.user_id;

        v_result := jsonb_set(
            v_result, '{rivals}',
            jsonb_build_object(
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
            from public.user_weekend_league_progress
            where user_id = v_row.user_id and weekend_league_event_id = v_current_event;
        end if;

        with recent_events as (
            select e.*
            from public.weekend_league_events as e
            where exists (
                select 1 from public.user_weekend_league_progress as p
                where p.user_id = v_row.user_id and p.weekend_league_event_id = e.id
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
        into v_wl_history
        from recent_events as re
        left join public.user_weekend_league_progress as m
            on m.user_id = v_row.user_id and m.weekend_league_event_id = re.id;

        v_result := jsonb_set(
            v_result, '{weekend_league}',
            jsonb_build_object(
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
        where user_id = v_row.user_id and is_default and is_active
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
$function$;

-- get_public_team(uuid)
CREATE OR REPLACE FUNCTION public.get_public_team(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
    join public.users as p on p.id = tm.user_id
    left join public.user_public_profiles as upp
        on upp.user_id = tm.user_id and upp.is_enabled
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
$function$;

-- get_requests_inbox()
CREATE OR REPLACE FUNCTION public.get_requests_inbox()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_invitations jsonb;
    v_join_requests jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', i.id,
            'team_id', i.team_id,
            'team_name', t.name,
            'team_tag', t.tag,
            'team_logo_url', t.logo_url,
            'member_count', (
                select count(*) from public.team_members m where m.team_id = t.id
            ),
            'created_at', to_jsonb(i.created_at)
        ) order by i.created_at desc
    ), '[]'::jsonb)
    into v_invitations
    from public.team_invitations as i
    join public.teams as t on t.id = i.team_id
    where i.invitee_user_id = v_user_id and i.status = 'PENDING';

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'team_id', r.team_id,
            'team_name', t.name,
            'requester_user_id', r.user_id,
            'requester_display_name', p.display_name,
            'requester_avatar_url', p.avatar_url,
            'created_at', to_jsonb(r.created_at)
        ) order by r.created_at desc
    ), '[]'::jsonb)
    into v_join_requests
    from public.team_join_requests as r
    join public.teams as t on t.id = r.team_id
    join public.users as p on p.id = r.user_id
    where r.status = 'PENDING' and public.is_team_admin(r.team_id);

    return jsonb_build_object(
        'invitations_received', v_invitations,
        'join_requests_to_review', v_join_requests
    );
end;
$function$;

-- get_team_activity_history(uuid,integer,timestamp with time zone,uuid,text,uuid,timestamp with time zone,timestamp with time zone)
CREATE OR REPLACE FUNCTION public.get_team_activity_history(p_team_id uuid, p_limit integer DEFAULT 20, p_cursor_occurred_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_cursor_id uuid DEFAULT NULL::uuid, p_search_status text DEFAULT NULL::text, p_user_id uuid DEFAULT NULL::uuid, p_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
                    round(extract(epoch from (s.finished_at - s.started_at)))::int
            ) as item
        from public.match_search_sessions as s
        left join public.users as p on p.id = s.user_id
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_search_status is null or s.status = p_search_status)
          and (p_user_id is null or s.user_id = p_user_id)
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
$function$;

-- get_team_matchmaking_stats(uuid,timestamp with time zone,timestamp with time zone)
CREATE OR REPLACE FUNCTION public.get_team_matchmaking_stats(p_team_id uuid, p_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_totals jsonb;
    v_players jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    with finished as (
        select
            s.user_id, s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    )
    select jsonb_build_object(
        'total', count(*),
        'match_found', count(*) filter (where status = 'MATCH_FOUND'),
        'cancelled', count(*) filter (where status = 'CANCELLED'),
        'expired', count(*) filter (where status = 'EXPIRED'),
        'success_rate', case
            when count(*) = 0 then null
            else round(
                count(*) filter (where status = 'MATCH_FOUND')::numeric
                    / count(*), 4)
        end,
        'avg_duration_seconds', case
            when count(*) = 0 then null
            else round(avg(duration))::int
        end
    )
    into v_totals
    from finished;

    with finished as (
        select
            s.user_id, s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    ),
    per_player as (
        select
            f.user_id,
            count(*) as total,
            count(*) filter (where f.status = 'MATCH_FOUND') as match_found,
            count(*) filter (where f.status = 'CANCELLED') as cancelled,
            count(*) filter (where f.status = 'EXPIRED') as expired,
            round(
                count(*) filter (where f.status = 'MATCH_FOUND')::numeric
                    / count(*), 4) as success_rate,
            round(avg(f.duration))::int as avg_duration_seconds
        from finished as f
        group by f.user_id
    )
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', pp.user_id,
            'display_name', coalesce(pr.display_name, ''),
            'avatar_url', pr.avatar_url,
            'total', pp.total,
            'match_found', pp.match_found,
            'cancelled', pp.cancelled,
            'expired', pp.expired,
            'success_rate', pp.success_rate,
            'avg_duration_seconds', pp.avg_duration_seconds
        )
        order by pp.total desc, coalesce(pr.display_name, '') asc
    ), '[]'::jsonb)
    into v_players
    from per_player as pp
    left join public.users as pr on pr.id = pp.user_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'from', to_jsonb(p_from),
        'to', to_jsonb(p_to),
        'totals', v_totals,
        'players', v_players
    );
end;
$function$;

-- get_team_member_profile(uuid,uuid)
CREATE OR REPLACE FUNCTION public.get_team_member_profile(p_team_id uuid, p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_caller uuid := (select auth.uid());
    v_display_name text;
    v_avatar_url text;
    v_squad public.fc_squads;
    v_squad_json jsonb;
    v_rivals_division text;
    v_rivals_manual public.user_rivals_progress;
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
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    select display_name, avatar_url, rivals_division
    into v_display_name, v_avatar_url, v_rivals_division
    from public.users
    where id = p_user_id;

    select * into v_squad
    from public.fc_squads
    where user_id = p_user_id and is_default and is_active;

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
    from public.user_rivals_progress
    where user_id = p_user_id;

    with recent_events as (
        select e.*
        from public.weekend_league_events as e
        where exists (
            select 1 from public.user_weekend_league_progress as p
            where p.user_id = p_user_id and p.weekend_league_event_id = e.id
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
    left join public.user_weekend_league_progress as m
        on m.user_id = p_user_id and m.weekend_league_event_id = re.id;

    return jsonb_build_object(
        'user_id', p_user_id,
        'display_name', coalesce(v_display_name, ''),
        'avatar_url', v_avatar_url,
        'rivals_division', v_rivals_division,
        'rivals_wins', coalesce(v_rivals_manual.manual_wins, 0),
        'rivals_losses', coalesce(v_rivals_manual.manual_losses, 0),
        'squad', v_squad_json,
        'weekend_league_history', coalesce(v_wl, '[]'::jsonb)
    );
end;
$function$;

-- get_team_player_statuses(uuid)
CREATE OR REPLACE FUNCTION public.get_team_player_statuses(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_members jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', m.user_id,
            'display_name', coalesce(p.display_name, ''),
            'avatar_url', p.avatar_url,
            'role', m.role,
            'last_active_at', to_jsonb(p.last_active_at),
            'status', case
                when exists (
                    select 1 from public.game_matches g
                    where g.user_id = m.user_id and g.status = 'IN_MATCH'
                ) then 'IN_MATCH'
                when exists (
                    select 1 from public.match_search_sessions s
                    where s.team_id = p_team_id and s.user_id = m.user_id
                      and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    where q.team_id = p_team_id and q.user_id = m.user_id
                ) then 'QUEUED'
                when p.last_active_at is not null
                    and p.last_active_at >= now() - interval '60 minutes'
                    then 'RECENTLY_ACTIVE'
                else 'OFFLINE'
            end,
            'queue_position', (
                select row_number() over (order by q.sequence)
                from public.match_search_queue as q
                where q.team_id = p_team_id and q.user_id = m.user_id
            )
        )
        order by
            case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end,
            coalesce(p.display_name, '')
    ), '[]'::jsonb)
    into v_members
    from public.team_members as m
    join public.users as p on p.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'members', v_members
    );
end;
$function$;

-- get_team_sent_invitations(uuid)
CREATE OR REPLACE FUNCTION public.get_team_sent_invitations(p_team_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    return coalesce((
        select jsonb_agg(
            jsonb_build_object(
                'id', i.id,
                'invitee_user_id', i.invitee_user_id,
                'invitee_display_name', p.display_name,
                'invitee_avatar_url', p.avatar_url,
                'created_at', to_jsonb(i.created_at)
            ) order by i.created_at desc
        )
        from public.team_invitations as i
        join public.users as p on p.id = i.invitee_user_id
        where i.team_id = p_team_id and i.status = 'PENDING'
    ), '[]'::jsonb);
end;
$function$;

-- handle_new_user()
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    candidate text;
begin
    candidate := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));

    if candidate = '' then
        candidate := btrim(coalesce(new.raw_user_meta_data ->> 'name', ''));
    end if;

    if candidate = '' then
        candidate := btrim(split_part(coalesce(new.email, ''), '@', 1));
    end if;

    candidate := left(candidate, 32);

    if char_length(candidate) < 2 then
        candidate := 'Jogador';
    end if;

    insert into public.users (id, display_name)
    values (new.id, candidate)
    on conflict (id) do nothing;

    insert into public.notification_preferences (user_id)
    values (new.id)
    on conflict (user_id) do nothing;

    return new;
exception
    when others then
        raise warning 'handle_new_user falhou para % (%): %',
            new.id, sqlstate, sqlerrm;
        return new;
end;
$function$;

-- invite_team_member(uuid,text)
CREATE OR REPLACE FUNCTION public.invite_team_member(p_team_id uuid, p_slug text)
 RETURNS team_invitations
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_actor_id uuid := (select auth.uid());
    v_input text := lower(btrim(coalesce(p_slug, '')));
    v_target public.user_public_profiles;
    v_row public.team_invitations;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select * into v_target
    from public.user_public_profiles
    where lower(slug) = v_input and is_enabled;

    if v_target.user_id is null then
        begin
            select upp.* into strict v_target
            from public.user_public_profiles upp
            join public.users p on p.id = upp.user_id
            where lower(p.display_name) = v_input
              and upp.is_enabled;
        exception
            when no_data_found or too_many_rows then
                null;
        end;
    end if;

    if v_target.user_id is null then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;

    if v_target.user_id = v_actor_id then
        raise exception 'invite target not found' using errcode = 'FQ057';
    end if;

    if exists (
        select 1 from public.team_members
        where team_id = p_team_id and user_id = v_target.user_id
    ) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_invitations
        where team_id = p_team_id
          and invitee_user_id = v_target.user_id
          and status = 'PENDING'
    ) then
        raise exception 'duplicate invitation' using errcode = 'FQ055';
    end if;

    insert into public.team_invitations (team_id, inviter_id, invitee_user_id)
    values (p_team_id, v_actor_id, v_target.user_id)
    returning * into v_row;

    return v_row;
end;
$function$;

-- join_team_by_invite(text)
CREATE OR REPLACE FUNCTION public.join_team_by_invite(p_code text)
 RETURNS TABLE(already_member boolean, team_id uuid, team_name text, team_tag text, role text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_link
    from public.team_invite_links
    where code = v_code
    for update;

    if v_link.id is null then
        raise exception 'invite not found' using errcode = 'FQ008';
    end if;

    if not v_link.is_active then
        raise exception 'invite is not active' using errcode = 'FQ009';
    end if;

    if v_link.expires_at is not null and v_link.expires_at < now() then
        raise exception 'invite has expired' using errcode = 'FQ010';
    end if;

    if v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        raise exception 'invite has been exhausted' using errcode = 'FQ011';
    end if;

    select * into v_existing
    from public.team_members as tm
    where tm.team_id = v_link.team_id and tm.user_id = v_user_id;

    if v_existing.team_id is not null then
        select * into v_team from public.teams where id = v_link.team_id;
        return query select true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
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
        return query select true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end;

    update public.team_invite_links
    set usage_count = usage_count + 1
    where id = v_link.id;

    select * into v_team from public.teams where id = v_link.team_id;
    select display_name into v_joiner_name from public.users where id = v_user_id;

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

    return query select false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$function$;

-- request_match_search(uuid,uuid,text)
CREATE OR REPLACE FUNCTION public.request_match_search(p_team_id uuid, p_fc_squad_id uuid, p_game_mode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_is_active boolean;
    v_already_session public.match_search_sessions;
    v_already_queue public.match_search_queue;
    v_queue_count integer;
    v_new_session public.match_search_sessions;
    v_new_queue public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_game_mode is null
        or p_game_mode not in ('WEEKEND_LEAGUE', 'DIVISION_RIVALS')
    then
        raise exception 'invalid game mode' using errcode = 'FQ023';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    -- Plataforma e obrigatoria pra entrar na fila: o mesmo FQ058 que
    -- update_my_platforms usa, para o app nao depender so da checagem local.
    if not exists (
        select 1 from public.users
        where id = v_user_id and coalesce(array_length(platforms, 1), 0) > 0
    ) then
        raise exception 'at least one platform is required' using errcode = 'FQ058';
    end if;

    if p_fc_squad_id is not null and not exists (
        select 1 from public.fc_squads
        where id = p_fc_squad_id and user_id = v_user_id and is_active
    ) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select is_active into v_is_active from public.teams where id = p_team_id;
    if v_is_active is not true then
        raise exception 'team is not active' using errcode = 'FQ018';
    end if;

    perform public._lock_team_matchmaking(p_team_id);
    perform public._lock_user_matchmaking(v_user_id);
    perform public._expire_team_search_if_needed(p_team_id);

    select * into v_already_session
    from public.match_search_sessions
    where team_id = p_team_id and user_id = v_user_id
      and game_mode = p_game_mode and status = 'SEARCHING';
    if v_already_session.id is not null then
        return public.get_my_matchmaking_status(p_team_id, p_game_mode);
    end if;

    select * into v_already_queue
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id
      and game_mode = p_game_mode;
    if v_already_queue.id is not null then
        return public.get_my_matchmaking_status(p_team_id, p_game_mode);
    end if;

    if exists (
        select 1 from public.game_matches
        where user_id = v_user_id and game_mode = p_game_mode
          and started_at > now() - interval '30 seconds'
    ) then
        raise exception 'search cooldown active' using errcode = 'FQ020';
    end if;

    select count(*) into v_queue_count
    from public.match_search_queue
    where team_id = p_team_id and game_mode = p_game_mode;

    if v_queue_count = 0
        and public._team_free_for_search(p_team_id, p_game_mode)
        and not public._user_globally_searching(v_user_id)
    then
        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_squad_id)
        select
            p_team_id, v_user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            p_game_mode, p_fc_squad_id
        from public.teams as t
        where t.id = p_team_id
        returning * into v_new_session;
    else
        insert into public.match_search_queue
            (team_id, user_id, game_mode, fc_squad_id)
        values (p_team_id, v_user_id, p_game_mode, p_fc_squad_id)
        returning * into v_new_queue;
    end if;

    perform public._notify_matchmaking_changed(p_team_id);
    return public.get_my_matchmaking_status(p_team_id, p_game_mode);
end;
$function$;

-- request_match_search_priority(uuid,text)
CREATE OR REPLACE FUNCTION public.request_match_search_priority(p_team_id uuid, p_game_mode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_requester_name text;
    v_team_name text;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select * into v_searching
    from public.match_search_sessions
    where team_id = p_team_id and game_mode = p_game_mode and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search to prioritize' using errcode = 'FQ048';
    end if;

    select display_name into v_requester_name
    from public.users where id = v_user_id;
    select name into v_team_name from public.teams where id = p_team_id;

    perform public._enqueue_notification(
        v_searching.user_id,
        'PRIORITY_REQUESTED',
        p_team_id,
        v_searching.id,
        jsonb_build_object(
            'requested_by_display_name', v_requester_name,
            'team_name', v_team_name
        ),
        'PRIORITY_REQUESTED:' || v_searching.id::text || ':' || v_user_id::text
    );

    return jsonb_build_object('server_now', to_jsonb(now()), 'requested', true);
end;
$function$;

-- request_team_join(uuid)
CREATE OR REPLACE FUNCTION public.request_team_join(p_team_id uuid)
 RETURNS team_join_requests
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_requester_name text;
    v_team_name text;
    v_admin record;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select name into v_team_name from public.teams where id = p_team_id;
    if v_team_name is null then
        raise exception 'team not found' using errcode = 'FQ053';
    end if;

    if public.is_team_member(p_team_id) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_join_requests
        where team_id = p_team_id and user_id = v_user_id and status = 'PENDING'
    ) then
        raise exception 'a pending request already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_join_requests (team_id, user_id)
    values (p_team_id, v_user_id)
    returning * into v_row;

    perform public._notify_team_admins_requests_changed(p_team_id);

    select display_name into v_requester_name
    from public.users where id = v_user_id;

    for v_admin in
        select user_id from public.team_members
        where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._emit_user_notification(
            v_admin.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_RECEIVED',
            'TEAM_JOIN_REQUEST_RECEIVED:' || v_row.id || ':' || v_admin.user_id,
            'notification_team_join_request_received',
            jsonb_build_object(
                'team_id', p_team_id,
                'requester_display_name', coalesce(v_requester_name, ''),
                'team_name', v_team_name
            ),
            'requests', jsonb_build_object('team_id', p_team_id)
        );
    end loop;

    return v_row;
end;
$function$;

-- resolve_invite_target(text)
CREATE OR REPLACE FUNCTION public.resolve_invite_target(p_slug text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_input text := lower(btrim(coalesce(p_slug, '')));
    v_row public.user_public_profiles;
    v_display_name text;
    v_avatar_url text;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if v_input = '' then
        return jsonb_build_object('found', false);
    end if;

    select * into v_row
    from public.user_public_profiles
    where lower(slug) = v_input and is_enabled;

    if v_row.user_id is null then
        begin
            select upp.* into strict v_row
            from public.user_public_profiles upp
            join public.users p on p.id = upp.user_id
            where lower(p.display_name) = v_input
              and upp.is_enabled;
        exception
            when no_data_found or too_many_rows then
                null;
        end;
    end if;

    if v_row.user_id is null then
        return jsonb_build_object('found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.users where id = v_row.user_id;

    return jsonb_build_object(
        'found', true,
        'user_id', v_row.user_id,
        'display_name', v_display_name,
        'avatar_url', v_avatar_url
    );
end;
$function$;

-- respond_team_invitation(uuid,boolean)
CREATE OR REPLACE FUNCTION public.respond_team_invitation(p_invitation_id uuid, p_accept boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_invitations;
    v_team_name text;
    v_display_name text;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_invitations
    where id = p_invitation_id
      and invitee_user_id = v_user_id
      and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'invitation not found' using errcode = 'FQ056';
    end if;

    if not p_accept then
        update public.team_invitations
        set status = 'REJECTED', resolved_at = now(), resolved_by = v_user_id
        where id = p_invitation_id;
        return;
    end if;

    if not exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and user_id = v_user_id
    ) then
        insert into public.team_members (team_id, user_id, role)
        values (v_row.team_id, v_user_id, 'PLAYER');
    end if;

    update public.team_invitations
    set status = 'ACCEPTED', resolved_at = now(), resolved_by = v_user_id
    where id = p_invitation_id;

    select name into v_team_name from public.teams where id = v_row.team_id;
    select display_name into v_display_name from public.users where id = v_user_id;

    perform public._emit_user_notification(
        v_row.inviter_id, 'TEAMS', 'TEAM_INVITATION_ACCEPTED',
        'TEAM_INVITATION_ACCEPTED:' || v_row.id,
        'notification_team_invitation_accepted',
        jsonb_build_object(
            'team_id', v_row.team_id,
            'team_name', v_team_name,
            'display_name', coalesce(v_display_name, '')
        ),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$function$;

-- update_my_platforms(text[])
CREATE OR REPLACE FUNCTION public.update_my_platforms(p_platforms text[])
 RETURNS text[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_clean text[];
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(array_agg(distinct p order by p), array[]::text[]) into v_clean
    from unnest(p_platforms) as p
    where p in ('PC', 'PS', 'XBOX');

    if array_length(v_clean, 1) is null then
        raise exception 'at least one platform is required' using errcode = 'FQ058';
    end if;

    update public.users set platforms = v_clean where id = v_user_id;

    return v_clean;
end;
$function$;

-- update_my_rivals_division(text)
CREATE OR REPLACE FUNCTION public.update_my_rivals_division(p_division text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    v_user_id uuid := (select auth.uid());
    v_old_division text;
    v_display_name text;
    v_team_id uuid;
    v_member record;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select rivals_division, display_name into v_old_division, v_display_name
    from public.users where id = v_user_id;

    update public.users set rivals_division = p_division where id = v_user_id;

    -- Mesma regra de antes do fim do conceito de Perfil: subir de divisao
    -- avisa os OUTROS membros de cada time do usuario. So mudou de onde sai
    -- a lista de times (team_members, nao mais fc_account_teams).
    if p_division is not null and p_division is distinct from v_old_division then
        for v_team_id in
            select team_id from public.team_members where user_id = v_user_id
        loop
            for v_member in
                select tm.user_id
                from public.team_members as tm
                where tm.team_id = v_team_id and tm.user_id <> v_user_id
            loop
                perform public._emit_user_notification(
                    v_member.user_id, 'RIVALS', 'RIVALS_DIVISION_CHANGED',
                    'RIVALS_DIVISION_CHANGED:' || v_team_id || ':' || v_user_id
                        || ':' || p_division,
                    'notification_rivals_division_changed',
                    jsonb_build_object(
                        'team_id', v_team_id,
                        'user_id', v_user_id,
                        'display_name', v_display_name,
                        'division', p_division
                    ),
                    'team_rivals', jsonb_build_object('team_id', v_team_id),
                    'user', v_user_id
                );
            end loop;
        end loop;
    end if;

    return p_division;
end;
$function$;
