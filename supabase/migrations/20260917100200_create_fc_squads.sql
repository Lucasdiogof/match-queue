-- Squad: uma escalacao dentro de um Elenco.
--
-- ELENCO != SQUAD. user_fc_accounts continua sendo a CONTA ("Lucksrei"); o
-- squad e uma escalacao dela ("Principal", "Weekend League"). Um elenco tem
-- quantos squads quiser -- sem limite artificial.
--
-- A formacao pertence ao SQUAD, nunca ao elenco: dois squads do mesmo elenco
-- podem usar formacoes diferentes, que e exatamente o caso de uso.

create table public.fc_squads (
    id uuid primary key default gen_random_uuid(),
    fc_account_id uuid not null
        references public.user_fc_accounts (id) on delete cascade,
    name text not null,
    formation_code text not null references public.fc_formations (code),

    is_active boolean not null default true,
    is_default boolean not null default false,

    manager_id uuid references public.fc_managers (id) on delete set null,
    -- Liga do tecnico e configuracao DO SQUAD, nao propriedade do tecnico:
    -- o mesmo tecnico pode ser usado com ligas diferentes em squads
    -- diferentes.
    manager_league_id uuid references public.fc_leagues (id) on delete set null,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint fc_squads_name_length
        check (char_length(btrim(name)) between 1 and 40)
);

comment on table public.fc_squads is
    'Escalacao dentro de um Elenco. Pessoal: nem admin de time enxerga.';

create index fc_squads_account_idx
    on public.fc_squads (fc_account_id)
    where is_active;

-- No maximo um default POR ELENCO, e so entre os ativos. Squad arquivado
-- nunca segura o posto de default.
create unique index fc_squads_one_default_per_account
    on public.fc_squads (fc_account_id)
    where is_default and is_active;

create trigger fc_squads_set_updated_at before update on public.fc_squads
    for each row execute function public.set_updated_at();

-- Slot ocupado de um squad.
--
-- Guardamos SO os slots preenchidos. Slot vazio simplesmente nao tem linha:
-- a grade de 11 titulares vem do catalogo da formacao no read model, entao
-- nao existe estado duplicado pra manter sincronizado, e trocar de formacao
-- vira remapear as poucas linhas que existem em vez de reescrever 18.
create table public.fc_squad_slots (
    squad_id uuid not null references public.fc_squads (id) on delete cascade,
    slot_type text not null,
    -- STARTING: slot_code do catalogo da formacao ('CB1', 'ST'...).
    -- BENCH: 'BENCH_1'..'BENCH_7'.
    slot_code text not null,
    player_card_id uuid not null
        references public.fc_player_cards (id) on delete cascade,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    primary key (squad_id, slot_type, slot_code),
    constraint fc_squad_slots_type_check
        check (slot_type in ('STARTING', 'BENCH'))
);

comment on table public.fc_squad_slots is
    'Somente slots PREENCHIDOS. Slot vazio = ausencia de linha.';

-- Mesma carta nao ocupa dois slots do mesmo squad.
create unique index fc_squad_slots_unique_card_per_squad
    on public.fc_squad_slots (squad_id, player_card_id);

create trigger fc_squad_slots_set_updated_at
    before update on public.fc_squad_slots
    for each row execute function public.set_updated_at();

alter table public.fc_squads enable row level security;
alter table public.fc_squad_slots enable row level security;

-- Squad e PESSOAL. Nem companheiro de time, nem admin do time, ninguem alem
-- do dono do elenco enxerga. Leitura direta liberada so pro dono (mesmo
-- padrao de user_fc_accounts); toda escrita passa pelas RPCs.
create policy fc_squads_select_own
    on public.fc_squads for select to authenticated
    using (
        exists (
            select 1 from public.user_fc_accounts as a
            where a.id = fc_squads.fc_account_id
              and a.user_id = (select auth.uid())
        )
    );

create policy fc_squad_slots_select_own
    on public.fc_squad_slots for select to authenticated
    using (
        exists (
            select 1
            from public.fc_squads as s
            join public.user_fc_accounts as a on a.id = s.fc_account_id
            where s.id = fc_squad_slots.squad_id
              and a.user_id = (select auth.uid())
        )
    );

revoke all on table public.fc_squads from anon;
revoke all on table public.fc_squad_slots from anon;

grant select on table public.fc_squads to authenticated;
grant select on table public.fc_squad_slots to authenticated;
