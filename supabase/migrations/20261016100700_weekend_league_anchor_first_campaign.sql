-- O Champions estava 4 semanas adiantado: o app mostrava "#4" quando a
-- primeira campanha ainda nem comecou.
--
-- Causa: o numero da campanha e derivado, nao armazenado --
--     number = 1 + (semana - anchor) / 7 dias
-- e _weekend_league_season_anchor() ainda apontava pro placeholder original
-- (2026-09-01, que cai na sexta 28/08/2026 18h). A migration
-- 20261013103600 corrigiu a JANELA pra sexta 18h -> segunda 4h e ate
-- escreveu a regra no proprio comentario ("primeira campanha 25/09 ->
-- 28/09"), mas nao moveu o anchor -- entao 28/08 continuou sendo a #1.
--
-- Por que so apagar as linhas nao resolveria: list_weekend_league_events
-- chama ensure_weekend_league_events() sozinha quando alguem abre o
-- seletor de semanas, e a geracao deriva tudo do anchor. Sem corrigir o
-- anchor primeiro, as mesmas 4 semanas erradas voltariam na primeira
-- abertura da tela.

-- 1) Anchor na primeira campanha de verdade. 2026-09-25 e sexta; passar um
-- horario ja dentro da janela (20h) e floorar com a mesma funcao usada em
-- todo lugar evita repetir a aritmetica de fuso aqui.
create or replace function public._weekend_league_season_anchor()
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select public._weekend_league_week_start(timestamptz '2026-09-25 20:00:00-03');
$$;

comment on function public._weekend_league_season_anchor() is
    'Inicio da campanha #1 do Champions: sexta 25/09/2026 18h (America/Sao_Paulo). Toda numeracao de semana e contada a partir daqui.';

-- 2) Limpa o que foi gerado com o anchor antigo. Recortado por
-- "antes do anchor" em vez de um delete solto: idempotente (rodar de novo
-- nao apaga nada novo) e incapaz de encostar numa campanha legitima de
-- 25/09 em diante.
--
-- Cascata conferida antes: fc_account_weekend_league_progress e o registro
-- de WL do time somem junto (contadores manuais dessas semanas, que nunca
-- deveriam ter existido); game_matches.weekend_league_event_id e SET NULL,
-- entao nenhuma partida jogada e perdida -- so deixa de estar pendurada
-- numa campanha que nao existe.
delete from public.weekend_league_events
where starts_at < public._weekend_league_season_anchor();

-- 3) Regenera a partir do anchor novo. O filtro interno
-- (week_start >= anchor) faz esta chamada criar so a #1 enquanto hoje for
-- antes de 25/09 -- nenhuma semana passada e inventada.
select public.ensure_weekend_league_events();
