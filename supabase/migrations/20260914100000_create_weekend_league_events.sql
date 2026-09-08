-- Campanhas de Weekend League. Eventos persistidos e corrigíveis (nunca
-- calculados no cliente): a janela real de cada FUT Champions pode variar de
-- season para season, então quem manda é a linha no banco, não uma regra
-- sexta→segunda hardcodada no Flutter.
--
-- Um game_match de Weekend League é vinculado ao evento cuja janela contém o
-- início da partida. Rivals fica sem evento (null).

create table public.weekend_league_events (
    id uuid primary key default gen_random_uuid(),
    number integer not null,
    season text,
    starts_at timestamptz not null,
    ends_at timestamptz not null,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),

    constraint weekend_league_events_window_check check (ends_at > starts_at),
    constraint weekend_league_events_number_positive check (number > 0)
);

comment on table public.weekend_league_events is
    'Campanhas de Weekend League. Janela definida no banco, não no cliente.';

-- Uma varredura típica é "o evento cuja janela contém agora, senão o próximo
-- que ainda vai começar" — ambos ordenam por starts_at.
create index weekend_league_events_window_idx
    on public.weekend_league_events (starts_at, ends_at)
    where is_active;

-- Primeiro evento: Weekend League #1, 02/10/2026 → 05/10/2026 (UTC).
insert into public.weekend_league_events (number, season, starts_at, ends_at)
values (
    1,
    '2026',
    '2026-10-02T00:00:00Z',
    '2026-10-05T23:59:59Z'
);

-- Evento ativo agora, senão o próximo a começar, senão o último encerrado.
-- Read model puro para a tela Jogar mostrar a campanha certa.
create function public.get_current_weekend_league_event()
returns public.weekend_league_events
language sql
stable
security definer
set search_path = ''
as $$
    select *
    from public.weekend_league_events
    where is_active
    order by
        -- 0 = acontecendo agora, 1 = futuro, 2 = passado.
        case
            when now() between starts_at and ends_at then 0
            when starts_at > now() then 1
            else 2
        end,
        -- dentro de "futuro" o mais próximo primeiro; nos demais o mais recente.
        case when starts_at > now() then starts_at end asc nulls last,
        starts_at desc
    limit 1;
$$;

comment on function public.get_current_weekend_league_event() is
    'Evento de WL acontecendo agora, senão o próximo, senão o último.';

alter table public.weekend_league_events enable row level security;

-- Eventos são catálogo comum (não têm dado sensível de usuário) mas mantemos
-- a postura fechada do projeto: leitura só pela RPC read model acima.
revoke all on table public.weekend_league_events from anon, authenticated, public;

revoke execute on function public.get_current_weekend_league_event()
    from public, anon;
grant execute on function public.get_current_weekend_league_event()
    to authenticated;
