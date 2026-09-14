-- Os quatro toggles de conteudo (show_squad/show_weekend_league/show_rivals/
-- show_stats) passam a nascer ativados. `is_enabled` continua false por
-- padrao (ligar o perfil publico exige um slug, entao continua sendo uma
-- acao explicita) -- so o que aparece DEPOIS de habilitado vem tudo marcado,
-- em vez do usuario precisar ligar categoria por categoria.

alter table public.user_public_profiles
    alter column show_squad set default true,
    alter column show_weekend_league set default true,
    alter column show_rivals set default true,
    alter column show_stats set default true;

create or replace function public.get_my_public_profile_settings()
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

    select * into v_row from public.user_public_profiles where user_id = v_user_id;

    if v_row.user_id is null then
        return jsonb_build_object(
            'is_enabled', false,
            'slug', null,
            'fc_account_id', null,
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

create or replace function public.update_my_public_profile_settings(
    p_is_enabled boolean,
    p_slug text,
    p_fc_account_id uuid,
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

    if v_slug is not null then
        if v_slug !~ '^[a-z0-9_]{3,24}$' then
            raise exception 'invalid slug format' using errcode = 'FQ040';
        end if;

        if v_slug = any (public._public_profile_reserved_slugs()) then
            raise exception 'reserved slug' using errcode = 'FQ041';
        end if;

        if exists (
            select 1 from public.user_public_profiles
            where lower(slug) = v_slug and user_id <> v_user_id
        ) then
            raise exception 'slug already taken' using errcode = 'FQ042';
        end if;
    end if;

    if v_slug is null then
        select slug into v_slug
        from public.user_public_profiles where user_id = v_user_id;
    end if;

    if v_is_enabled and v_slug is null then
        raise exception 'public profile requires a slug to be enabled'
            using errcode = 'FQ043';
    end if;

    if p_fc_account_id is not null and not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    insert into public.user_public_profiles (
        user_id, slug, is_enabled, fc_account_id,
        show_squad, show_weekend_league, show_rivals, show_stats
    ) values (
        v_user_id, v_slug, v_is_enabled, p_fc_account_id,
        coalesce(p_show_squad, true), coalesce(p_show_weekend_league, true),
        coalesce(p_show_rivals, true), coalesce(p_show_stats, true)
    )
    on conflict (user_id) do update set
        slug = excluded.slug,
        is_enabled = excluded.is_enabled,
        fc_account_id = excluded.fc_account_id,
        show_squad = excluded.show_squad,
        show_weekend_league = excluded.show_weekend_league,
        show_rivals = excluded.show_rivals,
        show_stats = excluded.show_stats,
        updated_at = now();

    return public.get_my_public_profile_settings();
end;
$$;
