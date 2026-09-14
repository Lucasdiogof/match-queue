-- Perfil publico passa a ser POR CONTA FC, nao por usuario.
--
-- Ate aqui existia uma linha so por usuario (user_id primary key), com
-- fc_account_id sendo so um PONTEIRO pra "qual conta esse unico perfil
-- mostra agora". Um usuario com duas contas via os toggles/slug de uma
-- conta mudarem o mesmo perfil que a outra conta tambem usava -- pedido
-- explicito do dono do produto pra cada conta ter seu proprio link, slug e
-- toggles, totalmente independentes.
--
-- Backfill: linha sem fc_account_id pega a primeira conta ativa do dono; sem
-- conta nenhuma pra vincular, a linha e apagada (perfil publico sem conta
-- deixa de fazer sentido -- ele sempre mostrou dado de UMA conta).
update public.user_public_profiles as upp
set fc_account_id = (
    select a.id from public.user_fc_accounts as a
    where a.user_id = upp.user_id and a.is_active
    order by a.created_at
    limit 1
)
where upp.fc_account_id is null;

delete from public.user_public_profiles where fc_account_id is null;

alter table public.user_public_profiles drop constraint user_public_profiles_pkey;
alter table public.user_public_profiles alter column fc_account_id set not null;
alter table public.user_public_profiles add primary key (fc_account_id);

alter table public.user_public_profiles
    drop constraint user_public_profiles_fc_account_id_fkey;
alter table public.user_public_profiles
    add constraint user_public_profiles_fc_account_id_fkey
    foreign key (fc_account_id) references public.user_fc_accounts (id)
    on delete cascade;

comment on table public.user_public_profiles is
    'Configuracao de exposicao do perfil publico de UMA CONTA FC (chave e fc_account_id, nao user_id -- cada conta tem seu proprio link/slug/toggles). Linha some em cascata se a conta ou o usuario somem.';
comment on column public.user_public_profiles.fc_account_id is
    'Dona da linha: qual Conta FC este perfil publico e sobre. Nao muda depois de criado -- trocar de conta e trocar de linha, nao editar o ponteiro.';

-- ---------------------------------------------------------------------
-- check_public_profile_slug_available: exclusao agora e por CONTA, nao por
-- usuario -- outra conta do mesmo dono tambem nao pode reusar o slug (ele
-- e globalmente unico), so a propria conta pode manter o slug que ja tinha.
-- ---------------------------------------------------------------------
drop function if exists public.check_public_profile_slug_available(text);

