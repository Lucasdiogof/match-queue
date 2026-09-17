-- =====================================================================
-- CHECKUP pos-migrations (100900 + 101000 + 102000)
--
-- So LE o banco -- nao altera nada, pode rodar quantas vezes quiser.
-- Uma linha por verificacao. Olhe a coluna `status`:
--   OK     = como esperado
--   FALHA  = precisa de acao
--   AVISO  = esperado, mas vale saber
--
-- A lista de RPCs do bloco 9 e gerada a partir das chamadas reais do app
-- Flutter, com os parametros que ele de fato envia.
-- =====================================================================
with

mortas as (
    select t.nome, to_regclass('public.' || t.nome) is null as ok
    from (values
        ('user_fc_accounts'), ('fc_account_teams'),
        ('fc_account_weekend_league_progress'), ('fc_account_rivals_progress'),
        ('game_match_player_stats'), ('team_sports_leaders_state')
    ) as t(nome)
),

vivas as (
    select t.nome, to_regclass('public.' || t.nome) is not null as ok
    from (values
        ('profiles'), ('teams'), ('team_members'), ('fc_squads'),
        ('user_weekend_league_progress'), ('user_rivals_progress'),
        ('match_search_sessions'), ('match_search_queue'),
        ('team_join_requests'), ('team_invitations'), ('user_public_profiles')
    ) as t(nome)
),

colunas_orfas as (
    select table_name || '.' || column_name as alvo
    from information_schema.columns
    where table_schema = 'public' and column_name = 'fc_account_id'
),

colunas_novas as (
    select c.nome,
           exists (
               select 1 from information_schema.columns
               where table_schema = 'public' and table_name = 'profiles'
                 and column_name = c.nome
           ) as ok
    from (values ('platforms'), ('rivals_division')) as c(nome)
),

pk_team_members as (
    select coalesce(string_agg(a.attname, ', ' order by k.ord), '(sem PK)') as cols
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    cross join lateral unnest(c.conkey) with ordinality as k(attnum, ord)
    join pg_attribute a on a.attrelid = t.oid and a.attnum = k.attnum
    where n.nspname = 'public' and t.relname = 'team_members' and c.contype = 'p'
),

funcs_nome as (
    select p.proname
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname like '%fc_account%'
),

funcs_corpo as (
    -- prosrc inclui os comentarios do corpo, e comentario citando o nome
    -- antigo e documentacao, nao dependencia. Tira os `--` antes de casar,
    -- senao o check acusa funcao sadia.
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and regexp_replace(p.prosrc, '--.*', '', 'gn')
          ~ '(user_fc_accounts|fc_account_teams|fc_account_id)'
),

sobrecargas as (
    select p.proname, count(*) as n
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
    group by p.proname having count(*) > 1
),

