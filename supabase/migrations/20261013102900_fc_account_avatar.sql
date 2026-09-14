-- Foto por Conta FC -- times ja tem logo, jogador (perfil publico) ja tem
-- avatar do proprio usuario; faltava a Conta em si poder ter uma imagem.
-- Mesmo padrao de team-logos (20261013101800): bucket publico, path fixo
-- '<fc_account_id>/avatar.<ext>' (upsert nunca acumula lixo), escrita so do
-- DONO da conta (user_fc_accounts.user_id).
alter table public.user_fc_accounts add column avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'fc-account-avatars', 'fc-account-avatars', true, 2097152,
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy fc_account_avatars_insert_owner_only
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'fc-account-avatars'
        and exists (
            select 1 from public.user_fc_accounts
            where id = ((storage.foldername(name))[1])::uuid
              and user_id = (select auth.uid())
        )
    );

create policy fc_account_avatars_update_owner_only
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'fc-account-avatars'
        and exists (
            select 1 from public.user_fc_accounts
            where id = ((storage.foldername(name))[1])::uuid
              and user_id = (select auth.uid())
        )
    )
    with check (
        bucket_id = 'fc-account-avatars'
        and exists (
            select 1 from public.user_fc_accounts
            where id = ((storage.foldername(name))[1])::uuid
              and user_id = (select auth.uid())
        )
    );

create policy fc_account_avatars_delete_owner_only
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'fc-account-avatars'
        and exists (
            select 1 from public.user_fc_accounts
            where id = ((storage.foldername(name))[1])::uuid
              and user_id = (select auth.uid())
        )
    );

-- p_avatar_url null = remove a foto (volta pras iniciais no cliente).
create function public.update_fc_account_avatar(p_id uuid, p_avatar_url text)
returns public.user_fc_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_account public.user_fc_accounts;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    update public.user_fc_accounts
    set avatar_url = p_avatar_url
    where id = p_id and user_id = v_user_id
    returning * into v_account;

    if v_account.id is null then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return v_account;
end;
$$;

comment on function public.update_fc_account_avatar(uuid, text) is
    'Define ou remove (p_avatar_url null) a foto da Conta FC. So o dono altera.';

revoke execute on function public.update_fc_account_avatar(uuid, text)
    from public, anon;
grant execute on function public.update_fc_account_avatar(uuid, text)
    to authenticated;

-- list_my_fc_accounts ganha avatar_url ao lado do resto do resumo por conta.
create or replace function public.list_my_fc_accounts()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_event public.weekend_league_events;
    v_result jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    v_event := public.get_current_weekend_league_event();

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', a.id,
            'name', a.name,
            'avatar_url', a.avatar_url,
            'is_active', a.is_active,
            'rivals_division', a.rivals_division,
            'team_ids', coalesce((
                select jsonb_agg(t.team_id)
                from public.fc_account_teams t
                where t.fc_account_id = a.id
            ), '[]'::jsonb),
            'weekend_league_computed_wins', (
                select count(*) from public.game_matches g
                where g.fc_account_id = a.id
                  and v_event.id is not null
                  and g.weekend_league_event_id = v_event.id
                  and g.status = 'FINISHED' and g.result = 'WIN'
            ),
            'weekend_league_computed_losses', (
                select count(*) from public.game_matches g
                where g.fc_account_id = a.id
                  and v_event.id is not null
                  and g.weekend_league_event_id = v_event.id
                  and g.status = 'FINISHED' and g.result = 'LOSS'
            ),
            'weekend_league_manual', (
                select jsonb_build_object('wins', p.manual_wins, 'losses', p.manual_losses)
                from public.fc_account_weekend_league_progress p
                where p.fc_account_id = a.id
                  and v_event.id is not null
                  and p.weekend_league_event_id = v_event.id
                  and p.manual_wins is not null
            ),
            'rivals_manual', (
                select jsonb_build_object('wins', r.manual_wins, 'losses', r.manual_losses)
                from public.fc_account_rivals_progress r
                where r.fc_account_id = a.id
            )
        )
        order by a.created_at
    ), '[]'::jsonb)
    into v_result
    from public.user_fc_accounts a
    where a.user_id = v_user_id and a.is_active;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'accounts', v_result,
        'weekend_league_event', case when v_event.id is null then null else jsonb_build_object(
            'id', v_event.id,
            'number', v_event.number,
            'starts_at', to_jsonb(v_event.starts_at),
            'ends_at', to_jsonb(v_event.ends_at)
        ) end
    );
end;
$$;
