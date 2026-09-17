-- Elimina por completo a camada "Elenco"/"Conta FC" (user_fc_accounts), o
-- "Profile" do dominio Flutter. Novo modelo: 1 conta autenticada (auth.users)
-- = 1 usuario do Match Queue. Tudo pertence direto a auth.users.id
-- (via public.profiles.id, que ja e 1:1 com auth.users).
--
-- Sem usuarios reais em producao ainda -- dono do produto autorizou reset
-- completo dos dados de desenvolvimento em vez de uma migracao de dados
-- complexa. Por isso este arquivo comeca truncando tudo que dependia da
-- identidade antiga, e so depois faz os ALTERs de schema (mais simples e
-- seguros em tabelas vazias).
--
-- O que sai: user_fc_accounts, fc_account_teams (redundante com
-- team_members agora), platform como valor unico, "trocar de perfil",
-- qualquer RPC que recebesse p_fc_account_id.
--
-- O que fica, so re-chaveado por user_id: fc_squads (1 por usuario, ja era
-- de fato assim), fc_account_weekend_league_progress ->
-- user_weekend_league_progress, fc_account_rivals_progress ->
-- user_rivals_progress, user_public_profiles (volta a ser 1 por usuario),
-- team_members (volta a PK (team_id, user_id), que ja e como
-- is_team_member/is_team_admin/is_team_owner/shares_team_with sempre
-- leram -- essas 4 funcoes nao mudam nesta migration).
--
-- platform vira platforms text[] em profiles (multi-select, minimo 1 depois
-- do onboarding -- validado no RPC, nao por CHECK, porque uma conta nova
-- nasce com array vazio antes do onboarding terminar).
-- rivals_division tambem migra pra profiles.

-- =======================================================================
-- 0a. IDEMPOTENCIA: derruba TODA sobrecarga, por NOME, de cada funcao que
--     esta migration recria OU remove -- antes de qualquer outra coisa.
--
--     Por que por nome e nao por assinatura: o historico deste schema tem
--     varios `create or replace` que mudaram a lista de parametros -- o que
--     nao substitui, cria sobrecarga. Um `drop function if exists` com
--     assinatura fixa erra em silencio quando o banco real diverge, e o
--     `create` seguinte estoura com "already exists with same argument
--     types". Dropar por nome nao tem esse ponto cego, e deixa a migration
--     re-executavel -- o SQL Editor do Supabase nao envolve o script numa
--     transacao, entao uma falha no meio deixa a primeira metade aplicada.
--
--     O `cascade` tambem resolve a dependencia inversa: varias funcoes
--     antigas (create_fc_account, update_fc_account_platform...) declaram
--     `returns public.user_fc_accounts`, e um `drop table` tropeca nelas.
--     Matando todas aqui em cima, a tabela cai limpa la embaixo.
--
--     Fora da lista de proposito: team_members_protect_owner e
--     _guard_no_double_matchmaking_participation, que tem trigger pendurado
--     -- `cascade` neles derrubaria o trigger junto. As duas sao recriadas
--     com `create or replace` e assinatura estavel (), entao nao precisam.
-- =======================================================================
do $guard$
declare
    v_fn record;
begin
    for v_fn in
        select p.oid::regprocedure as sig
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname in (
              '_build_matchmaking_state',
              '_data_checkup',
              '_dispatch_finished_weekend_league_notifications',
              '_expire_team_search_if_needed',
              '_fc_account_globally_searching',
              '_fc_account_team_ids',
              '_lock_fc_account_matchmaking',
              '_lock_user_matchmaking',
              '_owns_fc_squad',
              '_promote_next_queued_player',
              '_promote_next_queued_player_for_team',
              '_promote_next_queued_players_for_teams',
              '_retry_promotion_for_fc_account_queues',
              '_retry_promotion_for_user_queues',
              '_transfer_team_ownership',
              '_user_globally_searching',
              'approve_team_join_request',
              'archive_fc_account',
              'archive_fc_squad',
              'cancel_match_search',
              'check_public_profile_slug_available',
              'clear_weekend_league_manual_record',
              'create_fc_account',
              'create_fc_squad',
              'create_team',
              'delete_my_account',
              'get_fc_squad_builder',
              'get_my_account',
              'get_my_matchmaking_status',
              'get_my_public_profile_settings',
              'get_public_profile',
              'get_public_team',
              'get_requests_inbox',
              'get_rivals_account_stats',
              'get_team_activity_history',
              'get_team_member_profile',
              'get_team_player_statuses',
              'get_weekend_league_account_stats',
              'get_weekend_league_record',
              'increment_rivals_manual_record',
              'increment_weekend_league_manual_record',
              'invite_team_member',
              'is_team_member_as',
              'join_team_by_invite',
              'leave_match_search_queue',
              'link_fc_account_to_team',
              'list_fc_squads',
              'list_my_fc_accounts',
              'remove_team_member',
              'report_match_found_and_start_game',
              'request_match_search',
              'request_match_search_priority',
              'request_team_join',
              'resolve_invite_target',
              'respond_team_invitation',
              'set_default_fc_squad',
              'set_team_member_role',
              'set_weekend_league_manual_record',
              'team_members_sync_user_id',
              'transfer_team_ownership',
              'unlink_fc_account_from_team',
              'update_fc_account',
              'update_fc_account_avatar',
              'update_fc_account_platform',
              'update_my_platforms',
              'update_my_public_profile_settings',
              'update_my_rivals_division',
              'update_rivals_division'
          )
    loop
        execute 'drop function if exists ' || v_fn.sig || ' cascade';
    end loop;
end;
$guard$;

-- =======================================================================
-- 0b. Helpers de renomeacao idempotente. Mesmo motivo do bloco acima: sem
--     transacao envolvendo o script, um `rename` que ja rodou precisa ser
--     no-op em vez de erro.
-- =======================================================================
create or replace function pg_temp._rename_table(p_from text, p_to text)
returns void
language plpgsql
as $h$
begin
    if to_regclass('public.' || p_from) is not null
       and to_regclass('public.' || p_to) is null then
        execute format('alter table public.%I rename to %I', p_from, p_to);
    end if;
end;
$h$;

create or replace function pg_temp._rename_column(
    p_table text, p_from text, p_to text
)
returns void
language plpgsql
as $h$
begin
    if exists (
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = p_table
          and column_name = p_from
    ) and not exists (
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = p_table
          and column_name = p_to
    ) then
        execute format(
            'alter table public.%I rename column %I to %I', p_table, p_from, p_to
        );
    end if;
end;
$h$;

create or replace function pg_temp._add_pk(p_table text, p_cols text)
returns void
language plpgsql
as $h$
begin
    if not exists (
        select 1 from pg_constraint c
        join pg_class t on t.oid = c.conrelid
        join pg_namespace n on n.oid = t.relnamespace
        where n.nspname = 'public' and t.relname = p_table and c.contype = 'p'
    ) then
        execute format('alter table public.%I add primary key (%s)', p_table, p_cols);
    end if;
end;
$h$;

