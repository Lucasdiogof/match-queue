-- Plataforma (PC/PS/XBOX) do elenco -- opcional, escolhida na criacao ou
-- editada depois. So 3 valores porque e so o que importa pro produto hoje:
-- pre-selecionar a aba certa (Consoles/PC) na consulta de preco de mercado
-- (feature Mercado) -- la, PS e Xbox ja compartilham o mesmo mercado
-- ("Consoles"), so PC diverge de verdade, entao nao ha necessidade de
-- distinguir PS de Xbox pra esse uso. Catalogo por CHECK, mesmo padrao de
-- rivals_division -- se um dia precisar separar PS/Xbox, e um ALTER de
-- constraint, nunca uma migracao de enum.
alter table public.user_fc_accounts
    add column platform text;

alter table public.user_fc_accounts
    add constraint user_fc_accounts_platform_check
    check (platform is null or platform in ('PC', 'PS', 'XBOX'));

comment on column public.user_fc_accounts.platform is
    'Plataforma que o usuario joga com este elenco -- PC, PS ou XBOX. Opcional (null = nao informado).';

-- RPC dedicada, mesmo padrao de update_rivals_division: um campo, uma RPC,
-- nunca sobrecarregando update_fc_account (que so cuida do nome).
create function public.update_fc_account_platform(p_id uuid, p_platform text)
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

    if p_platform is not null and p_platform not in ('PC', 'PS', 'XBOX') then
        raise exception 'invalid platform' using errcode = 'FQ058';
    end if;

    update public.user_fc_accounts
    set platform = p_platform
    where id = p_id and user_id = v_user_id
    returning * into v_account;

    if v_account.id is null then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return v_account;
end;
$$;

revoke execute on function public.update_fc_account_platform(uuid, text) from public, anon;
grant execute on function public.update_fc_account_platform(uuid, text) to authenticated;

-- list_my_fc_accounts ganha 'platform' no JSON de cada conta -- resto do
-- corpo identico ao da ultima versao (20261013102900_fc_account_avatar.sql).
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
            'platform', a.platform,
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
