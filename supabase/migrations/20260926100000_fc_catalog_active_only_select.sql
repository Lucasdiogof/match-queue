-- Etapa 17B, item 0: a Etapa 17 encontrou (e este import real do catalogo
-- confirma de novo, direto no schema remoto via pg_policies) que
-- fc_players/fc_player_cards tem select using (true) para authenticated,
-- sem filtrar is_active -- mesmo a RPC search_fc_player_cards ja filtrando
-- desde a Etapa 11. Qualquer client autenticado le carta/jogador inativo
-- direto via PostgREST, contornando a RPC.
--
-- Fix escolhido: trocar a policy para using (is_active = true) em vez de
-- revogar o grant e forcar tudo por RPC. Motivo: SupabasePlayerCardCatalogRepository.getCard
-- (features/fc_squads) le fc_player_cards direto por id via .from() -- e um
-- read model legitimo e continua funcionando sem mudanca nenhuma no Flutter,
-- so deixa de conseguir devolver uma linha inativa. fc_players nao tem
-- nenhum .from() direto no cliente hoje, mas ganha a mesma politica por
-- simetria e pra fechar o caminho antes do catalogo real (com cartas
-- descontinuadas de verdade) entrar.

drop policy fc_player_cards_select_authenticated on public.fc_player_cards;
create policy fc_player_cards_select_active
    on public.fc_player_cards for select to authenticated
    using (is_active = true);

drop policy fc_players_select_authenticated on public.fc_players;
create policy fc_players_select_active
    on public.fc_players for select to authenticated
    using (is_active = true);
