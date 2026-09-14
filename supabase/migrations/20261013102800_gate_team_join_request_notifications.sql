-- TEAM_JOIN_REQUEST_RECEIVED/APPROVED/REJECTED nao eram filtrados por
-- nenhuma preferencia (caiam no "else true" generico) -- a categoria
-- "Times" na tela de Notificacoes so cobria TEAM_MEMBER_JOINED. Como essa
-- categoria virou, na pratica, "convites/pedidos de time" pro usuario,
-- os tres tipos passam a respeitar o mesmo teams_enabled.
create or replace function public._notification_allowed(
    p_user_id uuid,
    p_type public.notification_type
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select case p_type
        when 'YOUR_TURN' then coalesce(
            (select matchmaking_enabled and queue_turn_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'PRIORITY_REQUESTED' then coalesce(
            (select matchmaking_enabled and priority_requested_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRING' then coalesce(
            (select matchmaking_enabled and search_expiring_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRED' then coalesce(
            (select matchmaking_enabled and search_expired_enabled
             from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_MEMBER_JOINED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_RECEIVED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_APPROVED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_JOIN_REQUEST_REJECTED' then coalesce(
            (select teams_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_LEADER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_SCORER_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'TEAM_TOP_ASSIST_CHANGED' then coalesce(
            (select rankings_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'WEEKEND_LEAGUE_FINISHED' then coalesce(
            (select weekend_league_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'RIVALS_DIVISION_CHANGED' then coalesce(
            (select rivals_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        else true
    end;
$$;
