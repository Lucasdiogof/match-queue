-- O record de Weekend League é por ELENCO, não por usuário -- um usuário
-- com 3 elencos tem 3 records diferentes na mesma campanha (item 23/45). A
-- versão da Etapa 8.5 (por user_id) nunca foi consumida em produção real,
-- então dropar e recriar aqui é seguro -- nenhum dado de usuário se perde,
-- só o formato do override manual muda de dono.

drop function if exists public.set_weekend_league_manual_record(uuid, integer, integer);
drop function if exists public.get_weekend_league_record(uuid);
drop table if exists public.weekend_league_manual_records;

create table public.fc_account_weekend_league_progress (
    fc_account_id uuid not null
        references public.user_fc_accounts (id) on delete cascade,
    weekend_league_event_id uuid not null
        references public.weekend_league_events (id) on delete cascade,
    manual_wins integer,
    manual_losses integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    primary key (fc_account_id, weekend_league_event_id),
    constraint fc_account_wl_progress_manual_pairing
        check ((manual_wins is null) = (manual_losses is null)),
    constraint fc_account_wl_progress_manual_non_negative
        check (
            (manual_wins is null or manual_wins >= 0)
            and (manual_losses is null or manual_losses >= 0)
        )
);

comment on table public.fc_account_weekend_league_progress is
    'Override manual do record de WL por elenco+evento. Computado vem de game_matches, nunca somado ao manual.';

create trigger fc_account_wl_progress_set_updated_at
    before update on public.fc_account_weekend_league_progress
    for each row
    execute function public.set_updated_at();

alter table public.fc_account_weekend_league_progress enable row level security;
revoke all on table public.fc_account_weekend_league_progress
    from anon, authenticated, public;

-- Record do elenco no evento: computado das partidas FINISHED do elenco +
-- o override manual, se houver. p_event_id null = evento atual.
create function public.get_weekend_league_record(
    p_fc_account_id uuid,
    p_event_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_event public.weekend_league_events;
    v_wins integer;
    v_losses integer;
    v_manual public.fc_account_weekend_league_progress;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if p_event_id is null then
        v_event := public.get_current_weekend_league_event();
    else
        select * into v_event from public.weekend_league_events where id = p_event_id;
    end if;

    if v_event.id is null then
        return jsonb_build_object('event', null);
    end if;

    select
        count(*) filter (where result = 'WIN'),
        count(*) filter (where result = 'LOSS')
    into v_wins, v_losses
    from public.game_matches
    where fc_account_id = p_fc_account_id
      and weekend_league_event_id = v_event.id
      and status = 'FINISHED';

    select * into v_manual from public.fc_account_weekend_league_progress
    where fc_account_id = p_fc_account_id and weekend_league_event_id = v_event.id;

    return jsonb_build_object(
        'event', jsonb_build_object(
            'id', v_event.id,
            'number', v_event.number,
            'season', v_event.season,
            'starts_at', to_jsonb(v_event.starts_at),
            'ends_at', to_jsonb(v_event.ends_at)
        ),
        'computed', jsonb_build_object('wins', v_wins, 'losses', v_losses),
        'manual', case when v_manual.manual_wins is null then null
            else jsonb_build_object('wins', v_manual.manual_wins, 'losses', v_manual.manual_losses)
        end
    );
end;
$$;

-- Define o override manual do elenco no evento. wins/losses null limpa
-- (item 29: "usar resultado das partidas" volta a mostrar o computado).
create function public.set_weekend_league_manual_record(
    p_fc_account_id uuid,
    p_event_id uuid,
    p_wins integer,
    p_losses integer
)
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

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if p_wins is null or p_losses is null then
        delete from public.fc_account_weekend_league_progress
        where fc_account_id = p_fc_account_id and weekend_league_event_id = p_event_id;
        return;
    end if;

    if p_wins < 0 or p_losses < 0 then
        raise exception 'invalid record' using errcode = 'FQ024';
    end if;

    insert into public.fc_account_weekend_league_progress
        (fc_account_id, weekend_league_event_id, manual_wins, manual_losses)
    values (p_fc_account_id, p_event_id, p_wins, p_losses)
    on conflict (fc_account_id, weekend_league_event_id) do update
        set manual_wins = excluded.manual_wins,
            manual_losses = excluded.manual_losses,
            updated_at = now();
end;
$$;

create function public.clear_weekend_league_manual_record(
    p_fc_account_id uuid,
    p_event_id uuid
)
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

    delete from public.fc_account_weekend_league_progress p
    where p.fc_account_id = p_fc_account_id
      and p.weekend_league_event_id = p_event_id
      and exists (
          select 1 from public.user_fc_accounts a
          where a.id = p.fc_account_id and a.user_id = v_user_id
      );
end;
$$;

revoke execute on function public.get_weekend_league_record(uuid, uuid) from public, anon;
revoke execute on function public.set_weekend_league_manual_record(uuid, uuid, integer, integer) from public, anon;
revoke execute on function public.clear_weekend_league_manual_record(uuid, uuid) from public, anon;

grant execute on function public.get_weekend_league_record(uuid, uuid) to authenticated;
grant execute on function public.set_weekend_league_manual_record(uuid, uuid, integer, integer) to authenticated;
grant execute on function public.clear_weekend_league_manual_record(uuid, uuid) to authenticated;
