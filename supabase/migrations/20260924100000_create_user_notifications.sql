-- Etapa 15: inbox de notificacoes do usuario.
--
-- A notification_outbox (Etapa 7) e fila de ENTREGA (push), efemera por
-- natureza: processed_at marca "ja tentei mandar", nao "o usuario devia
-- poder consultar isso depois". Misturar as duas responsabilidades faria a
-- outbox virar historico de produto e a tabela operacional inchar para
-- sempre. user_notifications e tabela nova, dedicada a "o que a pessoa quer
-- poder abrir e reler" -- a Central de Notificacoes.
--
-- category e coluna separada de type: preferencia e por categoria (5
-- toggles, item 20), tipo e granular (para icone/copy/deep link). Nao dava
-- para derivar categoria de type no cliente sem duplicar essa tabela de
-- mapeamento nos dois lados.

create type public.app_notification_category as enum (
    'MATCHMAKING',
    'TEAMS',
    'WEEKEND_LEAGUE',
    'RIVALS',
    'RANKINGS'
);

create table public.user_notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    category public.app_notification_category not null,
    type text not null,

    -- Texto e sempre type + params, nunca frase pronta (item 70): o Flutter
    -- resolve a string via l10n a partir de title_key/params, o mesmo padrao
    -- ja usado em toda a UI. O servidor so grava dados, nunca copy PT/EN/ES.
    title_key text not null,
    params jsonb not null default '{}'::jsonb,

    -- Destino opcional. O tipo por si so ja e suficiente pra resolver a rota
    -- na maioria dos casos (item 42); os params carregam os ids quando o
    -- destino precisa de mais que o proprio evento.
    deep_link_type text,
    deep_link_params jsonb not null default '{}'::jsonb,

    -- Rastreia de onde o evento veio, sem FK: o time/partida/conta pode ser
    -- apagado depois e a notificacao antiga continua legivel (copy vem dos
    -- params, capturados no momento do evento, nunca por join tardio).
    source_entity_type text,
    source_entity_id uuid,

    -- Idempotencia (itens 27/28). Todo emissor calcula essa chave
    -- deterministicamente a partir do evento -- nunca um uuid aleatorio.
    dedupe_key text not null,

    created_at timestamptz not null default now(),
    read_at timestamptz
);

comment on table public.user_notifications is
    'Central de notificacoes do usuario. Existe por evento relevante o bastante para reconsultar depois -- nao e log tecnico nem espelho da outbox de entrega.';
comment on column public.user_notifications.dedupe_key is
    'Idempotencia por evento. Insercao repetida do mesmo dedupe_key e descartada.';

create unique index user_notifications_dedupe_key_idx
    on public.user_notifications (dedupe_key);

-- Ordem de leitura da inbox: mais nova primeiro, id como desempate
-- determinístico (keyset pagination, item 30).
create index user_notifications_user_created_idx
    on public.user_notifications (user_id, created_at desc, id desc);

-- So o que falta contar pro badge (item 31).
create index user_notifications_unread_idx
    on public.user_notifications (user_id)
    where read_at is null;

alter table public.user_notifications enable row level security;

-- So o dono le (item 57). Nao ha policy de insert/update/delete: quem
-- escreve e as RPCs security definer abaixo e os emissores de evento --
-- nunca o cliente diretamente (item 56).
create policy user_notifications_select_own
    on public.user_notifications
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_notifications from anon, authenticated;
grant select on table public.user_notifications to authenticated;

-- ---------------------------------------------------------------------
-- Read model paginado (item 29/30): keyset por (created_at, id), nunca
-- offset. Mesmo formato de retorno usado no historico de matchmaking.
-- ---------------------------------------------------------------------
create function public.list_my_notifications(
    p_limit integer default 20,
    p_cursor_created_at timestamptz default null,
    p_cursor_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 30));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (order by n.created_at desc, n.id desc) as ord,
            jsonb_build_object(
                'id', n.id,
                'category', n.category,
                'type', n.type,
                'title_key', n.title_key,
                'params', n.params,
                'deep_link_type', n.deep_link_type,
                'deep_link_params', n.deep_link_params,
                'created_at', to_jsonb(n.created_at),
                'read_at', to_jsonb(n.read_at)
            ) as item,
            n.created_at,
            n.id
        from public.user_notifications as n
        where n.user_id = v_user_id
          and (
              p_cursor_created_at is null
              or p_cursor_id is null
              or (n.created_at, n.id) < (p_cursor_created_at, p_cursor_id)
          )
        order by n.created_at desc, n.id desc
        limit v_limit + 1
    ) as page;

    v_items := case
        when v_count > v_limit then
            (select jsonb_agg(value)
             from jsonb_array_elements(v_rows) with ordinality as t(value, i)
             where i <= v_limit)
        else v_rows
    end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case
            when v_count > v_limit then jsonb_build_object(
                'created_at', v_items -> (v_limit - 1) -> 'created_at',
                'id', v_items -> (v_limit - 1) -> 'id'
            )
            else null
        end
    );
end;
$$;

comment on function public.list_my_notifications(integer, timestamptz, uuid) is
    'Central de notificacoes do chamador, paginada por keyset (created_at, id).';

revoke execute on function public.list_my_notifications(integer, timestamptz, uuid)
    from public, anon;
grant execute on function public.list_my_notifications(integer, timestamptz, uuid)
    to authenticated;

create function public.get_my_unread_notification_count()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
    select count(*)::integer
    from public.user_notifications
    where user_id = (select auth.uid()) and read_at is null;
$$;

revoke execute on function public.get_my_unread_notification_count()
    from public, anon;
grant execute on function public.get_my_unread_notification_count()
    to authenticated;

-- Idempotente: notificacao ja lida ou de outro usuario nao levanta erro,
-- so nao faz nada (item 32/57 -- ownership sem vazar existencia da linha).
create function public.mark_notification_read(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.user_notifications
    set read_at = now()
    where id = p_id
      and user_id = (select auth.uid())
      and read_at is null;
end;
$$;

revoke execute on function public.mark_notification_read(uuid) from public, anon;
grant execute on function public.mark_notification_read(uuid) to authenticated;

create function public.mark_all_notifications_read()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.user_notifications
    set read_at = now()
    where user_id = (select auth.uid()) and read_at is null;
end;
$$;

revoke execute on function public.mark_all_notifications_read() from public, anon;
grant execute on function public.mark_all_notifications_read() to authenticated;