create function public.check_public_profile_slug_available(
    p_slug text,
    p_fc_account_id uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select
        lower(btrim(p_slug)) ~ '^[a-z0-9_]{3,24}$'
        and not (lower(btrim(p_slug)) = any (public._public_profile_reserved_slugs()))
        and not exists (
            select 1 from public.user_public_profiles
            where lower(slug) = lower(btrim(p_slug))
              and (p_fc_account_id is null or fc_account_id <> p_fc_account_id)
        );
$$;

comment on function public.check_public_profile_slug_available(text, uuid) is
    'Validacao em tempo real do slug. p_fc_account_id exclui a PROPRIA conta da checagem de unicidade (ela pode manter o slug que ja tinha).';

revoke execute on function public.check_public_profile_slug_available(text, uuid)
    from public, anon;
grant execute on function public.check_public_profile_slug_available(text, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- get_my_public_profile_settings: agora escopado por conta.
-- ---------------------------------------------------------------------
drop function if exists public.get_my_public_profile_settings();

create function public.get_my_public_profile_settings(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.user_public_profiles;
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

    select * into v_row from public.user_public_profiles
    where fc_account_id = p_fc_account_id;

    if v_row.fc_account_id is null then
        return jsonb_build_object(
            'is_enabled', false,
            'slug', null,
            'fc_account_id', p_fc_account_id,
            'show_squad', true,
            'show_weekend_league', true,
            'show_rivals', true,
            'show_stats', true
        );
    end if;

    return jsonb_build_object(
        'is_enabled', v_row.is_enabled,
        'slug', v_row.slug,
        'fc_account_id', v_row.fc_account_id,
        'show_squad', v_row.show_squad,
        'show_weekend_league', v_row.show_weekend_league,
        'show_rivals', v_row.show_rivals,
        'show_stats', v_row.show_stats
    );
end;
$$;

comment on function public.get_my_public_profile_settings(uuid) is
    'Le a config de perfil publico da CONTA informada (precisa ser dona). Sem linha ainda: devolve default desativado com os 4 toggles ja ligados (item de privacidade default-on).';

revoke execute on function public.get_my_public_profile_settings(uuid)
    from public, anon;
grant execute on function public.get_my_public_profile_settings(uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- update_my_public_profile_settings: p_fc_account_id agora e a CHAVE da
-- linha (dona fixa), nao mais um valor que muda pra apontar pra outra
-- conta -- por isso sai do payload de "campos que mudam" e vira o primeiro
-- parametro, sempre obrigatorio.
-- ---------------------------------------------------------------------
drop function if exists public.update_my_public_profile_settings(
    boolean, text, uuid, boolean, boolean, boolean, boolean
);

create function public.update_my_public_profile_settings(
    p_fc_account_id uuid,
    p_is_enabled boolean,
    p_slug text,
    p_show_squad boolean,
    p_show_weekend_league boolean,
    p_show_rivals boolean,
    p_show_stats boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_slug text := nullif(lower(btrim(coalesce(p_slug, ''))), '');
    v_is_enabled boolean := coalesce(p_is_enabled, false);
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

    if v_slug is not null then
        if v_slug !~ '^[a-z0-9_]{3,24}$' then
            raise exception 'invalid slug format' using errcode = 'FQ040';
        end if;

        if v_slug = any (public._public_profile_reserved_slugs()) then
            raise exception 'reserved slug' using errcode = 'FQ041';
        end if;

        if exists (
            select 1 from public.user_public_profiles
            where lower(slug) = v_slug and fc_account_id <> p_fc_account_id
        ) then
            raise exception 'slug already taken' using errcode = 'FQ042';
        end if;
    end if;

    -- Sem slug novo: preserva o que essa CONTA ja tinha (troca de outro
    -- toggle nao deve apagar o link dela).
    if v_slug is null then
        select slug into v_slug
        from public.user_public_profiles where fc_account_id = p_fc_account_id;
    end if;

    if v_is_enabled and v_slug is null then
        raise exception 'public profile requires a slug to be enabled'
            using errcode = 'FQ043';
    end if;

    insert into public.user_public_profiles (
        user_id, fc_account_id, slug, is_enabled,
        show_squad, show_weekend_league, show_rivals, show_stats
    ) values (
        v_user_id, p_fc_account_id, v_slug, v_is_enabled,
        coalesce(p_show_squad, true), coalesce(p_show_weekend_league, true),
        coalesce(p_show_rivals, true), coalesce(p_show_stats, true)
    )
    on conflict (fc_account_id) do update set
        slug = excluded.slug,
        is_enabled = excluded.is_enabled,
        show_squad = excluded.show_squad,
        show_weekend_league = excluded.show_weekend_league,
        show_rivals = excluded.show_rivals,
        show_stats = excluded.show_stats,
        updated_at = now();

    return public.get_my_public_profile_settings(p_fc_account_id);
end;
$$;

comment on function public.update_my_public_profile_settings(
    uuid, boolean, text, boolean, boolean, boolean, boolean
) is 'Upsert do perfil publico de UMA conta (p_fc_account_id fixa qual). Trocar o slug invalida o link antigo dessa conta na mesma transacao.';

revoke execute on function public.update_my_public_profile_settings(
    uuid, boolean, text, boolean, boolean, boolean, boolean
) from public, anon;
grant execute on function public.update_my_public_profile_settings(
    uuid, boolean, text, boolean, boolean, boolean, boolean
) to authenticated;

-- ---------------------------------------------------------------------
-- get_public_profile: fc_account_id agora e inerente a linha encontrada
-- pelo slug -- sem mais o ramo de "conta arquivada limpa o ponteiro"
-- (nao ha ponteiro pra limpar; se a conta some, a linha some junto por
-- ON DELETE CASCADE). Se a conta ficar so inativa (nao deletada), o
-- perfil so para de aparecer -- mesma postura de "nunca revela estado
-- interno" do resto da funcao.
-- ---------------------------------------------------------------------
drop function if exists public.get_public_profile(text);

create function public.get_public_profile(p_identifier text)
returns jsonb
language plpgsql
stable
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

    if v_row.fc_account_id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select * into v_account
    from public.user_fc_accounts
    where id = v_row.fc_account_id and is_active;

    if v_account.id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    select display_name, avatar_url into v_display_name, v_avatar_url
    from public.profiles where id = v_row.user_id;

    v_result := jsonb_build_object(
        'schema_version', 1,
        'found', true,
        'profile', jsonb_build_object(
            'display_name', v_display_name,
            'avatar_url', v_avatar_url
        ),
        'account', jsonb_build_object(
            'name', v_account.name,
            'rivals_division', case
                when v_row.show_rivals then v_account.rivals_division
                else null
            end
        ),
        'stats', null,
        'weekend_league', null,
        'rivals', null,
        'squad', null
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
    'Payload publico de UMA CONTA (a linha e por conta desde esta migration). is_enabled=false, slug inexistente ou conta inativa devolvem a mesma resposta -- nunca revela qual dos tres foi.';

revoke execute on function public.get_public_profile(text) from public;
grant execute on function public.get_public_profile(text) to anon, authenticated;

-- ---------------------------------------------------------------------
-- get_public_team: uma conta podia ter mais de um perfil publico
-- habilitado por usuario antes (nunca mais de um POR CONTA, mas um
-- usuario com duas contas tem duas linhas agora) -- o join simples
-- duplicaria o membro no roster. Prefere a linha cuja conta esta
-- vinculada a ESTE time; sem nenhuma vinculada, pega a mais recente.
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
    v_record jsonb;
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

    select jsonb_build_object(
        'wins', count(*) filter (where gm.result = 'WIN'),
        'losses', count(*) filter (where gm.result = 'LOSS'),
        'goals_for', coalesce(sum(gm.goals_for), 0),
        'goals_against', coalesce(sum(gm.goals_against), 0)
    )
    into v_record
    from public.game_matches as gm
    where gm.team_id = v_team.id and gm.status = 'FINISHED';

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
        'members', v_members,
        'record', v_record
    );
end;
$$;
