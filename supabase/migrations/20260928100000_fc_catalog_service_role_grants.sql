-- Etapa 17B-2: achado ao vivo, com credencial real, rodando
-- tool/sync_fc_cards.dart pela primeira vez de verdade contra o Supabase
-- remoto (todas as escritas anteriores tinham passado por SQL manual via
-- CLI ou pelo app via RPC -- nunca por este caminho).
--
-- O importer fala direto com o PostgREST autenticado como service_role
-- (nunca por RPC, de proposito -- ele que faz a resolucao de
-- fc_player_id/club_id/league_id/nation_id por nome, upsert em lote,
-- etc.). Todo outro caminho de escrita deste projeto passa por funcao
-- security definer, que roda com o privilegio do dono da funcao -- entao
-- nunca precisou de grant de tabela pra nenhum role alem de quem criou o
-- schema. service_role nunca tinha sido grantado direto nestas tabelas
-- porque nunca tinha sido usado assim antes.
--
-- BYPASSRLS do service_role (default da plataforma Supabase) pula as
-- policies de row-level security, mas nao substitui o grant de objeto --
-- sem select/insert/update na tabela, o Postgres nega antes mesmo de
-- chegar em RLS. Confirmado ao vivo: `GET .../fc_player_cards` retornou
-- 403 42501 "permission denied for table fc_player_cards", com o proprio
-- Postgres sugerindo exatamente o grant abaixo no hint do erro.
--
-- Escopo minimo, nada alem do que o importer de fato faz: select (ler
-- ids existentes por provider/nome), insert e update (upsert via
-- on_conflict) -- nunca delete, o importer so desativa (is_active=false),
-- nunca apaga linha. Nunca concedido a anon/authenticated -- essas
-- continuam exatamente como estavam (select-only via RLS, sem policy de
-- escrita nenhuma).

grant select, insert, update on table public.fc_players to service_role;
grant select, insert, update on table public.fc_player_cards to service_role;
grant select, insert, update on table public.fc_clubs to service_role;
grant select, insert, update on table public.fc_leagues to service_role;
grant select, insert, update on table public.fc_nations to service_role;
