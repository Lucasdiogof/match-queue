-- service_role bypassa RLS (BYPASSRLS) mas isso nao supre o grant de
-- tabela em si, que e uma camada separada do Postgres -- sem isto, so a
-- RPC read model (security definer, roda como o dono da function) consegue
-- ler esta tabela; consultas diretas via service role (debug, Edge
-- Function futura) falhavam com permission denied. Mesmo gotcha ja visto
-- em market_price_cache.
grant select on table public.weekend_league_events to service_role;
