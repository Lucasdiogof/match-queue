-- fc_managers nunca teve grant explicito pra service_role (as outras
-- tabelas do catalogo -- fc_nations/fc_leagues/fc_player_cards -- tambem
-- nao tem, mas nunca precisaram: so fc_managers ganhou um importador
-- server-side agora). Sem o grant, ate o service_role (que so ignora RLS,
-- nao GRANT de tabela) toma 42501 "permission denied" tentando escrever.
grant select, insert, update on table public.fc_managers to service_role;
