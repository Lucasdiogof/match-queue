-- Etapa 17B, item 18/22: auditoria da fixture real (WEFUT, so teste de
-- pipeline, nunca producao) mostrou 3 coisas que o schema atual de
-- fc_player_cards nao tem onde guardar sem jogar dado fora:
--   - detailed_stats: subatributos por categoria (pace.acceleration,
--     shooting.finishing, etc.) -- 29 campos no pedido original, ja chegam
--     como um objeto JSON aninhado na fonte. jsonb generico em vez de 29
--     colunas: nada no produto consome isso ainda (Squad Builder/chemistry
--     usam so os 6 stats principais + GK, que ja sao colunas tipadas), e
--     jsonb evita uma migration nova a cada campo novo que uma fonte trouxer.
--   - playstyles_plus: distinto de playstyles (a fonte ja diferencia os
--     dois quando tem o dado -- nao faz sentido juntar).
--   - raw_provider_data: campos provider-specific que ainda nao modelamos
--     (ex.: raw_face_stats) -- fc_player_cards.raw_metadata jsonb JA existe
--     desde a criacao da tabela (Etapa 11), so nunca foi populado pelo
--     importer. Passa a ser populado a partir desta etapa, mas
--     deliberadamente NAO entra em _fc_card_json -- e um campo de
--     debug/auditoria do backend, nao algo pensado pra chegar no cliente.
-- accelerate_rate entra vazio de proposito -- nenhuma fonte auditada até
-- agora declara o valor (so aparece como conceito no source_manifest), mas
-- o schema fica pronto pra quando uma fonte trouxer, sem precisar de mais
-- uma migration so pra essa coluna.
--
-- Tudo aditivo, nullable/default seguro -- nao toca nas linhas existentes.

alter table public.fc_player_cards
    add column playstyles_plus text[] not null default '{}',
    add column detailed_stats jsonb not null default '{}'::jsonb,
    add column accelerate_rate text;

comment on column public.fc_player_cards.detailed_stats is
    'Subatributos por categoria (pace.acceleration, shooting.finishing, etc.) quando a fonte fornece -- generico de proposito, ver auditoria da Etapa 17B.';

comment on column public.fc_player_cards.raw_metadata is
    'Campos provider-specific ainda nao modelados como coluna propria. Nunca megabytes por linha -- so o que a fonte ja trouxe como metadata pontual. Coluna existe desde a criacao da tabela (Etapa 11); passou a ser populada e exposta a partir da Etapa 17B.';

create or replace function public._fc_card_json(p_card public.fc_player_cards)
returns jsonb
language sql
stable
set search_path = ''
as $$
    select jsonb_build_object(
        'id', p_card.id,
        'provider', p_card.provider,
        'game_version', p_card.game_version,
        'player_name', p_card.player_name,
        'common_name', p_card.common_name,
        'rating', p_card.rating,
        'primary_position', p_card.primary_position,
        'alternative_positions', to_jsonb(p_card.alternative_positions),
        'pace', p_card.pace,
        'shooting', p_card.shooting,
        'passing', p_card.passing,
        'dribbling', p_card.dribbling,
        'defending', p_card.defending,
        'physical', p_card.physical,
        'gk_diving', p_card.gk_diving,
        'gk_handling', p_card.gk_handling,
        'gk_kicking', p_card.gk_kicking,
        'gk_reflexes', p_card.gk_reflexes,
        'gk_speed', p_card.gk_speed,
        'gk_positioning', p_card.gk_positioning,
        'skill_moves', p_card.skill_moves,
        'weak_foot', p_card.weak_foot,
        'playstyles', to_jsonb(p_card.playstyles),
        'playstyles_plus', to_jsonb(p_card.playstyles_plus),
        'detailed_stats', p_card.detailed_stats,
        'accelerate_rate', p_card.accelerate_rate,
        'height_cm', p_card.height_cm,
        'preferred_foot', p_card.preferred_foot,
        'player_roles', to_jsonb(p_card.player_roles),
        'rarity', p_card.rarity,
        'player_image_url', p_card.player_image_url,
        'card_image_url', p_card.card_image_url,
        'club_name', coalesce(
            (select cl.name from public.fc_clubs as cl where cl.id = p_card.club_id),
            p_card.club_name
        ),
        'league_name', coalesce(
            (select l.name from public.fc_leagues as l where l.id = p_card.league_id),
            p_card.league_name
        ),
        'nation_name', coalesce(
            (select n.name from public.fc_nations as n where n.id = p_card.nation_id),
            p_card.nation_name
        ),
        'card_type', p_card.card_type,
        'fc_player_id', p_card.fc_player_id,
        'fc_player', (
            select jsonb_build_object(
                'id', pl.id,
                'name', pl.name,
                'common_name', pl.common_name,
                'primary_position', pl.primary_position,
                'image_url', pl.image_url,
                'nation_name', (
                    select n.name from public.fc_nations as n where n.id = pl.nation_id
                ),
                'club_name', (
                    select cl.name from public.fc_clubs as cl where cl.id = pl.club_id
                ),
                'league_name', (
                    select l.name from public.fc_leagues as l where l.id = pl.league_id
                )
            )
            from public.fc_players as pl
            where pl.id = p_card.fc_player_id
        )
    );
$$;
