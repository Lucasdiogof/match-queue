-- Rivals e Champions deixam de depender de partida real registrada
-- (game_matches) para o placar que a UI mostra. Granularidade por partida
-- (data, gols, quem marcou) era "perfumaria" para quem só quer acompanhar
-- 15-0 ou 125-1 -- pedido explícito do dono do produto para simplificar
-- para um contador manual com +1 vitória / +1 derrota.
--
-- Rivals nunca teve override manual (só existia o computado de
-- game_matches) -- esta migration cria a tabela e as RPCs do zero, no
-- mesmo formato que Champions já usa desde 20260916100300.
create table public.fc_account_rivals_progress (
    fc_account_id uuid primary key
        references public.user_fc_accounts (id) on delete cascade,
    manual_wins integer not null default 0,
    manual_losses integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint fc_account_rivals_progress_non_negative
        check (manual_wins >= 0 and manual_losses >= 0)
);

comment on table public.fc_account_rivals_progress is
    'Contador manual (+1 vitoria / +1 derrota) de Division Rivals por elenco. All-time, sem season/semana modelada.';

create trigger fc_account_rivals_progress_set_updated_at
    before update on public.fc_account_rivals_progress
    for each row
    execute function public.set_updated_at();

alter table public.fc_account_rivals_progress enable row level security;
revoke all on table public.fc_account_rivals_progress
    from anon, authenticated, public;

-- Incrementa (ou decrementa, delta negativo) o contador manual de Rivals.
-- Nunca deixa ir abaixo de zero. Upsert: primeira chamada de uma conta cria
-- a linha partindo de 0-0.
create function public.increment_rivals_manual_record(
    p_fc_account_id uuid,
    p_win_delta integer default 0,
    p_loss_delta integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.fc_account_rivals_progress;
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

    insert into public.fc_account_rivals_progress
        (fc_account_id, manual_wins, manual_losses)
    values (
        p_fc_account_id,
        greatest(0, coalesce(p_win_delta, 0)),
        greatest(0, coalesce(p_loss_delta, 0))
    )
    on conflict (fc_account_id) do update
        set manual_wins = greatest(
                0, fc_account_rivals_progress.manual_wins + coalesce(p_win_delta, 0)
            ),
            manual_losses = greatest(
                0, fc_account_rivals_progress.manual_losses + coalesce(p_loss_delta, 0)
            ),
            updated_at = now()
    returning * into v_row;

    return jsonb_build_object('wins', v_row.manual_wins, 'losses', v_row.manual_losses);
end;
$$;

revoke execute on function public.increment_rivals_manual_record(uuid, integer, integer)
    from public, anon;
grant execute on function public.increment_rivals_manual_record(uuid, integer, integer)
    to authenticated;

-- Mesma ideia para Champions, incremental em vez de exigir digitar os dois
-- números toda vez. Continua limitado a 15 jogos por campanha (mesma regra
-- de 20261002100200_weekend_league_match_limit.sql, FQ046).
create function public.increment_weekend_league_manual_record(
    p_fc_account_id uuid,
    p_event_id uuid,
    p_win_delta integer default 0,
    p_loss_delta integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_current public.fc_account_weekend_league_progress;
    v_next_wins integer;
    v_next_losses integer;
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

    select * into v_current from public.fc_account_weekend_league_progress
    where fc_account_id = p_fc_account_id and weekend_league_event_id = p_event_id;

    v_next_wins := greatest(0, coalesce(v_current.manual_wins, 0) + coalesce(p_win_delta, 0));
    v_next_losses := greatest(0, coalesce(v_current.manual_losses, 0) + coalesce(p_loss_delta, 0));

    if v_next_wins + v_next_losses > public._weekend_league_max_matches() then
        raise exception 'weekend league match limit reached' using errcode = 'FQ046';
    end if;

    insert into public.fc_account_weekend_league_progress
        (fc_account_id, weekend_league_event_id, manual_wins, manual_losses)
    values (p_fc_account_id, p_event_id, v_next_wins, v_next_losses)
    on conflict (fc_account_id, weekend_league_event_id) do update
        set manual_wins = v_next_wins,
            manual_losses = v_next_losses,
            updated_at = now();

    return jsonb_build_object('wins', v_next_wins, 'losses', v_next_losses);
end;
$$;

revoke execute on function public.increment_weekend_league_manual_record(uuid, uuid, integer, integer)
    from public, anon;
grant execute on function public.increment_weekend_league_manual_record(uuid, uuid, integer, integer)
    to authenticated;

-- get_rivals_account_stats ganha o manual ao lado do aggregate computado
-- (mesmo par computed/manual que Champions ja devolve) -- a UI passa a
-- mostrar so o manual, mas o computado continua disponivel/intacto.
create or replace function public.get_rivals_account_stats(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_manual public.fc_account_rivals_progress;
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

    select * into v_manual from public.fc_account_rivals_progress
    where fc_account_id = p_fc_account_id;

    return jsonb_build_object(
        'aggregate', public._fc_account_match_aggregate(p_fc_account_id, 'DIVISION_RIVALS', null),
        'manual', jsonb_build_object(
            'wins', coalesce(v_manual.manual_wins, 0),
            'losses', coalesce(v_manual.manual_losses, 0)
        ),
        'top_scorers', public._fc_account_player_leaderboard(
            p_fc_account_id, 'DIVISION_RIVALS', null, false, 10
        ),
        'top_assists', public._fc_account_player_leaderboard(
            p_fc_account_id, 'DIVISION_RIVALS', null, true, 10
        )
    );
end;
$$;

-- list_my_fc_accounts ganha o contador manual de Rivals ao lado do de
-- Champions, pro card da tela da Conta nao precisar de uma segunda chamada.
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
