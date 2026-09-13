-- Novo valor de enum precisa da sua propria transacao/migration (Postgres
-- nao deixa usar um valor recem-criado na mesma transacao que o criou) --
-- mesmo padrao das extensoes anteriores de notification_type.
alter type public.notification_type add value 'TEAM_JOIN_REQUEST_RECEIVED';
alter type public.notification_type add value 'TEAM_JOIN_REQUEST_APPROVED';
alter type public.notification_type add value 'TEAM_JOIN_REQUEST_REJECTED';
alter type public.notification_type add value 'TEAM_INVITATION_RECEIVED';
alter type public.notification_type add value 'TEAM_INVITATION_ACCEPTED';
