-- Historico nao carregava: "Algo deu errado no servidor".
--
-- Causa: public.get_team_activity_history existia DUAS vezes.
--
-- 20260915100300 criou a versao de 10 argumentos. 20260916100400 fez
-- "create or replace function" acrescentando p_fc_account_id -- e mudar a
-- lista de parametros NAO substitui, cria uma sobrecarga. A de 10 ficou orfa
-- no banco desde entao.
--
-- O cliente omite parametros nulos, entao a chamada tipica sai so com
-- p_team_id e p_limit e casa com as duas assinaturas: o PostgREST nao tem
-- como escolher e devolve erro (PGRST203), que a UI mostra como falha
-- generica de servidor.
--
-- A versao viva e a de 11 argumentos (replaced por 20260917100700, com
-- p_fc_account_id default null): ela aceita todas as chamadas que a antiga
-- aceitava, entao remover a orfa nao muda comportamento nenhum -- so
-- desfaz a ambiguidade.

drop function if exists public.get_team_activity_history(
    uuid,
    integer,
    timestamptz,
    uuid,
    text,
    text,
    text,
    uuid,
    timestamptz,
    timestamptz
);
