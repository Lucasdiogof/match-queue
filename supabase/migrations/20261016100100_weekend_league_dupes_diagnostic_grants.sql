-- Mesmo gotcha de sempre (BYPASSRLS do service_role nao supre GRANT de
-- tabela): necessario para diagnosticar duplicatas em weekend_league_events
-- geradas por um efeito colateral do fix de horario do Champions.
grant select on table public.game_matches to service_role;
grant select on table public.fc_account_weekend_league_progress to service_role;
