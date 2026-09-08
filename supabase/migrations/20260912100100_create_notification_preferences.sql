-- Preferencias de notificacao por usuario.
--
-- Tres chaves, uma por alerta que realmente existe hoje. Nao ha toggle para
-- MATCH_FOUND nem CANCELLED porque esses eventos nao geram push nenhum: o
-- proprio jogador foi quem agiu, e os companheiros com o app aberto ja veem
-- pelo Realtime.
--
-- A linha e criada junto com o profile, mas o worker NAO depende disso: um
-- usuario sem linha e tratado como "tudo ligado". A tabela e preferencia,
-- nao pre-requisito de entrega.

create table public.notification_preferences (
    user_id uuid primary key references public.profiles (id) on delete cascade,
    queue_turn_enabled boolean not null default true,
    search_expiring_enabled boolean not null default true,
    search_expired_enabled boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.notification_preferences is
    'Toggles de push por usuario. Ausencia da linha significa tudo habilitado.';

create trigger notification_preferences_set_updated_at
    before update on public.notification_preferences
    for each row
    execute function public.set_updated_at();

alter table public.notification_preferences enable row level security;

create policy notification_preferences_select_own
    on public.notification_preferences
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

-- Insert proprio permite o "lazy ensure" do app para contas criadas antes
-- desta migration, sem precisar de RPC.
create policy notification_preferences_insert_own
    on public.notification_preferences
    for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

create policy notification_preferences_update_own
    on public.notification_preferences
    for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

revoke all on table public.notification_preferences from anon;
grant select, insert, update
    on table public.notification_preferences to authenticated;

-- Passa a criar tambem as preferencias, mantendo um unico mecanismo de
-- "o que nasce junto com a conta". Continua defensiva do mesmo jeito: erro
-- aqui vira warning e o signup segue.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    candidate text;
begin
    candidate := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));

    if candidate = '' then
        candidate := btrim(coalesce(new.raw_user_meta_data ->> 'name', ''));
    end if;

    if candidate = '' then
        candidate := btrim(split_part(coalesce(new.email, ''), '@', 1));
    end if;

    candidate := left(candidate, 32);

    if char_length(candidate) < 2 then
        candidate := 'Jogador';
    end if;

    insert into public.profiles (id, display_name)
    values (new.id, candidate)
    on conflict (id) do nothing;

    insert into public.notification_preferences (user_id)
    values (new.id)
    on conflict (user_id) do nothing;

    return new;
exception
    when others then
        raise warning 'handle_new_user falhou para % (%): %',
            new.id, sqlstate, sqlerrm;
        return new;
end;
$$;

-- Contas que ja existiam antes desta migration.
insert into public.notification_preferences (user_id)
select id from public.profiles
on conflict (user_id) do nothing;
