-- API do worker + disparo.
--
-- LATENCIA: um cron de 1 minuto seria inaceitavel para "sua vez" numa
-- janela de busca de 3 minutos -- o alerta chegaria com um terco do tempo ja
-- gasto. Por isso o disparo principal e um trigger que usa pg_net para
-- avisar o worker assim que a outbox recebe linha: pg_net enfileira a
-- requisicao e um background worker a executa, entao o Postgres NUNCA fica
-- esperando resposta HTTP segurando o lock do time. O cron continua
-- existindo, mas rebaixado a rede de seguranca.

create extension if not exists pg_net;

-- URL e segredo do worker moram no Vault, nunca em coluna comum nem no Git.
-- Enquanto nao estiverem configurados, o disparo simplesmente nao acontece e
-- a outbox acumula -- que e o comportamento correto antes do Firebase
-- existir: nada quebra, nada se perde.
create function public._notification_worker_secret(p_name text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_value text;
begin
    select decrypted_secret into v_value
    from vault.decrypted_secrets
    where name = p_name
    limit 1;
    return v_value;
exception
    when others then
        return null;
end;
$$;

revoke execute on function public._notification_worker_secret(text)
    from public, anon, authenticated;

create function public._notify_worker()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_url text := public._notification_worker_secret('notification_worker_url');
    v_secret text := public._notification_worker_secret('notification_worker_secret');
begin
    if v_url is null or v_secret is null then
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-worker-secret', v_secret
        ),
        body := jsonb_build_object('trigger', 'outbox'),
        timeout_milliseconds := 5000
    );
exception
    when others then
        -- Entrega e best effort: falhar aqui nao pode derrubar a promocao
        -- que acabou de acontecer. O cron de seguranca pega o evento depois.
        raise warning 'dispatch do worker de notificacao falhou: %', sqlerrm;
end;
$$;

create function public._dispatch_notification_worker()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public._notify_worker();
    return null;
end;
$$;

-- FOR EACH STATEMENT: uma transacao que enfileira varias notificacoes gera
-- um unico aviso ao worker, nao um por linha.
create trigger notification_outbox_dispatch
    after insert on public.notification_outbox
    for each statement
    execute function public._dispatch_notification_worker();

revoke execute on function public._notify_worker()
    from public, anon, authenticated;
revoke execute on function public._dispatch_notification_worker()
    from public, anon, authenticated;

