-- Tokens FCM por dispositivo.
--
-- Um usuario tem N tokens (iPhone, Android, Web, segundo celular), entao
-- isso nunca poderia ser uma coluna em profiles.
--
-- NAO existe device_id proprio de proposito: o token FCM ja identifica a
-- instalacao de forma unica e e rotacionado pelo proprio Firebase. Um id
-- adicional so teria valor se fosse fingerprint de hardware -- invasivo e
-- desnecessario -- ou um uuid aleatorio guardado no cliente, que seria
-- apenas uma segunda copia do que o token ja diz.
--
-- Token e dado sensivel: quem tem o token de alguem consegue mandar push
-- para aquela pessoa. Por isso nao ha leitura cruzada nem grant de escrita
-- direta -- registro e baixa acontecem por RPC.

create type public.device_platform as enum ('ANDROID', 'IOS', 'WEB');

create table public.user_devices (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete cascade,
    fcm_token text not null,
    platform public.device_platform not null,
    is_active boolean not null default true,
    last_seen_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint user_devices_token_not_blank check (btrim(fcm_token) <> '')
);

comment on table public.user_devices is
    'Tokens FCM ativos por usuario. Escrita so via register_device/deactivate_device.';

-- Um token pertence a no maximo um usuario por vez. Se outra conta logar no
-- mesmo aparelho, register_device reatribui esta linha em vez de criar uma
-- segunda -- e o que impede push da conta anterior continuar chegando.
create unique index user_devices_fcm_token_key
    on public.user_devices (fcm_token);

create index user_devices_active_by_user_idx
    on public.user_devices (user_id)
    where is_active;

create trigger user_devices_set_updated_at
    before update on public.user_devices
    for each row
    execute function public.set_updated_at();

alter table public.user_devices enable row level security;

-- Leitura apenas dos proprios aparelhos (a tela de ajustes pode querer
-- listar "onde voce esta conectado"). Sem policy de insert/update/delete:
-- as duas RPCs abaixo sao o unico caminho de escrita.
create policy user_devices_select_own
    on public.user_devices
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_devices from anon;
grant select on table public.user_devices to authenticated;

-- Registro/renovacao do token do aparelho atual.
--
-- security definer porque o upsert pode precisar tomar o token de outro
-- usuario (mesmo aparelho, conta diferente), o que a RLS do chamador
-- jamais permitiria. O dono resultante e sempre auth.uid(): nao existe
-- parametro de usuario.
create function public.register_device(
    p_fcm_token text,
    p_platform public.device_platform
)
returns public.user_devices
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_token text := btrim(coalesce(p_fcm_token, ''));
    v_device public.user_devices;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if v_token = '' then
        raise exception 'fcm token is required' using errcode = 'FQ019';
    end if;

    insert into public.user_devices as d (user_id, fcm_token, platform)
    values (v_user_id, v_token, p_platform)
    on conflict (fcm_token) do update
        set user_id = v_user_id,
            platform = p_platform,
            is_active = true,
            last_seen_at = now()
    returning * into v_device;

    return v_device;
end;
$$;

comment on function public.register_device(text, public.device_platform) is
    'Registra/renova o token FCM do aparelho para o usuario autenticado.';

-- Baixa do token. Precisa ser chamada ANTES do signOut, enquanto a sessao
-- ainda existe. Idempotente: token inexistente ou de outra pessoa nao faz
-- nada e nao levanta erro.
create function public.deactivate_device(p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.user_devices
    set is_active = false
    where fcm_token = btrim(coalesce(p_fcm_token, ''))
      and user_id = v_user_id;
end;
$$;

comment on function public.deactivate_device(text) is
    'Desativa o token do aparelho atual. Chamar antes do signOut.';

revoke execute on function
    public.register_device(text, public.device_platform) from public, anon;
revoke execute on function public.deactivate_device(text) from public, anon;

grant execute on function
    public.register_device(text, public.device_platform) to authenticated;
grant execute on function public.deactivate_device(text) to authenticated;
