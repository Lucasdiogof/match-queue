-- Etapa 16: perfil publico opt-in + compartilhamento da Escalacao Principal.
--
-- Principio central: nada e publico por default, e o Flutter NUNCA decide
-- quais campos esconder de um payload cru -- get_public_profile ja monta o
-- jsonb so com os campos liberados, um a um, nunca um "select *" disfarcado.
-- anon nunca ganha acesso direto a profiles/user_fc_accounts/fc_squads --
-- so execute em get_public_profile.
--
-- Decisao de schema: so SLUG (sem public_id/uuid alternativo). Simplifica
-- sem perder nada essencial -- o slug ja e o link estavel pedido, e caiu a
-- necessidade de manter duas formas de identificador com o mesmo dono.
--
-- Codigos novos: FQ040 slug invalido, FQ041 slug reservado, FQ042 slug em
-- uso, FQ043 habilitar sem slug. FQ025 (conta nao encontrada/nao e dono/
-- inativa) e reaproveitado para a validacao de fc_account_id, mesma semantica
-- ja usada desde a Etapa 9.

create table public.user_public_profiles (
    user_id uuid primary key references auth.users (id) on delete cascade,
    slug text unique,
    is_enabled boolean not null default false,
    fc_account_id uuid references public.user_fc_accounts (id) on delete set null,
    show_squad boolean not null default false,
    show_weekend_league boolean not null default false,
    show_rivals boolean not null default false,
    show_stats boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint user_public_profiles_slug_format
        check (slug is null or slug ~ '^[a-z0-9_]{3,24}$')
);

comment on table public.user_public_profiles is
    'Configuracao de exposicao do perfil publico -- separada de profiles, que e identidade. Linha some em cascata se a conta some (item 79).';
comment on column public.user_public_profiles.slug is
    'Identificador estavel do link publico (/u/:slug). Trocar o slug invalida o link antigo imediatamente -- a proxima leitura ja usa o estado atual da tabela.';
comment on column public.user_public_profiles.fc_account_id is
    'Qual Elenco e mostrado no perfil publico. Trocar aqui NAO muda a rota -- so o conteudo.';

-- Unicidade case-insensitive: "Lucksrei" e "lucksrei" sao o mesmo link.
create unique index user_public_profiles_slug_lower_idx
    on public.user_public_profiles (lower(slug))
    where slug is not null;

alter table public.user_public_profiles enable row level security;

-- Zero policy de proposito: todo acesso passa por RPC security definer,
-- mesmo padrao de game_matches/user_notifications. anon e authenticated nao
-- tem nenhum grant direto na tabela.
revoke all on public.user_public_profiles from public, anon, authenticated;

create trigger user_public_profiles_set_updated_at
    before update on public.user_public_profiles
    for each row execute function public.set_updated_at();

-- Palavras reservadas: nomes de rota existentes ou nomes genéricos que
-- confundiriam com uma rota do proprio app.
create function public._public_profile_reserved_slugs()
returns text[]
language sql
immutable
set search_path = ''
as $$
    select array[
        'admin', 'api', 'auth', 'app', 'settings', 'notifications', 'share',
        'u', 'public', 'login', 'signup', 'onboarding', 'home', 'team',
        'teams', 'history', 'profile', 'join', 'squads', 'match'
    ];
$$;

revoke execute on function public._public_profile_reserved_slugs()
    from public, anon, authenticated;

create function public.check_public_profile_slug_available(p_slug text)
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
              and user_id <> (select auth.uid())
        );
$$;

comment on function public.check_public_profile_slug_available(text) is
    'Validacao em tempo real para o campo de slug na tela de Compartilhamento. So formato+reserva+unicidade -- nao garante que o insert vai passar (corrida rara cai no unique index mesmo assim).';

revoke execute on function public.check_public_profile_slug_available(text)
    from public, anon;
grant execute on function public.check_public_profile_slug_available(text)
    to authenticated;