rpc_app(nome, params) as (values
    ('approve_team_join_request', array['p_request_id']::text[]),
    ('archive_fc_squad', array['p_squad_id']::text[]),
    ('cancel_match_search', array[]::text[]),
    ('cancel_team_join_request', array['p_request_id']::text[]),
    ('check_public_profile_slug_available', array['p_slug']::text[]),
    ('clear_fc_squad_slot', array['p_slot_code','p_slot_type','p_squad_id']::text[]),
    ('clear_fc_squad_slots', array['p_squad_id']::text[]),
    ('clear_weekend_league_manual_record', array['p_event_id']::text[]),
    ('create_fc_squad', array['p_formation_code','p_name']::text[]),
    ('deactivate_device', array['p_fcm_token']::text[]),
    ('get_fc_club_catalog_summary', array['p_limit']::text[]),
    ('get_fc_club_summary', array['p_club_id']::text[]),
    ('get_fc_playstyle_summary', array[]::text[]),
    ('get_fc_squad_builder', array['p_squad_id']::text[]),
    ('get_my_account', array[]::text[]),
    ('get_my_matchmaking_status', array['p_game_mode','p_team_id']::text[]),
    ('get_my_public_profile_settings', array[]::text[]),
    ('get_my_unread_notification_count', array[]::text[]),
    ('get_or_create_team_invite', array['p_team_id']::text[]),
    ('get_public_profile', array['p_identifier']::text[]),
    ('get_public_team', array['p_team_id']::text[]),
    ('get_requests_inbox', array[]::text[]),
    ('get_rivals_account_stats', array[]::text[]),
    ('get_team_activity_history', array['p_cursor_id','p_cursor_occurred_at','p_from','p_limit','p_search_status','p_team_id','p_to','p_user_id']::text[]),
    ('get_team_member_profile', array['p_team_id','p_user_id']::text[]),
    ('get_team_player_statuses', array['p_team_id']::text[]),
    ('get_team_sent_invitations', array['p_team_id']::text[]),
    ('get_weekend_league_account_stats', array['p_weekend_league_event_id']::text[]),
    ('increment_rivals_manual_record', array['p_loss_delta','p_win_delta']::text[]),
    ('increment_weekend_league_manual_record', array['p_event_id','p_loss_delta','p_win_delta']::text[]),
    ('invite_team_member', array['p_slug','p_team_id']::text[]),
    ('join_team_by_invite', array['p_code']::text[]),
    ('leave_match_search_queue', array['p_game_mode','p_team_id']::text[]),
    ('list_fc_clubs', array['p_gender','p_limit','p_offset','p_query']::text[]),
    ('list_fc_squads', array[]::text[]),
    ('list_my_notifications', array['p_cursor_created_at','p_cursor_id','p_limit']::text[]),
    ('list_public_teams', array['p_limit']::text[]),
    ('list_weekend_league_events', array[]::text[]),
    ('mark_all_notifications_read', array[]::text[]),
    ('mark_notification_read', array['p_id']::text[]),
    ('preview_fc_squad_lineup', array['p_formation_code','p_manager_id','p_manager_league_id','p_slots','p_squad_id']::text[]),
    ('register_device', array['p_fcm_token','p_platform']::text[]),
    ('reject_team_join_request', array['p_request_id']::text[]),
    ('remove_team_member', array['p_target_user_id','p_team_id']::text[]),
    ('report_match_found_and_start_game', array[]::text[]),
    ('request_match_search', array['p_fc_squad_id','p_game_mode','p_team_id']::text[]),
    ('request_match_search_priority', array['p_game_mode','p_team_id']::text[]),
    ('request_team_join', array['p_team_id']::text[]),
    ('resolve_invite_target', array['p_slug']::text[]),
    ('resolve_team_invite', array['p_code']::text[]),
    ('respond_team_invitation', array['p_accept','p_invitation_id']::text[]),
    ('revoke_team_invitation', array['p_invitation_id']::text[]),
    ('revoke_team_invite', array['p_team_id']::text[]),
    ('rotate_team_invite', array['p_team_id']::text[]),
    ('save_fc_squad_lineup', array['p_expected_updated_at','p_formation_code','p_manager_id','p_manager_league_id','p_slots','p_squad_id']::text[]),
    ('search_fc_managers', array['p_nation_id','p_query']::text[]),
    ('search_fc_player_cards', array['p_card_type','p_club_id','p_club_name','p_exclude_card_ids','p_gender','p_league_name','p_limit','p_max_rating','p_min_rating','p_nation_name','p_offset','p_playstyle','p_playstyle_plus_only','p_position','p_positions','p_query']::text[]),
    ('set_default_fc_squad', array['p_squad_id']::text[]),
    ('set_fc_squad_formation', array['p_formation_code','p_squad_id']::text[]),
    ('set_fc_squad_manager', array['p_manager_id','p_manager_league_id','p_squad_id']::text[]),
    ('set_fc_squad_slot', array['p_player_card_id','p_slot_code','p_slot_type','p_squad_id']::text[]),
    ('set_team_member_role', array['p_role','p_target_user_id','p_team_id']::text[]),
    ('set_team_visibility', array['p_is_public','p_team_id']::text[]),
    ('set_weekend_league_manual_record', array['p_event_id','p_losses','p_wins']::text[]),
    ('swap_fc_squad_slots', array['p_from_code','p_from_type','p_squad_id','p_to_code','p_to_type']::text[]),
    ('transfer_team_ownership', array['p_target_user_id','p_team_id']::text[]),
    ('update_fc_squad', array['p_name','p_squad_id']::text[]),
    ('update_my_platforms', array['p_platforms']::text[]),
    ('update_my_public_profile_settings', array['p_is_enabled','p_show_rivals','p_show_squad','p_show_stats','p_show_weekend_league','p_slug']::text[]),
    ('update_my_rivals_division', array['p_division']::text[]),
    ('update_team_search_duration', array['p_seconds','p_team_id']::text[])
),

