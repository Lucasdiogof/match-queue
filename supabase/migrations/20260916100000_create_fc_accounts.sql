-- Elenco (conta de Ultimate Team) do usuário. Um usuário joga com várias
-- contas EA diferentes -- isso nunca foi modelado antes desta etapa. Sem
-- e-mail/EA account real na V1: só um nome que o próprio usuário escolhe
-- ("Lucksrei", "Pedro FC"). Pertence ao USUÁRIO, nunca ao time -- é o time
-- que pode ter vários elencos vinculados, não o contrário.
create table public.user_fc_accounts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.profiles (id) on delete restrict,
    name text not null,
    is_active boolean not null default true,
    -- Divisão de Rivals do elenco. Catálogo por CHECK (não enum Postgres):
    -- se a FC 27 mudar o número de divisões, é um ALTER de constraint, não
    -- uma migração de tipo enum inteira.
    rivals_division text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint user_fc_accounts_name_length
        check (char_length(btrim(name)) between 2 and 40),
    constraint user_fc_accounts_rivals_division_check
        check (
            rivals_division is null
            or rivals_division in (
                'DIV_10', 'DIV_9', 'DIV_8', 'DIV_7', 'DIV_6',
                'DIV_5', 'DIV_4', 'DIV_3', 'DIV_2', 'DIV_1', 'ELITE'
            )
        )
);

comment on table public.user_fc_accounts is
    'Elenco/conta de Ultimate Team do usuário. Chamado de "Elenco" na UI, nunca "conta EA".';

create index user_fc_accounts_user_active_idx
    on public.user_fc_accounts (user_id)
    where is_active;

create trigger user_fc_accounts_set_updated_at
    before update on public.user_fc_accounts
    for each row
    execute function public.set_updated_at();

alter table public.user_fc_accounts enable row level security;

-- Leitura direta liberada só pro dono (mesmo padrão de user_devices):
-- simples o bastante pra não precisar de RPC só pra listar. Toda escrita
-- passa pelas RPCs da próxima migration, que validam nome/dono.
create policy user_fc_accounts_select_own
    on public.user_fc_accounts
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.user_fc_accounts from anon;
grant select on table public.user_fc_accounts to authenticated;

-- Vínculo N:N entre Elenco e Time. Um elenco pode representar o usuário em
-- vários times sociais; um time pode ter vários elencos vinculados (um por
-- membro, tipicamente). Nunca teams.fc_account_id -- o vínculo é sempre
-- desta tabela, nunca uma coluna no time.
create table public.fc_account_teams (
    fc_account_id uuid not null
        references public.user_fc_accounts (id) on delete cascade,
    team_id uuid not null references public.teams (id) on delete cascade,
    created_at timestamptz not null default now(),

    primary key (fc_account_id, team_id)
);

comment on table public.fc_account_teams is
    'Vínculo N:N: quais times um elenco representa. O elenco é do usuário, o vínculo é por escolha.';

create index fc_account_teams_team_idx on public.fc_account_teams (team_id);

alter table public.fc_account_teams enable row level security;

-- Só o dono do elenco vê os vínculos dele -- outros membros do time não
-- enxergam quais elencos alguém vinculou (não é informação pública do time).
create policy fc_account_teams_select_own
    on public.fc_account_teams
    for select
    to authenticated
    using (
        exists (
            select 1 from public.user_fc_accounts a
            where a.id = fc_account_teams.fc_account_id
              and a.user_id = (select auth.uid())
        )
    );

revoke all on table public.fc_account_teams from anon;
grant select on table public.fc_account_teams to authenticated;
