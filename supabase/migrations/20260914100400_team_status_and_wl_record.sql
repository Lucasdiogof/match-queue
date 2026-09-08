-- Status de cada jogador do time para a tela Time. Derivado das tabelas que
-- já existem, sem presença ainda (Online/Ativo há X min fica para uma etapa
-- própria — inventar presença com heurística fraca seria mentir). Precedência:
-- IN_MATCH > SEARCHING > QUEUED > NONE. IN_MATCH é global (≤1 por usuário);
-- SEARCHING/QUEUED são deste time.
create function public.get_team_player_statuses(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_members jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', m.user_id,
            'display_name', coalesce(p.display_name, ''),
            'avatar_url', p.avatar_url,
            'role', m.role,
            'status', case
                when exists (
                    select 1 from public.game_matches g
                    where g.user_id = m.user_id and g.status = 'IN_MATCH'
                ) then 'IN_MATCH'
                when exists (
                    select 1 from public.match_search_sessions s
                    where s.team_id = p_team_id and s.user_id = m.user_id
                      and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    where q.team_id = p_team_id and q.user_id = m.user_id
                ) then 'QUEUED'
                else 'NONE'
            end
        )
        order by
            case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end,
            coalesce(p.display_name, '')
    ), '[]'::jsonb)
    into v_members
    from public.team_members m
    join public.profiles p on p.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'members', v_members
    );
end;
$$;

comment on function public.get_team_player_statuses(uuid) is
    'Membros do time com status IN_MATCH/SEARCHING/QUEUED/NONE. Sem presença ainda.';

revoke execute on function public.get_team_player_statuses(uuid) from public, anon;
grant execute on function public.get_team_player_statuses(uuid) to authenticated;

-- Override manual do record de Weekend League por usuário/evento. Fica
-- separado do computado de propósito: nunca somamos manual + calculado em
-- silêncio — a UI escolhe qual mostrar.
create table public.weekend_league_manual_records (
    user_id uuid not null references public.profiles (id) on delete cascade,
    event_id uuid not null references public.weekend_league_events (id) on delete cascade,
    wins integer not null default 0,
    losses integer not null default 0,
    updated_at timestamptz not null default now(),
    primary key (user_id, event_id),
    constraint wl_manual_wins_non_negative check (wins >= 0 and losses >= 0)
);

alter table public.weekend_league_manual_records enable row level security;
revoke all on table public.weekend_league_manual_records
    from anon, authenticated, public;

-- Record do chamador num evento: computado das partidas FINISHED de WL + o
-- override manual, se houver. p_event_id null = evento atual.
create function public.get_weekend_league_record(p_event_id uuid default null)
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
    v_manual public.weekend_league_manual_records;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
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
    where user_id = v_user_id
      and weekend_league_event_id = v_event.id
      and status = 'FINISHED';

    select * into v_manual from public.weekend_league_manual_records
    where user_id = v_user_id and event_id = v_event.id;

    return jsonb_build_object(
        'event', jsonb_build_object(
            'id', v_event.id,
            'number', v_event.number,
            'season', v_event.season,
            'starts_at', to_jsonb(v_event.starts_at),
            'ends_at', to_jsonb(v_event.ends_at)
        ),
        'computed', jsonb_build_object('wins', v_wins, 'losses', v_losses),
        'manual', case when v_manual.user_id is null then null
            else jsonb_build_object('wins', v_manual.wins, 'losses', v_manual.losses)
        end
    );
end;
$$;

revoke execute on function public.get_weekend_league_record(uuid) from public, anon;
grant execute on function public.get_weekend_league_record(uuid) to authenticated;

-- Define/limpa o override manual do chamador. wins/losses null = remove o override.
create function public.set_weekend_league_manual_record(
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

    if p_wins is null or p_losses is null then
        delete from public.weekend_league_manual_records
        where user_id = v_user_id and event_id = p_event_id;
        return;
    end if;

    if p_wins < 0 or p_losses < 0 then
        raise exception 'invalid record' using errcode = 'FQ024';
    end if;

    insert into public.weekend_league_manual_records
        (user_id, event_id, wins, losses)
    values (v_user_id, p_event_id, p_wins, p_losses)
    on conflict (user_id, event_id) do update
        set wins = excluded.wins, losses = excluded.losses, updated_at = now();
end;
$$;

revoke execute on function public.set_weekend_league_manual_record(uuid, integer, integer)
    from public, anon;
grant execute on function public.set_weekend_league_manual_record(uuid, integer, integer)
    to authenticated;
