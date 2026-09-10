-- Novo valor de enum precisa da sua propria transacao/migration (Postgres
-- nao deixa usar um valor de enum recem-criado na mesma transacao que o
-- criou) -- mesmo padrao das 6 extensoes anteriores de notification_type.
alter type public.notification_type add value 'PRIORITY_REQUESTED';
