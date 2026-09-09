-- Etapa 17B-2: segundo achado ao vivo na mesma sessao da migration anterior
-- (grants pro service_role). Rodando tool/sync_fc_cards.dart de verdade via
-- PostgREST (nunca exercitado antes -- todo import real anterior passou por
-- SQL manual via `supabase db query`, que aceita `on conflict (...) where
-- ...` repetindo o predicado a mao), todo upsert real falhou com:
--
--   ERROR 42P10: there is no unique or exclusion constraint matching the
--   ON CONFLICT specification
--
-- Causa: os 5 indices unicos de identidade externa do catalogo
-- (fc_players_provider_idx, fc_player_cards_provider_idx,
-- fc_clubs_provider_idx, fc_leagues_provider_idx, fc_nations_provider_idx)
-- sao PARCIAIS (`where <coluna> is not null`). O parametro `on_conflict=`
-- do PostgREST gera `ON CONFLICT (colunas) DO UPDATE ...` sem nenhum
-- predicado -- Postgres so aceita inferir um indice parcial como arbiter
-- quando o predicado e repetido explicitamente na clausula ON CONFLICT, o
-- que o PostgREST nao faz (nem tem como, via query param generico). Ou
-- seja: nenhum desses 5 upserts jamais poderia funcionar de verdade pelo
-- caminho HTTP que o importer usa, so pelo caminho SQL direto -- um
-- problema estrutural que so apareceu agora porque e a primeira vez que
-- alguem rodou o importer real com credencial de escrita de verdade.
--
-- Correcao: os 5 viram indices unicos SIMPLES (sem where). Isso NAO muda
-- nenhum comportamento pratico -- UNIQUE no Postgres ja trata NULL como
-- distinto de qualquer outro valor (inclusive de outro NULL) por padrao,
-- entao "permitir N linhas com a coluna nula" ja era garantido pelo
-- indice simples sem precisar do predicado parcial. O `where ... is not
-- null` nunca fazia diferenca de comportamento, so quebrava a
-- compatibilidade com PostgREST.

drop index public.fc_players_provider_idx;
create unique index fc_players_provider_idx
    on public.fc_players (provider, game_version, provider_player_id);

drop index public.fc_player_cards_provider_idx;
create unique index fc_player_cards_provider_idx
    on public.fc_player_cards (provider, provider_card_id);

drop index public.fc_clubs_provider_idx;
create unique index fc_clubs_provider_idx
    on public.fc_clubs (provider, provider_club_id);

drop index public.fc_leagues_provider_idx;
create unique index fc_leagues_provider_idx
    on public.fc_leagues (provider, provider_league_id);

drop index public.fc_nations_provider_idx;
create unique index fc_nations_provider_idx
    on public.fc_nations (provider, provider_nation_id);
