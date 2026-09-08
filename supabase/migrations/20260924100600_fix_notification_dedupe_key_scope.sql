-- Auditoria da Etapa 15 encontrou um bug real: dedupe_key era unico GLOBAL
-- (por linha, nao por usuario) em user_notifications e notification_outbox.
-- Isso nunca deu problema nos 3 tipos da Etapa 7 (YOUR_TURN/SEARCH_EXPIRING/
-- SEARCH_EXPIRED) porque cada evento la so tem UM destinatario (quem estava
-- na vez da fila). A Etapa 15 introduziu eventos de fan-out: um Time inteiro
-- e notificado do mesmo evento (novo lider/artilheiro/assistente, membro
-- novo, Weekend League encerrada, divisao do Rivals). Todos os membros do
-- loop usam o MESMO dedupe_key (o evento e um so) -- so muda o user_id.
-- Com o indice antigo, o primeiro insert "ganhava" a chave e todos os outros
-- membros eram descartados em silencio pelo on conflict, nunca recebendo a
-- notificacao. Confirmado ao vivo em QA: de 4 destinatarios esperados para
-- uma troca de artilheiro, so 1 recebeu.
--
-- Correcao: a chave de idempotencia sempre foi "por usuario", nunca global
-- -- so nao tinha ficado explicito enquanto todo evento era 1:1. Trocando
-- para unique (user_id, dedupe_key) em ambas as tabelas, cada destinatario
-- do mesmo evento tem sua propria linha, e o retry continua idempotente
-- (mesmo usuario + mesmo dedupe_key = descartado).

drop index public.user_notifications_dedupe_key_idx;
create unique index user_notifications_user_dedupe_key_idx
    on public.user_notifications (user_id, dedupe_key);

drop index public.notification_outbox_dedupe_key_idx;
create unique index notification_outbox_user_dedupe_key_idx
    on public.notification_outbox (user_id, dedupe_key);

create or replace function public._enqueue_notification(
    p_user_id uuid,
    p_type public.notification_type,
    p_team_id uuid,
    p_session_id uuid,
    p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.notification_outbox (
        user_id, type, team_id, session_id, payload, dedupe_key
    )
    values (
        p_user_id,
        p_type,
        p_team_id,
        p_session_id,
        coalesce(p_payload, '{}'::jsonb),
        p_type::text || ':' || coalesce(p_session_id::text, gen_random_uuid()::text)
    )
    on conflict (user_id, dedupe_key) do nothing;
end;
$$;

revoke execute on function public._enqueue_notification(
    uuid, public.notification_type, uuid, uuid, jsonb
) from public, anon, authenticated;

create or replace function public._emit_user_notification(
    p_user_id uuid,
    p_category public.app_notification_category,
    p_type public.notification_type,
    p_dedupe_key text,
    p_title_key text,
    p_params jsonb default '{}'::jsonb,
    p_deep_link_type text default null,
    p_deep_link_params jsonb default '{}'::jsonb,
    p_source_entity_type text default null,
    p_source_entity_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_inbox_id uuid;
begin
    if p_user_id is null then
        return;
    end if;

    insert into public.user_notifications (
        user_id, category, type, title_key, params,
        deep_link_type, deep_link_params,
        source_entity_type, source_entity_id, dedupe_key
    )
    values (
        p_user_id, p_category, p_type::text, p_title_key, coalesce(p_params, '{}'::jsonb),
        p_deep_link_type, coalesce(p_deep_link_params, '{}'::jsonb),
        p_source_entity_type, p_source_entity_id, p_dedupe_key
    )
    on conflict (user_id, dedupe_key) do nothing
    returning id into v_inbox_id;

    -- Retry que ja gravou a inbox no passado nao gera um segundo push
    -- (item 28): so ha o que entregar quando a linha e realmente nova.
    if v_inbox_id is null then
        return;
    end if;

    if not public._notification_allowed(p_user_id, p_type) then
        return;
    end if;

    -- Payload pequeno de proposito (item 44): so o suficiente para o
    -- worker montar o data payload do FCM. Texto de push continua sendo
    -- resolvido pelo worker a partir de type + locale, nunca gravado aqui.
    insert into public.notification_outbox (
        user_id, type, payload, dedupe_key
    )
    values (
        p_user_id, p_type,
        jsonb_build_object('notification_id', v_inbox_id) || coalesce(p_params, '{}'::jsonb),
        'inbox:' || p_dedupe_key
    )
    on conflict (user_id, dedupe_key) do nothing;
end;
$$;

revoke execute on function public._emit_user_notification(
    uuid, public.app_notification_category, public.notification_type,
    text, text, jsonb, text, jsonb, text, uuid
) from public, anon, authenticated;