-- Le a propria configuracao (nunca a de outro usuario -- e por isso que nao
-- e so um select direto: a tabela nao tem select nem para o dono).
create function public.get_my_public_profile_settings()
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
            'show_squad', false,
            'show_weekend_league', false,
            'show_rivals', false,
            'show_stats', false
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

revoke execute on function public.get_my_public_profile_settings()
    from public, anon;
grant execute on function public.get_my_public_profile_settings()
    to authenticated;

-- Upsert da propria configuracao. So o dono altera a propria linha --
-- nenhum parametro de outro usuario e aceito (auth.uid() decide a linha,
-- nunca um p_user_id de entrada).
create function public.update_my_public_profile_settings(
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

    -- Sem slug novo: preserva o que ja existia (troca de outro toggle nao
    -- deve apagar o link).
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
        coalesce(p_show_squad, false), coalesce(p_show_weekend_league, false),
        coalesce(p_show_rivals, false), coalesce(p_show_stats, false)
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

comment on function public.update_my_public_profile_settings(
    boolean, text, uuid, boolean, boolean, boolean, boolean
) is 'Upsert da propria configuracao de perfil publico. Trocar o slug invalida o link antigo na mesma transacao.';

revoke execute on function public.update_my_public_profile_settings(
    boolean, text, uuid, boolean, boolean, boolean, boolean
) from public, anon;
grant execute on function public.update_my_public_profile_settings(
    boolean, text, uuid, boolean, boolean, boolean, boolean
) to authenticated;

-- Serializacao enxuta da carta para o perfil publico: nunca o id interno,
-- nunca PAC/SHO/DRI/DEF/PHY completos -- so o que o card visual precisa.
create function public._public_squad_card_json(
    p_card public.fc_player_cards,
    p_chemistry integer
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
    select jsonb_build_object(
        'player_name', coalesce(p_card.common_name, p_card.player_name),
        'rating', p_card.rating,
        'position', p_card.primary_position,
        'image_url', coalesce(p_card.card_image_url, p_card.player_image_url),
        'card_type', p_card.card_type,
        'chemistry', p_chemistry
    );
$$;

revoke execute on function public._public_squad_card_json(public.fc_player_cards, integer)
    from public, anon, authenticated;

-- Leitura publica. SEM depender de auth -- e a unica funcao desta migration
-- com grant para anon. Sempre devolve o mesmo formato de resposta para
-- "nao existe" e "existe mas is_enabled = false" (item 29): nunca revela que
-- um slug esta desativado.
--
-- Efeito colateral deliberado (por isso a funcao nao e STABLE): se a Conta
-- selecionada foi arquivada, a selecao e limpa automaticamente em
-- user_public_profiles.fc_account_id -- preferencia do dono do produto por
-- invalidar a selecao em vez de esconder em silencio o dado arquivado.
create function public.get_public_profile(p_identifier text)
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
        v_result := jsonb_set(
            v_result, '{rivals}',
            jsonb_build_object(
                'aggregate', public._fc_account_match_aggregate(
                    v_account.id, 'DIVISION_RIVALS', null
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

        v_result := jsonb_set(
            v_result, '{weekend_league}',
            jsonb_build_object(
                'computed', public._fc_account_match_aggregate(
                    v_account.id, 'WEEKEND_LEAGUE', v_current_event
                )
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
                    -- So titulares (item 26): nunca vira jeito de listar o
                    -- catalogo inteiro, nunca mais cards do que os que estao
                    -- de fato no squad. Banco nao entra nesta V1 -- decisao
                    -- consciente para manter o payload publico minimo; o
                    -- card visual mostra so a linha titular.
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
    'Payload publico, montado campo a campo -- nunca select *. is_enabled=false e slug inexistente devolvem a mesma resposta (item 29). Ver docs/handoff_etapa16.md.';

revoke execute on function public.get_public_profile(text) from public;
grant execute on function public.get_public_profile(text) to anon, authenticated;