rpc_check as (
    select r.nome,
           p.oid is not null as existe,
           array(
               select unnest(r.params)
               except
               select unnest(coalesce(p.proargnames, array[]::text[]))
           ) as faltando
    from rpc_app r
    left join lateral (
        select pp.oid, pp.proargnames
        from pg_proc pp join pg_namespace nn on nn.oid = pp.pronamespace
        where nn.nspname = 'public' and pp.proname = r.nome
        order by pp.pronargs desc
        limit 1
    ) p on true
),

contagens as (
    select 'auth.users' as tabela, count(*)::bigint as n from auth.users
    union all select 'profiles', count(*) from public.profiles
    union all select 'teams', count(*) from public.teams
    union all select 'team_members', count(*) from public.team_members
    union all select 'fc_squads', count(*) from public.fc_squads
    union all select 'match_search_sessions', count(*) from public.match_search_sessions
),

bucket as (
    select exists (select 1 from storage.buckets where id = 'fc-account-avatars') as ainda_existe
)

select * from (
    select 1 as ord, 'tabela removida: ' || nome as verificacao,
           case when ok then 'OK' else 'FALHA' end as status,
           case when ok then 'sumiu' else 'AINDA EXISTE' end as detalhe
    from mortas

    union all
    select 2, 'tabela presente: ' || nome,
           case when ok then 'OK' else 'FALHA' end,
           case when ok then 'existe' else 'NAO EXISTE' end
    from vivas

    union all
    select 3, 'coluna fc_account_id em qualquer tabela',
           case when count(*) = 0 then 'OK' else 'FALHA' end,
           case when count(*) = 0 then 'nenhuma sobrou' else string_agg(alvo, ', ') end
    from colunas_orfas

    union all
    select 4, 'coluna profiles.' || nome,
           case when ok then 'OK' else 'FALHA' end,
           case when ok then 'criada' else 'FALTANDO' end
    from colunas_novas

    union all
    select 5, 'PK de team_members', case when cols = 'team_id, user_id' then 'OK' else 'FALHA' end, cols
    from pk_team_members

    union all
    select 6, 'funcao com fc_account no nome',
           case when count(*) = 0 then 'OK' else 'FALHA' end,
           case when count(*) = 0 then 'nenhuma' else string_agg(proname, ', ') end
    from funcs_nome

    union all
    select 7, 'funcao cujo corpo cita objeto removido',
           case when count(*) = 0 then 'OK' else 'FALHA' end,
           case when count(*) = 0 then 'nenhuma' else string_agg(sig, ' | ') end
    from funcs_corpo

    union all
    select 8, 'funcao com sobrecarga duplicada',
           case when count(*) = 0 then 'OK' else 'AVISO' end,
           case when count(*) = 0 then 'nenhuma'
                else string_agg(proname || ' (x' || n || ')', ', ') end
    from sobrecargas

    union all
    select 9, 'RPC que o app chama e nao existe no banco',
           case when count(*) = 0 then 'OK' else 'FALHA' end,
           case when count(*) = 0
                then 'todas as ' || (select count(*)::text from rpc_app) || ' existem'
                else string_agg(nome, ', ') end
    from rpc_check where not existe

    union all
    select 10, 'RPC sem um parametro que o app envia',
           case when count(*) = 0 then 'OK' else 'FALHA' end,
           case when count(*) = 0 then 'nenhuma'
                else string_agg(nome || ' -> ' || array_to_string(faltando, ' + '), ' | ') end
    from rpc_check where existe and cardinality(faltando) > 0

    union all
    select 11, 'linhas em ' || tabela,
           case when n = 0 then 'OK' else 'AVISO' end,
           n::text || ' linha(s)'
    from contagens

    union all
    select 12, 'bucket fc-account-avatars',
           case when ainda_existe then 'AVISO' else 'OK' end,
           case when ainda_existe then 'apagar a mao: Dashboard > Storage'
                else 'ja removido' end
    from bucket
) as r
order by case status when 'FALHA' then 0 when 'AVISO' then 1 else 2 end,
         ord, verificacao;