-- =======================================================================
-- 0. RESET DE DADOS DE DESENVOLVIMENTO
-- =======================================================================
-- Dinamico: numa re-execucao as tabelas de Perfil ja nao existem, e um
-- `truncate` com nome fixo estouraria em vez de virar no-op.
do $reset$
declare
    v_tables text[] := array[
        'match_search_queue', 'match_search_sessions', 'game_matches',
        'fc_squad_slots', 'fc_squads',
        'fc_account_weekend_league_progress', 'user_weekend_league_progress',
        'fc_account_rivals_progress', 'user_rivals_progress',
        'team_join_requests', 'team_invitations', 'team_invite_links',
        'user_public_profiles', 'fc_account_teams', 'team_members',
        'user_fc_accounts', 'teams', 'team_matchmaking_revisions',
        'user_requests_revisions', 'user_notifications', 'notification_outbox',
        'notification_preferences', 'user_devices', 'profiles'
    ];
    v_existing text[];
    v_name text;
begin
    foreach v_name in array v_tables loop
        if to_regclass('public.' || v_name) is not null then
            v_existing := v_existing || format('public.%I', v_name);
        end if;
    end loop;

    if v_existing is not null then
        execute 'truncate table ' || array_to_string(v_existing, ', ') || ' cascade';
    end if;
end;
$reset$;

delete from auth.users;

-- =======================================================================
-- 1. FUNCOES JA MORTAS/QUEBRADAS -- nao sobrevivem a esta migration mesmo
--    que nao dependessem de fc_account_id.
-- =======================================================================
drop function if exists public.get_weekend_league_record(uuid, uuid);

-- =======================================================================
-- 2. profiles ganha os atributos que viviam em user_fc_accounts.
-- =======================================================================
alter table public.profiles
    add column if not exists platforms text[] not null default '{}',
    add column if not exists rivals_division text;

alter table public.profiles
    drop constraint if exists profiles_platforms_valid,
    drop constraint if exists profiles_rivals_division_valid;

alter table public.profiles
    add constraint profiles_platforms_valid
        check (platforms <@ array['PC', 'PS', 'XBOX']::text[]),
    add constraint profiles_rivals_division_valid
        check (
            rivals_division is null
            or rivals_division in (
                'DIV_10', 'DIV_9', 'DIV_8', 'DIV_7', 'DIV_6',
                'DIV_5', 'DIV_4', 'DIV_3', 'DIV_2', 'DIV_1', 'ELITE'
            )
        );

comment on column public.profiles.platforms is
    'Plataformas selecionadas pelo usuario (PC/PS/XBOX), multi-select. Vazio so antes do onboarding terminar -- update_my_platforms exige pelo menos uma dali em diante.';
comment on column public.profiles.rivals_division is
    'Divisao atual de Division Rivals do usuario.';

-- =======================================================================
-- 3. team_members volta a ser por LOGIN (team_id, user_id) -- so existia
--    fc_account_id pra permitir duas Contas do mesmo login serem duas
--    linhas, cenario que deixa de existir.
-- =======================================================================
drop trigger if exists team_members_sync_user_id on public.team_members;
drop function if exists public.team_members_sync_user_id();
drop function if exists public.is_team_member_as(uuid, uuid);
drop index if exists public.team_members_fc_account_id_idx;

alter table public.team_members drop constraint if exists team_members_pkey;
alter table public.team_members drop column if exists fc_account_id;
alter table public.team_members alter column user_id set not null;
select pg_temp._add_pk('team_members', 'team_id, user_id');

comment on column public.team_members.user_id is
    'Identidade da membership -- volta a ser o login (auth.uid()), chave primaria junto com team_id.';

-- Trigger de protecao do OWNER: mesma invariante, agora sobre user_id.
create or replace function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
    v_transfer_allowed boolean :=
        coalesce(current_setting('app.allow_owner_transfer', true), '') = 'on';
begin
    if tg_op = 'DELETE' then
        if old.role = 'OWNER'
            and not v_transfer_allowed
            and exists (select 1 from public.teams where id = old.team_id)
        then
            raise exception 'team owner cannot be removed'
                using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.user_id is distinct from old.user_id
    then
        raise exception 'team membership identity is immutable'
            using errcode = 'FQ004';
    end if;

    if old.role = 'OWNER' and new.role <> 'OWNER' and not v_transfer_allowed then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    new.joined_at := old.joined_at;
    return new;
end;
$$;

-- =======================================================================
-- 4. fc_squads: fc_account_id -> user_id. Ja era 1 squad ativo por conta
--    (indice unico parcial existente) -- so troca a chave.
-- =======================================================================
drop index if exists public.fc_squads_account_idx;
drop index if exists public.fc_squads_one_default_per_account;
drop index if exists public.fc_squads_one_active_per_account_idx;
drop policy if exists fc_squads_select_own on public.fc_squads;
drop policy if exists fc_squad_slots_select_own on public.fc_squad_slots;

select pg_temp._rename_column('fc_squads', 'fc_account_id', 'user_id');
alter table public.fc_squads drop constraint if exists fc_squads_fc_account_id_fkey;
alter table public.fc_squads
    drop constraint if exists fc_squads_user_id_fkey;
alter table public.fc_squads
    add constraint fc_squads_user_id_fkey
        foreign key (user_id) references public.profiles (id) on delete cascade;

create index if not exists fc_squads_user_idx on public.fc_squads (user_id) where is_active;
create unique index if not exists fc_squads_one_default_per_user
    on public.fc_squads (user_id) where is_default and is_active;
create unique index if not exists fc_squads_one_active_per_user_idx
    on public.fc_squads (user_id) where is_active;

comment on index public.fc_squads_one_active_per_user_idx is
    'Um usuario = no maximo um Squad ativo. Arquivar (is_active=false) libera pra um novo.';

create policy fc_squads_select_own
    on public.fc_squads for select to authenticated
    using ((select auth.uid()) = user_id);

create policy fc_squad_slots_select_own
    on public.fc_squad_slots for select to authenticated
    using (
        exists (
            select 1 from public.fc_squads as s
            where s.id = fc_squad_slots.squad_id
              and s.user_id = (select auth.uid())
        )
    );

-- =======================================================================
-- 5. match_search_sessions / match_search_queue / game_matches: essas tres
--    tabelas JA TINHAM user_id (sempre igual ao dono da fc_account) -- so
--    sobra o fc_account_id redundante.
-- =======================================================================
drop trigger if exists match_search_sessions_guard_double on public.match_search_sessions;
drop trigger if exists match_search_queue_guard_double on public.match_search_queue;
drop index if exists public.match_search_queue_unique_team_fc_account_mode;

alter table public.match_search_sessions drop column if exists fc_account_id;
alter table public.match_search_queue drop column if exists fc_account_id;
alter table public.game_matches drop column if exists fc_account_id;

create unique index if not exists match_search_queue_unique_team_user_mode
    on public.match_search_queue (team_id, user_id, game_mode);

-- Guard de dupla participacao, agora por user_id.
create or replace function public._guard_no_double_matchmaking_participation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if new.user_id is null then
        return new;
    end if;

    if tg_table_name = 'match_search_sessions' then
        if exists (
            select 1 from public.match_search_queue
            where team_id = new.team_id and user_id = new.user_id
              and game_mode = new.game_mode
        ) then
            raise exception 'user already queued for this team'
                using errcode = 'FQ017';
        end if;
    elsif tg_table_name = 'match_search_queue' then
        if exists (
            select 1 from public.match_search_sessions
            where team_id = new.team_id
              and user_id = new.user_id
              and game_mode = new.game_mode
              and status = 'SEARCHING'
        ) then
            raise exception 'user already searching for this team'
                using errcode = 'FQ017';
        end if;
    end if;
    return new;
end;
$$;

create trigger match_search_sessions_guard_double
    before insert or update on public.match_search_sessions
    for each row execute function public._guard_no_double_matchmaking_participation();
