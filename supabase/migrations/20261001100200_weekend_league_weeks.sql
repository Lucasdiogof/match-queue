-- Weekend League por semana, de verdade.
--
-- Estado anterior: uma unica linha semeada na Etapa 8.5 como placeholder e
-- nenhuma forma de criar outras. Nao havia o que "selecionar" -- a tela
-- recebia o evento corrente e pronto.
--
-- A autoridade continua no banco, como o schema original decidiu: a janela
-- real pode variar por season, entao ninguem calcula semana no cliente. O que
-- faltava era o gerador que povoa esse calendario.
--
-- Fuso: a janela e sexta 00:00 -> segunda 00:00 em America/Sao_Paulo, ou seja
-- "comeca sexta, termina na virada de domingo pra segunda". Calcular em UTC
-- era erro concreto e ja estava no dado: o evento semeado dizia
-- 2026-10-02T00:00Z, que no Brasil e quinta 21:00. timestamptz guarda
-- instante, entao converter para o fuso na hora de achar a fronteira e
-- guardar o instante resultante e o caminho correto -- nunca gravar "meia
-- noite" ingenua.
--
-- Numeracao: sequencial a partir de uma ancora fixa, NAO o numero oficial da
-- EA. O app nao conhece o calendario oficial e nao inventa um; number e a
-- ordem das semanas dentro da season para o usuario se localizar.

create function public._weekend_league_week_start(p_at timestamptz)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select (
        date_trunc('day', p_at at time zone 'America/Sao_Paulo')
        - make_interval(days => (
            (extract(isodow from p_at at time zone 'America/Sao_Paulo')::int + 2) % 7
          ))
    ) at time zone 'America/Sao_Paulo';
$$;

comment on function public._weekend_league_week_start(timestamptz) is
    'Sexta 00:00 (America/Sao_Paulo) da semana de Weekend League que contem o instante.';

-- Ancora imutavel da numeracao. Derivada, nao digitada: a sexta da semana que
-- contem 01/09/2026. Mudar isto renumera o historico inteiro.
create function public._weekend_league_season_anchor()
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select public._weekend_league_week_start(timestamptz '2026-09-01 12:00:00-03');
$$;

-- Duas semanas nunca podem compartilhar o mesmo inicio: e o que torna a
-- geracao idempotente.
create unique index if not exists weekend_league_events_starts_at_key
    on public.weekend_league_events (starts_at);

-- Corrige o placeholder da Etapa 8.5 in place, sem apagar: mesma linha, mesmo
-- id, janela na fronteira certa e numero na sequencia. Seguro porque nenhuma
-- partida e nenhum progresso manual apontavam para ele (conferido antes).
update public.weekend_league_events as e
set starts_at = public._weekend_league_week_start(e.starts_at),
    ends_at = public._weekend_league_week_start(e.starts_at) + interval '3 days',
    number = 1 + (
        extract(epoch from (
            public._weekend_league_week_start(e.starts_at)
            - public._weekend_league_season_anchor()
        )) / 604800
    )::int
where e.starts_at <> public._weekend_league_week_start(e.starts_at);

-- Cria as semanas que faltam na janela pedida. Idempotente pelo unique index:
-- rodar de novo nao duplica nem reescreve o que ja existe, entao uma janela
-- corrigida a mao continua valendo.
create function public.ensure_weekend_league_events(
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
        w.week_start + interval '3 days',
        true
    from weeks as w
    -- Antes da ancora a numeracao seria <= 0 e a constraint number > 0 barra.
    where w.week_start >= v_anchor
    on conflict (starts_at) do nothing;

    get diagnostics v_inserted = row_count;
    return v_inserted;
end;
$$;

comment on function public.ensure_weekend_league_events(integer, integer) is
    'Povoa o calendario de Weekend League em torno de agora. Idempotente.';

-- Lista para o seletor de semana. Garante o calendario antes de ler, entao a
-- tela nunca abre vazia so porque ninguem rodou um job.
create function public.list_weekend_league_events(p_limit integer default 12)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 12), 52));
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public.ensure_weekend_league_events();

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
          and e.starts_at <= public._weekend_league_week_start(now())
        order by e.starts_at desc
        limit v_limit
    ) as page;

    return jsonb_build_object('items', v_items);
end;
$$;

comment on function public.list_weekend_league_events(integer) is
    'Semanas de Weekend League ja iniciadas, mais recente primeiro, para o seletor.';

revoke execute on function public.ensure_weekend_league_events(integer, integer)
    from public, anon;
revoke execute on function public.list_weekend_league_events(integer)
    from public, anon;
grant execute on function public.list_weekend_league_events(integer)
    to authenticated;
