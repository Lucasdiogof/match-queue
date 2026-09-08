-- Etapa 15 (itens 6/44): a outbox de push ganha os tipos sociais/esportivos
-- novos. ALTER TYPE ... ADD VALUE fica em migration propria, sozinha: um
-- valor novo de enum so pode ser usado em comandos de uma transacao
-- POSTERIOR a que o criou, nunca na mesma. Combinar com o uso (RPCs,
-- funcoes) na mesma migration quebraria a aplicacao.

alter type public.notification_type add value 'TEAM_MEMBER_JOINED';
alter type public.notification_type add value 'TEAM_LEADER_CHANGED';
alter type public.notification_type add value 'TEAM_TOP_SCORER_CHANGED';
alter type public.notification_type add value 'TEAM_TOP_ASSIST_CHANGED';
alter type public.notification_type add value 'WEEKEND_LEAGUE_FINISHED';
alter type public.notification_type add value 'RIVALS_DIVISION_CHANGED';