create trigger match_search_queue_guard_double
    before insert or update on public.match_search_queue
    for each row execute function public._guard_no_double_matchmaking_participation();

-- =======================================================================
-- 6. Progresso manual de WL/Rivals: renomeia tabela + chave.
-- =======================================================================
select pg_temp._rename_table(
    'fc_account_weekend_league_progress', 'user_weekend_league_progress'
);
select pg_temp._rename_column(
    'user_weekend_league_progress', 'fc_account_id', 'user_id'
);
alter table public.user_weekend_league_progress
    drop constraint if exists fc_account_weekend_league_progress_fc_account_id_fkey;
alter table public.user_weekend_league_progress
    drop constraint if exists user_weekend_league_progress_user_id_fkey;
alter table public.user_weekend_league_progress
    add constraint user_weekend_league_progress_user_id_fkey
        foreign key (user_id) references public.profiles (id) on delete cascade;

select pg_temp._rename_table(
    'fc_account_rivals_progress', 'user_rivals_progress'
);
select pg_temp._rename_column(
    'user_rivals_progress', 'fc_account_id', 'user_id'
);
alter table public.user_rivals_progress
    drop constraint if exists fc_account_rivals_progress_pkey;
alter table public.user_rivals_progress
    drop constraint if exists fc_account_rivals_progress_fc_account_id_fkey;
select pg_temp._add_pk('user_rivals_progress', 'user_id');
alter table public.user_rivals_progress
    drop constraint if exists user_rivals_progress_user_id_fkey;
alter table public.user_rivals_progress
    add constraint user_rivals_progress_user_id_fkey
        foreign key (user_id) references public.profiles (id) on delete cascade;

-- =======================================================================
-- 7. fc_account_teams: vinculo redundante com team_members agora que so
--    existe 1 identidade por login. Removido.
-- =======================================================================
drop table if exists public.fc_account_teams;

-- =======================================================================
-- 8. team_join_requests / team_invitations: fc_account_id era so o mesmo
--    login de novo -- coluna redundante com user_id/invitee_user_id.
-- =======================================================================
drop index if exists public.team_join_requests_pending_unique_idx;
alter table public.team_join_requests drop column if exists fc_account_id;
create unique index if not exists team_join_requests_pending_unique_idx
    on public.team_join_requests (team_id, user_id) where status = 'PENDING';

alter table public.team_invitations drop column if exists fc_account_id;

-- =======================================================================
-- 9. user_public_profiles: volta a ser 1 por usuario (era assim antes de
--    20261013102450). Reset ja truncou os dados de teste.
-- =======================================================================
alter table public.user_public_profiles drop constraint if exists user_public_profiles_pkey;
alter table public.user_public_profiles drop column if exists fc_account_id;
select pg_temp._add_pk('user_public_profiles', 'user_id');

comment on table public.user_public_profiles is
    'Configuracao de exposicao do perfil publico de UM usuario (chave e user_id). Linha some em cascata se o usuario some.';

-- =======================================================================
-- 10. user_fc_accounts: a tabela "Elenco"/Profile em si. Some.
-- =======================================================================
-- As tres policies do bucket de avatar de Perfil: sem Perfil, sem bucket.
drop policy if exists fc_account_avatars_insert_owner_only on storage.objects;
drop policy if exists fc_account_avatars_update_owner_only on storage.objects;
drop policy if exists fc_account_avatars_delete_owner_only on storage.objects;

-- O BUCKET 'fc-account-avatars' EM SI SAI A MAO, pelo Dashboard > Storage
-- (ou pela Storage API). O trigger storage.protect_delete() recusa
-- `delete from storage.objects/buckets` por SQL, justamente pra nao deixar
-- arquivo orfao no bucket de armazenamento quando a linha some do banco.
-- Sem as policies acima ninguem mais escreve nele, entao o bucket fica
-- inerte ate ser apagado -- nao bloqueia nada desta migration.

drop table if exists public.user_fc_accounts;

-- =======================================================================
-- 11. Squads RPCs: _owns_fc_squad direto por user_id (sem join), sem mais
--     parametro de conta em list/create.
-- =======================================================================
create or replace function public._owns_fc_squad(p_squad_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.fc_squads
        where id = p_squad_id and user_id = (select auth.uid())
    );
$$;

create or replace function public.get_fc_squad_builder(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_squad public.fc_squads;
    v_result jsonb;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select * into v_squad from public.fc_squads where id = p_squad_id;

    select jsonb_build_object(
        'id', v_squad.id,
        'user_id', v_squad.user_id,
        'name', v_squad.name,
        'formation_code', v_squad.formation_code,
        'is_default', v_squad.is_default,
        'is_active', v_squad.is_active,
        'bench_size', public._fc_bench_size(),
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
        'slots', (
            select coalesce(jsonb_agg(
                jsonb_build_object(
                    'slot_type', sl.slot_type,
                    'slot_code', sl.slot_code,
                    'card', public._fc_card_json(c)
                ) order by sl.slot_type, sl.slot_code
            ), '[]'::jsonb)
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = p_squad_id
        ),
        'manager', (
            select jsonb_build_object(
                'id', m.id,
                'name', m.name,
                'image_url', m.image_url,
                'nation', case when n.id is null then null else jsonb_build_object(
                    'id', n.id, 'name', n.name, 'flag_image_url', n.flag_image_url
                ) end
            )
            from public.fc_managers as m
            left join public.fc_nations as n on n.id = m.nation_id
            where m.id = v_squad.manager_id
        ),
        'manager_league', (
            select jsonb_build_object('id', l.id, 'name', l.name,
                                      'logo_image_url', l.logo_image_url)
            from public.fc_leagues as l
            where l.id = v_squad.manager_league_id
        )
    ) into v_result;

    return v_result;
end;
$$;

drop function if exists public.list_fc_squads(uuid);
create function public.list_fc_squads()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return (
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'user_id', s.user_id,
                'name', s.name,
                'formation_code', s.formation_code,
                'is_default', s.is_default,
                'is_active', s.is_active,
                'starting_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'STARTING'
                ),
                'bench_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'BENCH'
                )
            ) order by s.is_default desc, s.created_at
        ), '[]'::jsonb)
        from public.fc_squads as s
        where s.user_id = (select auth.uid()) and s.is_active
    );
end;
$$;

revoke execute on function public.list_fc_squads() from public, anon;
grant execute on function public.list_fc_squads() to authenticated;

