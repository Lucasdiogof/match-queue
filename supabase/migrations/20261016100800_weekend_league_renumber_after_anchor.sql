-- Complemento de 20261016100700. Aquela migration moveu o anchor e apagou
-- as semanas anteriores a ele, mas ensure_weekend_league_events() voltou 0
-- linhas inseridas: as semanas a partir de 25/09 JA existiam (a geracao
-- antiga tambem cria semanas pra frente, p_weeks_forward=2), e o
-- "on conflict (starts_at) do nothing" preservou cada uma delas com o
-- number calculado pelo anchor ANTIGO.
--
-- Resultado: 25/09 sobreviveu numerada como se a temporada tivesse comecado
-- em 28/08 -- o app mostraria "#5" em vez de "#1".
--
-- number nunca foi dado de entrada: e sempre derivado de
-- (starts_at - anchor). Recalcular a partir do anchor atual e por isso
-- seguro e idempotente -- rodar de novo com o anchor certo nao muda nada.
update public.weekend_league_events
set number = 1 + (
        extract(
            epoch from (starts_at - public._weekend_league_season_anchor())
        ) / 604800
    )::int
where starts_at >= public._weekend_league_season_anchor();

-- Garante que nada anterior ao anchor tenha sobrado (a 20261016100700 ja
-- limpou; repetido aqui so pra esta migration ser autossuficiente caso
-- alguem rode as duas fora de ordem num ambiente novo).
delete from public.weekend_league_events
where starts_at < public._weekend_league_season_anchor();
