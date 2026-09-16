-- Janela real do Champions: sexta 18h -> segunda 04h (America/Sao_Paulo), nao
-- sexta 00h -> segunda 00h como a geracao original assumia. Regra do produto,
-- nao suposicao: primeira campanha 25/09 -> 28/09, dali em diante toda sexta
-- 18h ate a madrugada de segunda (4h).
--
-- _weekend_league_week_start truncava o dia as 00h antes de achar a sexta da
-- semana; agora trunca deslocando 18h (o mesmo truque de "dia que comeca as
-- 18h, nao a meia-noite") para floorar direto na sexta 18h correta.
create or replace function public._weekend_league_week_start(p_at timestamptz)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select (
        date_trunc(
            'day',
            (p_at at time zone 'America/Sao_Paulo') - interval '18 hours'
        )
        - make_interval(days => (
            (
                extract(
                    isodow
                    from (p_at at time zone 'America/Sao_Paulo') - interval '18 hours'
                )::int + 2
            ) % 7
          ))
        + interval '18 hours'
    ) at time zone 'America/Sao_Paulo';
$$;

comment on function public._weekend_league_week_start(timestamptz) is
    'Sexta 18h (America/Sao_Paulo) da semana de Champions que contem o instante.';

-- Mesma geracao de antes, so a duracao da janela muda: 58h (sexta 18h ->
-- segunda 4h) em vez de 72h (sexta 00h -> segunda 00h).
create or replace function public.ensure_weekend_league_events(
    p_weeks_back integer default 8,
    p_weeks_forward integer default 2
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_anchor timestamptz := public._weekend_league_season_anchor();
    v_current timestamptz := public._weekend_league_week_start(now());
    v_inserted integer;
begin
    with weeks as (
        select v_current + make_interval(days => 7 * offset_weeks) as week_start
        from generate_series(
            -greatest(coalesce(p_weeks_back, 8), 0),
            greatest(coalesce(p_weeks_forward, 2), 0)
        ) as offset_weeks
    )
    insert into public.weekend_league_events
        (number, season, starts_at, ends_at, is_active)
    select
        1 + (extract(epoch from (w.week_start - v_anchor)) / 604800)::int,
        to_char(w.week_start at time zone 'America/Sao_Paulo', 'YYYY'),
        w.week_start,
        w.week_start + interval '2 days 10 hours',
        true
    from weeks as w
    where w.week_start >= v_anchor
    on conflict (starts_at) do nothing;

    get diagnostics v_inserted = row_count;
    return v_inserted;
end;
$$;

-- As duas campanhas futuras ja geradas (nao notificadas ainda) nasceram com a
-- janela antiga (sexta 00h -> segunda 00h). Corrige as linhas para a janela
-- certa; passadas/ja notificadas ficam como estao (historico).
update public.weekend_league_events
set starts_at = '2026-09-18T21:00:00Z',
    ends_at = '2026-09-21T07:00:00Z'
where number = 4
  and notifications_dispatched_at is null;

update public.weekend_league_events
set starts_at = '2026-09-25T21:00:00Z',
    ends_at = '2026-09-28T07:00:00Z'
where number = 5
  and notifications_dispatched_at is null;

-- O seletor so listava semanas "ja iniciadas" (starts_at <= agora), entao a
-- campanha que o card do Jogar mostra como atual/proxima (get_current_...,
-- que pode ser a que ainda vai comecar) as vezes ficava de fora da propria
-- lista de selecao -- exatamente o bug reportado ("nao da pra selecionar qual
-- Champions e"). Agora o limite tambem acompanha o que o card ja mostra.
create or replace function public.list_weekend_league_events(p_limit integer default 12)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 12), 52));
    v_boundary timestamptz;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public.ensure_weekend_league_events();

    select coalesce(starts_at, public._weekend_league_week_start(now()))
    into v_boundary
    from public.get_current_weekend_league_event();

    v_boundary := greatest(v_boundary, public._weekend_league_week_start(now()));

    select coalesce(jsonb_agg(item order by starts_at desc), '[]'::jsonb)
    into v_items
    from (
        select
            e.starts_at,
            jsonb_build_object(
                'id', e.id,
                'number', e.number,
                'season', e.season,
                'starts_at', to_jsonb(e.starts_at),
                'ends_at', to_jsonb(e.ends_at),
                'is_current', now() >= e.starts_at and now() < e.ends_at
            ) as item
        from public.weekend_league_events as e
        where e.is_active
          and e.starts_at <= v_boundary
        order by e.starts_at desc
        limit v_limit
    ) as page;

    return jsonb_build_object('items', v_items);
end;
$$;
