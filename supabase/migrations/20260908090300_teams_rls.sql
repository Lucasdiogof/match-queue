alter table public.teams enable row level security;
alter table public.team_members enable row level security;

-- Ver um time exige participar dele. Nao existe leitura aberta para qualquer
-- usuario autenticado.
create policy teams_select_member
    on public.teams
    for select
    to authenticated
    using (public.is_team_member(id));

-- Editar exige OWNER ou ADMIN. using controla quais linhas podem ser alvo,
-- with check controla o resultado; os dois amarrados ao mesmo predicado.
-- Colunas que nunca devem mudar sao travadas pelo trigger
-- teams_guard_immutable_columns.
create policy teams_update_admin
    on public.teams
    for update
    to authenticated
    using (public.is_team_admin(id))
    with check (public.is_team_admin(id));

-- Sem policy de insert: criar time acontece exclusivamente pela RPC
-- create_team, que garante que o dono e o proprio auth.uid().
-- Sem policy de delete: exclusao de time nao existe nesta etapa.

-- Ver os membros exige participar do time. Ninguem lista membros da
-- plataforma inteira.
create policy team_members_select_member
    on public.team_members
    for select
    to authenticated
    using (public.is_team_member(team_id));

-- Sem policy de insert, update ou delete: entrar em time, mudar papel e
-- remover membro sao fluxos das proximas etapas. Enquanto nao existirem, a
-- unica escrita possivel e a da RPC create_team.

revoke all on table public.teams from anon;
revoke all on table public.team_members from anon;

grant select, update on table public.teams to authenticated;
grant select on table public.team_members to authenticated;
