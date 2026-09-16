-- Mesmo gotcha de sempre: BYPASSRLS do service_role nao supre o GRANT de
-- tabela. Necessario para as consultas diagnosticas do redesenho de
-- team_members (fc_account_id) e para qualquer Edge Function futura nessa
-- area.
grant select on table public.team_members to service_role;
grant select on table public.fc_account_teams to service_role;
grant select on table public.user_fc_accounts to service_role;
grant select on table public.teams to service_role;
