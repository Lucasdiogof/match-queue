-- Categorias de preferencia (item 20/21): 5 toggles, nao 20. Matchmaking ja
-- tinha 3 colunas granulares desde a Etapa 7 (queue_turn/search_expiring/
-- search_expired) -- viram um master switch por cima delas em vez de serem
-- substituidas: desligar "Matchmaking" desliga as 3 de uma vez, mas a
-- granularidade fina continua existindo para quem um dia precisar dela nos
-- ajustes avancados. As 4 categorias novas (Times/WL/Rivals/Rankings) ganham
-- uma coluna cada, sem sub-toggle.
--
-- Importante (item 22/23): esta tabela so controla ENTREGA DE PUSH. A
-- inbox (user_notifications) nunca consulta estas colunas -- o evento
-- sempre entra na Central, preferencia desligada ou nao. So a chamada a
-- notification_outbox e condicional.

alter table public.notification_preferences
    add column matchmaking_enabled boolean not null default true,
    add column teams_enabled boolean not null default true,
    add column weekend_league_enabled boolean not null default true,
    add column rivals_enabled boolean not null default true,
    add column rankings_enabled boolean not null default true;

comment on column public.notification_preferences.matchmaking_enabled is
    'Master switch da categoria Matchmaking. Junto com as 3 colunas antigas, controla push de YOUR_TURN/SEARCH_EXPIRING/SEARCH_EXPIRED.';

-- YOUR_TURN/SEARCH_EXPIRING/SEARCH_EXPIRED passam a exigir tambem o master
-- de categoria. Ausencia de linha continua significando tudo habilitado.
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

revoke execute on function
    public._notification_allowed(uuid, public.notification_type)
    from public, anon, authenticated;