create function public._notification_allowed(
    p_user_id uuid,
    p_type public.notification_type
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    -- Ausencia de linha = tudo habilitado.
    select case p_type
        when 'YOUR_TURN' then coalesce(
            (select queue_turn_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRING' then coalesce(
            (select search_expiring_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        when 'SEARCH_EXPIRED' then coalesce(
            (select search_expired_enabled from public.notification_preferences
             where user_id = p_user_id), true)
        else true
    end;
$$;

revoke execute on function
    public._notification_allowed(uuid, public.notification_type)
    from public, anon, authenticated;

-- Reserva um lote para este worker.
--
-- FOR UPDATE SKIP LOCKED impede que duas execucoes simultaneas peguem a
-- mesma linha. Alem disso o proprio claim empurra available_at para frente
-- (lease): se o worker morrer no meio, a linha volta a ficar elegivel
-- sozinha, sem precisar de nenhum processo de limpeza.
--
-- O que nao tem como ser entregue e resolvido aqui mesmo, em SQL, em vez de
-- virar tentativa eterna: preferencia desligada e usuario sem aparelho ativo
-- viram processed com o motivo registrado.
create function public.claim_notification_batch(p_limit integer default 20)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_ids uuid[];
    v_result jsonb;
begin
    with candidate as (
        select id
        from public.notification_outbox
        where processed_at is null
          and available_at <= now()
          and attempt_count < 5
        order by created_at
        limit greatest(1, least(coalesce(p_limit, 20), 100))
        for update skip locked
    ),
    claimed as (
        update public.notification_outbox o
        set attempt_count = o.attempt_count + 1,
            available_at = now()
                + make_interval(secs => 60 * (o.attempt_count + 1))
        from candidate c
        where o.id = c.id
        returning o.id
    )
    select coalesce(array_agg(id), array[]::uuid[]) into v_ids from claimed;

    if array_length(v_ids, 1) is null then
        return '[]'::jsonb;
    end if;

    update public.notification_outbox o
    set processed_at = now(), last_error = 'suppressed_by_preference'
    where o.id = any(v_ids)
      and o.processed_at is null
      and not public._notification_allowed(o.user_id, o.type);

    update public.notification_outbox o
    set processed_at = now(), last_error = 'no_active_device'
    where o.id = any(v_ids)
      and o.processed_at is null
      and not exists (
          select 1 from public.user_devices d
          where d.user_id = o.user_id and d.is_active
      );

    -- O texto nao vem daqui: o worker resolve PT/EN/ES a partir do type e do
    -- locale. Guardar frase pronta na outbox impediria localizar.
    select coalesce(jsonb_agg(item), '[]'::jsonb) into v_result
    from (
        select jsonb_build_object(
            'id', o.id,
            'type', o.type,
            'team_id', o.team_id,
            'session_id', o.session_id,
            'payload', o.payload,
            'locale', coalesce(p.locale, 'en'),
            'tokens', (
                select coalesce(jsonb_agg(d.fcm_token), '[]'::jsonb)
                from public.user_devices d
                where d.user_id = o.user_id and d.is_active
            )
        ) as item
        from public.notification_outbox o
        join public.profiles p on p.id = o.user_id
        where o.id = any(v_ids) and o.processed_at is null
        order by o.created_at
    ) as rows;

    return v_result;
end;
$$;

create function public.complete_notification(
    p_id uuid,
    p_success boolean,
    p_error text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if p_success then
        update public.notification_outbox
        set processed_at = now(), last_error = null
        where id = p_id;
        return;
    end if;

    -- Falha temporaria continua pendente e volta pelo backoff do lease.
    -- Depois de 5 tentativas para de tentar: fica marcada como processada
    -- com o ultimo erro, servindo de auditoria em vez de lixo eterno.
    update public.notification_outbox
    set last_error = p_error,
        processed_at = case when attempt_count >= 5 then now() else null end
    where id = p_id;
end;
$$;

-- Chamada pelo worker quando o FCM responde UNREGISTERED/INVALID_ARGUMENT:
-- token morto para de ser tentado em vez de falhar para sempre.
create function public.deactivate_device_token(p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.user_devices
    set is_active = false
    where fcm_token = p_fcm_token;
end;
$$;

revoke execute on function public.claim_notification_batch(integer)
    from public, anon, authenticated;
revoke execute on function public.complete_notification(uuid, boolean, text)
    from public, anon, authenticated;
revoke execute on function public.deactivate_device_token(text)
    from public, anon, authenticated;

-- Somente o worker (service_role, dentro da Edge Function) processa a fila.
grant execute on function public.claim_notification_batch(integer)
    to service_role;
grant execute on function public.complete_notification(uuid, boolean, text)
    to service_role;
grant execute on function public.deactivate_device_token(text)
    to service_role;

-- Rede de seguranca: cobre o intervalo em que o pg_net falhou ou o worker
-- estava fora do ar. Nao e o caminho principal, por isso 60s basta.
create function public.dispatch_pending_notifications()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not exists (
        select 1 from public.notification_outbox
        where processed_at is null and available_at <= now()
    ) then
        return;
    end if;

    perform public._notify_worker();
end;
$$;

revoke execute on function public.dispatch_pending_notifications()
    from public, anon, authenticated;

-- pg_cron aceita intervalo em segundos so ate 59; um minuto cheio precisa
-- da expressao cron classica.
select cron.schedule(
    'notification-outbox-dispatch',
    '* * * * *',
    $$select public.dispatch_pending_notifications();$$
);