drop function if exists public.create_fc_squad(uuid, text, text);
create function public.create_fc_squad(
    p_name text,
    p_formation_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_name text := btrim(coalesce(p_name, ''));
    v_squad_id uuid;
    v_existing uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- Idempotente: o usuario ja tem squad, entao este e o squad dele.
    select id into v_existing
    from public.fc_squads
    where user_id = v_user_id and is_active
    limit 1;

    if v_existing is not null then
        return public.get_fc_squad_builder(v_existing);
    end if;

    if char_length(v_name) < 1 or char_length(v_name) > 40 then
        raise exception 'invalid squad name' using errcode = 'FQ030';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    insert into public.fc_squads (user_id, name, formation_code, is_default)
    values (v_user_id, v_name, p_formation_code, true)
    returning id into v_squad_id;

    return public.get_fc_squad_builder(v_squad_id);
end;
$$;

comment on function public.create_fc_squad(text, text) is
    'Cria o squad do usuario. Idempotente: se ja existir, devolve o existente.';

revoke execute on function public.create_fc_squad(text, text) from public, anon;
grant execute on function public.create_fc_squad(text, text) to authenticated;

-- update_fc_squad / set_default_fc_squad / archive_fc_squad / set_fc_squad_formation
-- / _fc_slot_position / set_fc_squad_slot / clear_fc_squad_slot / swap_fc_squad_slots
-- / set_fc_squad_manager: nao mudam de assinatura, so o que _owns_fc_squad faz por
-- baixo mudou (acima). set_default_fc_squad e archive_fc_squad liam
-- fc_squads.fc_account_id numa variavel local -- ajusta so essas duas.
create or replace function public.set_default_fc_squad(p_squad_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select user_id into v_user_id from public.fc_squads where id = p_squad_id;

    update public.fc_squads set is_default = false
    where user_id = v_user_id and is_default and id <> p_squad_id;

    update public.fc_squads set is_default = true where id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

create or replace function public.archive_fc_squad(p_squad_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid;
    v_was_default boolean;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if exists (
        select 1 from public.match_search_sessions
        where fc_squad_id = p_squad_id and status = 'SEARCHING'
    ) or exists (
        select 1 from public.match_search_queue where fc_squad_id = p_squad_id
    ) then
        raise exception 'squad is in use by an active search'
            using errcode = 'FQ034';
    end if;

    select user_id, is_default into v_user_id, v_was_default
    from public.fc_squads where id = p_squad_id;

    update public.fc_squads
    set is_active = false, is_default = false
    where id = p_squad_id;

    if v_was_default then
        update public.fc_squads set is_default = true
        where id = (
            select id from public.fc_squads
            where user_id = v_user_id and is_active
            order by created_at
            limit 1
        );
    end if;
end;
$$;

-- =======================================================================
-- 12. Matchmaking: toda RPC perde p_fc_account_id -- a identidade e sempre
--     auth.uid() agora, nunca precisa ser passada nem validada.
-- =======================================================================
drop function if exists public._lock_fc_account_matchmaking(uuid);
create function public._lock_user_matchmaking(p_user_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
    select pg_advisory_xact_lock(hashtextextended('user_matchmaking:' || p_user_id::text, 0));
$$;

revoke execute on function public._lock_user_matchmaking(uuid)
    from public, anon, authenticated;

drop function if exists public._fc_account_globally_searching(uuid);
create function public._user_globally_searching(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.match_search_sessions
        where user_id = p_user_id and status = 'SEARCHING'
    );
$$;

revoke execute on function public._user_globally_searching(uuid)
    from public, anon, authenticated;

drop function if exists public._retry_promotion_for_fc_account_queues(uuid, uuid);
create function public._retry_promotion_for_user_queues(
    p_user_id uuid,
    p_exclude_team_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_pair record;
    v_team_ids uuid[];
begin
    if p_user_id is null then
        return;
    end if;

    select coalesce(array_agg(distinct team_id order by team_id), array[]::uuid[])
        into v_team_ids
    from public.match_search_queue
    where user_id = p_user_id and team_id <> p_exclude_team_id;

    if array_length(v_team_ids, 1) is null then
        return;
    end if;

    perform public._lock_teams_matchmaking(v_team_ids);

    for v_pair in
        select distinct team_id, game_mode
        from public.match_search_queue
        where user_id = p_user_id and team_id <> p_exclude_team_id
    loop
        if public._team_free_for_search(v_pair.team_id, v_pair.game_mode) then
            perform public._promote_next_queued_player_for_team(
                v_pair.team_id, v_pair.game_mode
            );
            perform public._notify_matchmaking_changed(v_pair.team_id);
        end if;
    end loop;
end;
$$;

create or replace function public._promote_next_queued_player_for_team(
    p_team_id uuid,
    p_game_mode text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_attempts_left integer;
    v_candidate public.match_search_queue;
    v_new_session public.match_search_sessions;
begin
    select count(*) into v_attempts_left
    from public.match_search_queue
    where team_id = p_team_id and game_mode = p_game_mode;

    while v_attempts_left > 0 loop
        v_attempts_left := v_attempts_left - 1;

        select * into v_candidate
        from public.match_search_queue
        where team_id = p_team_id and game_mode = p_game_mode
        order by sequence
        limit 1;

        exit when v_candidate.id is null;

        perform public._lock_user_matchmaking(v_candidate.user_id);

        if public._user_globally_searching(v_candidate.user_id) then
            delete from public.match_search_queue where id = v_candidate.id;
            insert into public.match_search_queue
                (team_id, user_id, game_mode, fc_squad_id)
            values (
                v_candidate.team_id, v_candidate.user_id, v_candidate.game_mode,
                v_candidate.fc_squad_id
            );
            continue;
        end if;

        delete from public.match_search_queue where id = v_candidate.id;

        insert into public.match_search_sessions
            (team_id, user_id, status, started_at, expires_at, game_mode,
             fc_squad_id)
        select
            p_team_id, v_candidate.user_id, 'SEARCHING', now(),
            now() + make_interval(secs => t.default_search_duration_seconds),
            v_candidate.game_mode, v_candidate.fc_squad_id
        from public.teams as t
        where t.id = p_team_id
        returning * into v_new_session;

        perform public._enqueue_notification(
            v_new_session.user_id,
            'YOUR_TURN',
            p_team_id,
            v_new_session.id,
            jsonb_build_object('expires_at', to_jsonb(v_new_session.expires_at))
        );
        return;
    end loop;
end;
$$;

create or replace function public._expire_team_search_if_needed(p_team_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_session public.match_search_sessions;
    v_expired_any boolean := false;
begin
    for v_session in
        select * from public.match_search_sessions
        where team_id = p_team_id and status = 'SEARCHING'
          and expires_at <= now()
    loop
        update public.match_search_sessions
        set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
        where id = v_session.id;

        perform public._enqueue_notification(
            v_session.user_id, 'SEARCH_EXPIRED', p_team_id, v_session.id, '{}'::jsonb
        );

        perform public._promote_next_queued_player_for_team(
            p_team_id, v_session.game_mode
        );
        perform public._notify_matchmaking_changed(p_team_id);

        if v_session.user_id is not null then
            perform public._retry_promotion_for_user_queues(
                v_session.user_id, p_team_id
            );
        end if;

        v_expired_any := true;
    end loop;

    return v_expired_any;
end;
$$;

drop function if exists public.request_match_search(uuid, uuid, uuid, text);
create function public.request_match_search(
    p_team_id uuid,
    p_fc_squad_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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
        select 1 from public.profiles
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
$$;

comment on function public.request_match_search(uuid, uuid, text) is
    'Busca por Usuario+Time+Modo. Cada (Time, Modo) e uma fila independente -- so comeca na hora se ESSE par estiver livre e o usuario nao estiver buscando em outro lugar; senao entra na fila deste (time, modo).';

revoke execute on function public.request_match_search(uuid, uuid, text)
    from public, anon;
grant execute on function public.request_match_search(uuid, uuid, text)
    to authenticated;

drop function if exists public.cancel_match_search(uuid);
create function public.cancel_match_search()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_team_id uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._lock_user_matchmaking(v_user_id);

    select * into v_searching
    from public.match_search_sessions
    where user_id = v_user_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search to cancel' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;
    perform public._lock_team_matchmaking(v_team_id);

    update public.match_search_sessions
    set status = 'CANCELLED', finish_reason = 'CANCELLED', finished_at = now()
    where id = v_searching.id;

    perform public._promote_next_queued_player_for_team(
        v_team_id, v_searching.game_mode
    );
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_searching.game_mode);
end;
$$;

revoke execute on function public.cancel_match_search() from public, anon;
grant execute on function public.cancel_match_search() to authenticated;

drop function if exists public.leave_match_search_queue(uuid, uuid, text);
create function public.leave_match_search_queue(
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_entry public.match_search_queue;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._lock_team_matchmaking(p_team_id);

    select * into v_entry
    from public.match_search_queue
    where team_id = p_team_id and user_id = v_user_id
      and game_mode = p_game_mode;

    if v_entry.id is null then
        raise exception 'not in this team queue' using errcode = 'FQ047';
    end if;

    delete from public.match_search_queue where id = v_entry.id;

    perform public._notify_matchmaking_changed(p_team_id);

    return public.get_my_matchmaking_status(p_team_id, p_game_mode);
end;
$$;

comment on function public.leave_match_search_queue(uuid, text) is
    'Sai da fila de UM (time, modo) especifico -- o usuario pode continuar em filas de outros times/modos.';

revoke execute on function public.leave_match_search_queue(uuid, text)
    from public, anon;
grant execute on function public.leave_match_search_queue(uuid, text)
    to authenticated;

drop function if exists public.report_match_found_and_start_game(uuid);
create function public.report_match_found_and_start_game()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_searching public.match_search_sessions;
    v_event_id uuid;
    v_mode text;
    v_snapshot jsonb;
    v_team_id uuid;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public._lock_user_matchmaking(v_user_id);

    select * into v_searching
    from public.match_search_sessions
    where user_id = v_user_id and status = 'SEARCHING';

    if v_searching.id is null then
        raise exception 'no active search' using errcode = 'FQ015';
    end if;

    v_team_id := v_searching.team_id;
    perform public._lock_team_matchmaking(v_team_id);

    v_mode := coalesce(v_searching.game_mode, 'DIVISION_RIVALS');

    if v_searching.fc_squad_id is not null then
        v_snapshot := public._fc_squad_snapshot(v_searching.fc_squad_id);
    end if;

    update public.match_search_sessions
    set status = 'MATCH_FOUND', finish_reason = 'MATCH_FOUND', finished_at = now()
    where id = v_searching.id;

    update public.game_matches
    set status = 'ABANDONED', ended_at = now()
    where user_id = v_user_id and status = 'IN_MATCH';

    if v_mode = 'WEEKEND_LEAGUE' then
        select id into v_event_id
        from public.weekend_league_events
        where is_active and now() between starts_at and ends_at
        order by starts_at desc
        limit 1;
    end if;

    insert into public.game_matches
        (user_id, team_id, search_session_id, game_mode,
         weekend_league_event_id, status, started_at,
         fc_squad_id, squad_snapshot)
    values
        (v_user_id, v_team_id, v_searching.id, v_mode,
         v_event_id, 'IN_MATCH', now(),
         v_searching.fc_squad_id, v_snapshot);

    perform public._promote_next_queued_player_for_team(v_team_id, v_mode);
    perform public._notify_matchmaking_changed(v_team_id);
    perform public._retry_promotion_for_user_queues(v_user_id, v_team_id);

    return public.get_my_matchmaking_status(v_team_id, v_mode);
end;
$$;

revoke execute on function public.report_match_found_and_start_game()
    from public, anon;
grant execute on function public.report_match_found_and_start_game()
    to authenticated;

drop function if exists public.get_my_matchmaking_status(uuid, uuid, text);
create function public.get_my_matchmaking_status(
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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
        join public.profiles as p on p.id = q.user_id
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
            'display_name', (select display_name from public.profiles where id = v_other_session.user_id),
            'avatar_url', (select avatar_url from public.profiles where id = v_other_session.user_id),
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
$$;

comment on function public.get_my_matchmaking_status(uuid, text) is
    'Estado de Usuario+Time+MODO: minha busca/posicao NESSE (time, modo), quem me bloqueia nele, se estou buscando em outro (time, modo), e a fila daquele par.';

revoke execute on function public.get_my_matchmaking_status(uuid, text)
    from public, anon;
grant execute on function public.get_my_matchmaking_status(uuid, text)
    to authenticated;

drop function if exists public.request_match_search_priority(uuid, uuid, text);
create function public.request_match_search_priority(
    p_team_id uuid,
    p_game_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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
    from public.profiles where id = v_user_id;
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
$$;

comment on function public.request_match_search_priority(uuid, text) is
    'Pedido humano de prioridade na sessao daquele (time, modo) -- nunca altera fila/busca/lock, so notifica quem esta buscando.';

revoke execute on function public.request_match_search_priority(uuid, text)
    from public, anon;
grant execute on function public.request_match_search_priority(uuid, text)
    to authenticated;

-- =======================================================================
-- 13. Times: create_team / join_team_by_invite / remove_team_member /
--     set_team_member_role / request_team_join / approve_team_join_request
--     / respond_team_invitation / get_team_player_statuses /
--     transfer_team_ownership voltam a operar por user_id direto.
-- =======================================================================
drop function if exists public.create_team(text, text, integer, uuid);
create function public.create_team(
    p_name text,
    p_tag text default null,
    p_default_search_duration_seconds integer default 180
)
returns public.teams
language plpgsql
security definer
set search_path = ''
as $$
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

    if not exists (select 1 from public.profiles where id = v_user_id) then
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
$$;

comment on function public.create_team(text, text, integer) is
    'Cria um time e a membership OWNER do usuario numa unica transacao.';

revoke execute on function public.create_team(text, text, integer) from public, anon;
grant execute on function public.create_team(text, text, integer) to authenticated;

drop function if exists public.join_team_by_invite(text, uuid);
create function public.join_team_by_invite(p_code text)
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

    return query select false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$$;

comment on function public.join_team_by_invite(text) is
    'Entrada atomica no time via convite. Sempre role=PLAYER. Ja membro devolve already_member=true sem duplicar linha nem incrementar uso.';

revoke execute on function public.join_team_by_invite(text) from public, anon;
grant execute on function public.join_team_by_invite(text) to authenticated;

drop function if exists public.remove_team_member(uuid, uuid);
create function public.remove_team_member(
    p_team_id uuid,
    p_target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_actor_role public.team_role;
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select role into v_actor_role
    from public.team_members
    where team_id = p_team_id and user_id = v_actor_id;

    if v_actor_role is null or v_actor_role = 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team owner cannot be removed' using errcode = 'FQ005';
    end if;

    if v_actor_role = 'ADMIN' and v_target_role <> 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    delete from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

comment on function public.remove_team_member(uuid, uuid) is
    'OWNER remove PLAYER ou ADMIN; ADMIN remove so PLAYER. Nunca remove OWNER.';

drop function if exists public.set_team_member_role(uuid, uuid, public.team_role);
create function public.set_team_member_role(
    p_team_id uuid,
    p_target_user_id uuid,
    p_role public.team_role
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet' using errcode = 'FQ005';
    end if;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet' using errcode = 'FQ005';
    end if;

    update public.team_members
    set role = p_role
    where team_id = p_team_id and user_id = p_target_user_id;
end;
$$;

comment on function public.set_team_member_role(uuid, uuid, public.team_role) is
    'Somente OWNER promove PLAYER->ADMIN ou rebaixa ADMIN->PLAYER. Nunca atribui OWNER.';

revoke execute on function public.remove_team_member(uuid, uuid) from public, anon;
revoke execute on function public.set_team_member_role(uuid, uuid, public.team_role) from public, anon;
grant execute on function public.remove_team_member(uuid, uuid) to authenticated;
grant execute on function public.set_team_member_role(uuid, uuid, public.team_role) to authenticated;

drop function if exists public.request_team_join(uuid, uuid);
create function public.request_team_join(p_team_id uuid)
returns public.team_join_requests
language plpgsql
security definer
set search_path = ''
as $$
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
    from public.profiles where id = v_user_id;

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
$$;

drop function if exists public.approve_team_join_request(uuid);
create function public.approve_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_team_name text;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select name into v_team_name from public.teams where id = v_row.team_id;

    if not exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and user_id = v_row.user_id
    ) then
        insert into public.team_members (team_id, user_id, role)
        values (v_row.team_id, v_row.user_id, 'PLAYER');
    end if;

    update public.team_join_requests
    set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);

    perform public._emit_user_notification(
        v_row.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_APPROVED',
        'TEAM_JOIN_REQUEST_APPROVED:' || v_row.id,
        'notification_team_join_request_approved',
        jsonb_build_object('team_id', v_row.team_id, 'team_name', v_team_name),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;

drop function if exists public.respond_team_invitation(uuid, boolean, uuid);
create function public.respond_team_invitation(
    p_invitation_id uuid,
    p_accept boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
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
    select display_name into v_display_name from public.profiles where id = v_user_id;

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
$$;

revoke execute on function public.respond_team_invitation(uuid, boolean) from public, anon;
grant execute on function public.respond_team_invitation(uuid, boolean) to authenticated;

create or replace function public.get_team_player_statuses(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
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
    join public.profiles as p on p.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'members', v_members
    );
end;
$$;

drop function if exists public.transfer_team_ownership(uuid, uuid);
create function public.transfer_team_ownership(
    p_team_id uuid,
    p_target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform 1 from public.team_members where team_id = p_team_id for update;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if p_target_user_id = v_user_id then
        raise exception 'target is already the owner' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and user_id = p_target_user_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    perform public._transfer_team_ownership(p_team_id, v_user_id, p_target_user_id);
end;
$$;

comment on function public.transfer_team_ownership(uuid, uuid) is
    'OWNER passa a posse do time pra outro membro. O OWNER antigo vira PLAYER e continua no time. Atomica.';

revoke execute on function public.transfer_team_ownership(uuid, uuid) from public, anon;
grant execute on function public.transfer_team_ownership(uuid, uuid) to authenticated;

drop function if exists public._transfer_team_ownership(uuid, uuid, uuid);
create function public._transfer_team_ownership(
    p_team_id uuid,
    p_from_user_id uuid,
    p_to_user_id uuid
)
returns void
language plpgsql
set search_path = ''
as $$
begin
    perform set_config('app.allow_owner_transfer', 'on', true);

    update public.team_members
    set role = 'PLAYER'
    where team_id = p_team_id and user_id = p_from_user_id;

    update public.team_members
    set role = 'OWNER'
    where team_id = p_team_id and user_id = p_to_user_id;

    perform set_config('app.allow_owner_transfer', 'off', true);
end;
$$;

comment on function public._transfer_team_ownership(uuid, uuid, uuid) is
    'Uso interno. Rebaixa o OWNER atual e promove o novo, nessa ordem (o indice unico de OWNER nao e deferrable). Nao valida permissao -- quem chama valida.';

revoke execute on function public._transfer_team_ownership(uuid, uuid, uuid)
    from public, anon, authenticated;

-- resolve_invite_target / invite_team_member: sem mais "nome do elenco",
-- so o nome de exibicao do usuario.
create or replace function public.resolve_invite_target(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
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
            join public.profiles p on p.id = upp.user_id
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
    from public.profiles where id = v_row.user_id;

    return jsonb_build_object(
        'found', true,
        'user_id', v_row.user_id,
        'display_name', v_display_name,
        'avatar_url', v_avatar_url
    );
end;
$$;

create or replace function public.invite_team_member(p_team_id uuid, p_slug text)
returns public.team_invitations
language plpgsql
security definer
set search_path = ''
as $$
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
            join public.profiles p on p.id = upp.user_id
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
$$;

-- =======================================================================
-- 14. get_team_activity_history / get_team_member_profile / get_public_team:
--     perdem o parametro/join de fc_account.
-- =======================================================================
drop function if exists public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz, uuid
);
create function public.get_team_activity_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_occurred_at timestamptz default null,
    p_cursor_id uuid default null,
    p_search_status text default null,
    p_user_id uuid default null,
    p_from timestamptz default null,
    p_to timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
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
        left join public.profiles as p on p.id = s.user_id
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
$$;

comment on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) is 'Historico de buscas do time (achou partida/cancelou/expirou), paginado.';

revoke execute on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) from public, anon;
grant execute on function public.get_team_activity_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) to authenticated;

drop function if exists public.get_team_member_profile(uuid, uuid, uuid);
create function public.get_team_member_profile(p_team_id uuid, p_user_id uuid)
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
    from public.profiles
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
$$;

comment on function public.get_team_member_profile(uuid, uuid) is
    'Perfil publico de um membro do time: divisao+placar manual de Rivals, historico manual de WL por semana, squad principal. So membros do mesmo time podem chamar.';

revoke execute on function public.get_team_member_profile(uuid, uuid) from public, anon;
grant execute on function public.get_team_member_profile(uuid, uuid) to authenticated;

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
$$;

-- =======================================================================
-- 15. Conta: novas RPCs simples substituem create/update/archive/link/
--     unlink_fc_account e list_my_fc_accounts.
-- =======================================================================
drop function if exists public.create_fc_account(text);
drop function if exists public.update_fc_account(uuid, text);
drop function if exists public.archive_fc_account(uuid);
drop function if exists public.link_fc_account_to_team(uuid, uuid);
drop function if exists public.unlink_fc_account_from_team(uuid, uuid);
drop function if exists public.update_fc_account_platform(uuid, text);
drop function if exists public.update_fc_account_avatar(uuid, text);
drop function if exists public.update_rivals_division(uuid, text);
drop function if exists public.list_my_fc_accounts();

create function public.get_my_account()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_profile public.profiles;
    v_event public.weekend_league_events;
    v_wl_manual public.user_weekend_league_progress;
    v_rivals_manual public.user_rivals_progress;
    v_team_ids jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_profile from public.profiles where id = v_user_id;
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
$$;

comment on function public.get_my_account() is
    'Dados da propria conta numa chamada so: perfil, plataformas, divisao de Rivals, times, record manual de WL/Rivals.';

revoke execute on function public.get_my_account() from public, anon;
grant execute on function public.get_my_account() to authenticated;

create function public.update_my_platforms(p_platforms text[])
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
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

    update public.profiles set platforms = v_clean where id = v_user_id;

    return v_clean;
end;
$$;

comment on function public.update_my_platforms(text[]) is
    'Substitui as plataformas do usuario. Sempre exige pelo menos uma -- lista vazia e recusada com FQ058.';

revoke execute on function public.update_my_platforms(text[]) from public, anon;
grant execute on function public.update_my_platforms(text[]) to authenticated;

create function public.update_my_rivals_division(p_division text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
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
    from public.profiles where id = v_user_id;

    update public.profiles set rivals_division = p_division where id = v_user_id;

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
$$;

revoke execute on function public.update_my_rivals_division(text) from public, anon;
grant execute on function public.update_my_rivals_division(text) to authenticated;

-- Contadores manuais: perdem o parametro de conta, identidade e sempre
-- auth.uid().
drop function if exists public.increment_rivals_manual_record(uuid, integer, integer);
create function public.increment_rivals_manual_record(
    p_win_delta integer default 0,
    p_loss_delta integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.user_rivals_progress;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    insert into public.user_rivals_progress (user_id, manual_wins, manual_losses)
    values (
        v_user_id,
        greatest(0, coalesce(p_win_delta, 0)),
        greatest(0, coalesce(p_loss_delta, 0))
    )
    on conflict (user_id) do update
        set manual_wins = greatest(0, user_rivals_progress.manual_wins + coalesce(p_win_delta, 0)),
            manual_losses = greatest(0, user_rivals_progress.manual_losses + coalesce(p_loss_delta, 0)),
            updated_at = now()
    returning * into v_row;

    return jsonb_build_object('wins', v_row.manual_wins, 'losses', v_row.manual_losses);
end;
$$;

revoke execute on function public.increment_rivals_manual_record(integer, integer)
    from public, anon;
grant execute on function public.increment_rivals_manual_record(integer, integer)
    to authenticated;

drop function if exists public.increment_weekend_league_manual_record(uuid, uuid, integer, integer);
create function public.increment_weekend_league_manual_record(
    p_event_id uuid,
    p_win_delta integer default 0,
    p_loss_delta integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_current public.user_weekend_league_progress;
    v_next_wins integer;
    v_next_losses integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_current from public.user_weekend_league_progress
    where user_id = v_user_id and weekend_league_event_id = p_event_id;

    v_next_wins := greatest(0, coalesce(v_current.manual_wins, 0) + coalesce(p_win_delta, 0));
    v_next_losses := greatest(0, coalesce(v_current.manual_losses, 0) + coalesce(p_loss_delta, 0));

    if v_next_wins + v_next_losses > public._weekend_league_max_matches() then
        raise exception 'weekend league match limit reached' using errcode = 'FQ046';
    end if;

    insert into public.user_weekend_league_progress
        (user_id, weekend_league_event_id, manual_wins, manual_losses)
    values (v_user_id, p_event_id, v_next_wins, v_next_losses)
    on conflict (user_id, weekend_league_event_id) do update
        set manual_wins = v_next_wins,
            manual_losses = v_next_losses,
            updated_at = now();

    return jsonb_build_object('wins', v_next_wins, 'losses', v_next_losses);
end;
$$;

revoke execute on function public.increment_weekend_league_manual_record(uuid, integer, integer)
    from public, anon;
grant execute on function public.increment_weekend_league_manual_record(uuid, integer, integer)
    to authenticated;

drop function if exists public.set_weekend_league_manual_record(uuid, uuid, integer, integer);
drop function if exists public.clear_weekend_league_manual_record(uuid, uuid);

create function public.set_weekend_league_manual_record(
    p_event_id uuid,
    p_wins integer,
    p_losses integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if coalesce(p_wins, 0) < 0 or coalesce(p_losses, 0) < 0
        or coalesce(p_wins, 0) + coalesce(p_losses, 0) > public._weekend_league_max_matches()
    then
        raise exception 'weekend league match limit reached' using errcode = 'FQ046';
    end if;

    insert into public.user_weekend_league_progress
        (user_id, weekend_league_event_id, manual_wins, manual_losses)
    values (v_user_id, p_event_id, coalesce(p_wins, 0), coalesce(p_losses, 0))
    on conflict (user_id, weekend_league_event_id) do update
        set manual_wins = excluded.manual_wins,
            manual_losses = excluded.manual_losses,
            updated_at = now();

    return jsonb_build_object('wins', coalesce(p_wins, 0), 'losses', coalesce(p_losses, 0));
end;
$$;

create function public.clear_weekend_league_manual_record(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    delete from public.user_weekend_league_progress
    where user_id = v_user_id and weekend_league_event_id = p_event_id;
end;
$$;

revoke execute on function public.set_weekend_league_manual_record(uuid, integer, integer)
    from public, anon;
grant execute on function public.set_weekend_league_manual_record(uuid, integer, integer)
    to authenticated;
revoke execute on function public.clear_weekend_league_manual_record(uuid)
    from public, anon;
grant execute on function public.clear_weekend_league_manual_record(uuid)
    to authenticated;

-- get_weekend_league_account_stats / get_rivals_account_stats: perdem o
-- parametro de conta.
drop function if exists public.get_weekend_league_account_stats(uuid, uuid);
create function public.get_weekend_league_account_stats(p_weekend_league_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_manual public.user_weekend_league_progress;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_manual
    from public.user_weekend_league_progress
    where user_id = v_user_id and weekend_league_event_id = p_weekend_league_event_id;

    return jsonb_build_object(
        'manual', case when v_manual.manual_wins is null then null
            else jsonb_build_object('wins', v_manual.manual_wins, 'losses', v_manual.manual_losses)
        end
    );
end;
$$;

comment on function public.get_weekend_league_account_stats(uuid) is
    'Record manual (unica fonte) de WL do usuario num evento.';

revoke execute on function public.get_weekend_league_account_stats(uuid) from public, anon;
grant execute on function public.get_weekend_league_account_stats(uuid) to authenticated;

drop function if exists public.get_rivals_account_stats(uuid);
create function public.get_rivals_account_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_manual public.user_rivals_progress;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_manual from public.user_rivals_progress where user_id = v_user_id;

    return jsonb_build_object(
        'manual', jsonb_build_object(
            'wins', coalesce(v_manual.manual_wins, 0),
            'losses', coalesce(v_manual.manual_losses, 0)
        )
    );
end;
$$;

comment on function public.get_rivals_account_stats() is
    'Record manual (unica fonte) de Rivals do usuario. All-time.';

revoke execute on function public.get_rivals_account_stats() from public, anon;
grant execute on function public.get_rivals_account_stats() to authenticated;

-- =======================================================================
-- 16. Perfil publico: volta a ser 1 por usuario. stats/aggregate computados
--     de partida real ja tinham sido removidos do produto -- so sobra o
--     record manual.
-- =======================================================================
drop function if exists public.check_public_profile_slug_available(text, uuid);
create function public.check_public_profile_slug_available(
    p_slug text,
    p_exclude_self boolean default true
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
              and (not p_exclude_self or user_id <> (select auth.uid()))
        );
$$;

comment on function public.check_public_profile_slug_available(text, boolean) is
    'Validacao em tempo real do slug. p_exclude_self exclui o PROPRIO usuario da checagem de unicidade (pode manter o slug que ja tinha).';

revoke execute on function public.check_public_profile_slug_available(text, boolean)
    from public, anon;
grant execute on function public.check_public_profile_slug_available(text, boolean)
    to authenticated;

drop function if exists public.get_my_public_profile_settings(uuid);
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
            'show_squad', true,
            'show_weekend_league', true,
            'show_rivals', true,
            'show_stats', true
        );
    end if;

    return jsonb_build_object(
        'is_enabled', v_row.is_enabled,
        'slug', v_row.slug,
        'show_squad', v_row.show_squad,
        'show_weekend_league', v_row.show_weekend_league,
        'show_rivals', v_row.show_rivals,
        'show_stats', v_row.show_stats
    );
end;
$$;

comment on function public.get_my_public_profile_settings() is
    'Le a config de perfil publico do proprio usuario. Sem linha ainda: devolve default desativado com os 4 toggles ja ligados.';

revoke execute on function public.get_my_public_profile_settings()
    from public, anon;
grant execute on function public.get_my_public_profile_settings()
    to authenticated;

drop function if exists public.update_my_public_profile_settings(
    uuid, boolean, text, boolean, boolean, boolean, boolean
);
create function public.update_my_public_profile_settings(
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

    insert into public.user_public_profiles (
        user_id, slug, is_enabled,
        show_squad, show_weekend_league, show_rivals, show_stats
    ) values (
        v_user_id, v_slug, v_is_enabled,
        coalesce(p_show_squad, true), coalesce(p_show_weekend_league, true),
        coalesce(p_show_rivals, true), coalesce(p_show_stats, true)
    )
    on conflict (user_id) do update set
        slug = excluded.slug,
        is_enabled = excluded.is_enabled,
        show_squad = excluded.show_squad,
        show_weekend_league = excluded.show_weekend_league,
        show_rivals = excluded.show_rivals,
        show_stats = excluded.show_stats,
        updated_at = now();

    return public.get_my_public_profile_settings();
end;
$$;

comment on function public.update_my_public_profile_settings(
    boolean, text, boolean, boolean, boolean, boolean
) is 'Upsert do perfil publico do usuario. Trocar o slug invalida o link antigo na mesma transacao.';

revoke execute on function public.update_my_public_profile_settings(
    boolean, text, boolean, boolean, boolean, boolean
) from public, anon;
grant execute on function public.update_my_public_profile_settings(
    boolean, text, boolean, boolean, boolean, boolean
) to authenticated;

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
    from public.profiles where id = v_row.user_id;

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
$$;

comment on function public.get_public_profile(text) is
    'Payload publico de UM usuario. is_enabled=false ou slug inexistente devolvem a mesma resposta -- nunca revela qual dos dois foi. Stats "show_stats" saiu: era so o aggregate computado de partida real, ja removido do produto.';

revoke execute on function public.get_public_profile(text) from public;
grant execute on function public.get_public_profile(text) to anon, authenticated;

-- =======================================================================
-- 17. delete_my_account: com team_members de volta a user_id, a mesma
--     regra de sucessao/dissolucao do antigo archive_fc_account -- so
--     roda por USUARIO agora, nunca em loop por conta.
-- =======================================================================
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_membership record;
    v_queue record;
    v_successor uuid;
    v_other_members integer;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    -- 1) Estado AO VIVO de matchmaking primeiro: cancela busca/sai da fila
    -- antes de qualquer outra coisa (promove quem esperava, nunca deixa
    -- "busca fantasma").
    begin
        perform public.cancel_match_search();
    exception
        when sqlstate 'FQ015' then
            null;
    end;

    for v_queue in
        select team_id, game_mode from public.match_search_queue
        where user_id = v_user_id
    loop
        begin
            perform public.leave_match_search_queue(v_queue.team_id, v_queue.game_mode);
        exception
            when sqlstate 'FQ047' then
                null;
        end;
    end loop;

    -- 2) Anonimiza historico compartilhado com o time (nunca deleta).
    update public.game_matches set user_id = null where user_id = v_user_id;
    update public.match_search_sessions set user_id = null where user_id = v_user_id;
    update public.team_invite_links set created_by = null where created_by = v_user_id;

    -- 3) Times: dissolve o time se a pessoa for OWNER unica, transfere pro
    -- membro mais antigo se houver mais gente, ou so sai.
    for v_membership in
        select team_id, role from public.team_members where user_id = v_user_id
    loop
        perform 1 from public.team_members
        where team_id = v_membership.team_id
        for update;

        select count(*) into v_other_members
        from public.team_members
        where team_id = v_membership.team_id and user_id <> v_user_id;

        if v_membership.role = 'OWNER' and v_other_members = 0 then
            delete from public.teams where id = v_membership.team_id;
        else
            if v_membership.role = 'OWNER' then
                select user_id into v_successor
                from public.team_members
                where team_id = v_membership.team_id and user_id <> v_user_id
                order by joined_at asc, user_id asc
                limit 1;

                perform public._transfer_team_ownership(
                    v_membership.team_id, v_user_id, v_successor
                );
            end if;

            delete from public.team_members
            where team_id = v_membership.team_id and user_id = v_user_id;
        end if;
    end loop;

    -- 4) Dado pessoal exclusivo: cascade cuida de fc_squads/fc_squad_slots/
    -- user_weekend_league_progress/user_rivals_progress/user_public_profiles.
    -- 5) profiles, user_devices, notification_outbox,
    -- notification_preferences, user_notifications: ON DELETE CASCADE desde
    -- que foram criados -- a Edge Function delete-account apaga auth.users
    -- via admin API logo depois que esta funcao retornar, disparando essas
    -- cascatas. Esta funcao nao tem privilegio pra apagar auth.users direto.
end;
$$;

comment on function public.delete_my_account() is
    'Prepara a conta do chamador para exclusao: cancela buscas ativas, anonimiza historico compartilhado, resolve/dissolve times (dissolve se OWNER unico, transfere pro membro mais antigo se houver mais gente). Nao apaga auth.users -- isso e feito pela Edge Function delete-account via admin API.';

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ---------------------------------------------------------------------
-- 30. Funcoes legadas que ainda liam user_fc_accounts/fc_account_teams.
--
--     Os quatro helpers abaixo sao versoes anteriores do motor de fila,
--     substituidas nesta mesma migration por _promote_next_queued_player_for_team
--     e _retry_promotion_for_user_queues. Nenhum chamador vivo aponta pra
--     elas -- so sobraram no schema porque nunca foram dropadas. Deixa-las
--     seria deixar funcao SECURITY DEFINER apontando pra tabela inexistente.
-- ---------------------------------------------------------------------
drop function if exists public._build_matchmaking_state(uuid, uuid);
drop function if exists public._fc_account_team_ids(uuid);
drop function if exists public._promote_next_queued_player(uuid);
drop function if exists public._promote_next_queued_players_for_teams(uuid[]);
drop function if exists public._data_checkup();

-- ---------------------------------------------------------------------
-- 31. get_requests_inbox: o nome da Conta FC saia junto do convite/pedido
--     para dizer "quem exatamente vai entrar". Com 1 login = 1 usuario essa
--     informacao virou o proprio display_name do usuario, entao a chave
--     fc_account_name deixa de existir no payload.
-- ---------------------------------------------------------------------
create or replace function public.get_requests_inbox()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
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
    join public.profiles as p on p.id = r.user_id
    where r.status = 'PENDING' and public.is_team_admin(r.team_id);

    return jsonb_build_object(
        'invitations_received', v_invitations,
        'join_requests_to_review', v_join_requests
    );
end;
$$;

revoke execute on function public.get_requests_inbox() from public, anon;
grant execute on function public.get_requests_inbox() to authenticated;

-- ---------------------------------------------------------------------
-- 32. _dispatch_finished_weekend_league_notifications: mesma regra de antes
--     (so quem registrou placar manual naquele evento gera anuncio), agora
--     lendo user_weekend_league_progress e os times por team_members.
-- ---------------------------------------------------------------------
create or replace function public._dispatch_finished_weekend_league_notifications()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
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
            join public.profiles as p on p.id = wl.user_id
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
$$;
