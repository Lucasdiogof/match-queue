-- RLS self-only. Leitura cruzada entre companheiros de time so entra quando
-- team_members existir (Etapa 3) -- inventar uma regra de time agora, sem a
-- tabela que define quem e companheiro de quem, significaria abrir profiles
-- para qualquer usuario autenticado sem necessidade.

alter table public.profiles enable row level security;

-- O select do proprio profile e o insert de recuperacao usam auth.uid()
-- dentro de um subselect: o Postgres avalia a funcao uma vez por query em
-- vez de uma vez por linha.

create policy profiles_select_own
    on public.profiles
    for select
    to authenticated
    using ((select auth.uid()) = id);

-- Rede de seguranca para contas que existirem sem profile (trigger criado
-- depois do usuario, falha registrada como warning). O with check amarra a
-- linha ao proprio usuario, entao ninguem cria profile para outra pessoa.
create policy profiles_insert_own
    on public.profiles
    for insert
    to authenticated
    with check ((select auth.uid()) = id);

-- using controla quais linhas podem ser alvo do update; with check controla
-- o resultado. Com os dois amarrados ao auth.uid(), trocar o id da propria
-- linha para o id de outra pessoa e rejeitado.
create policy profiles_update_own
    on public.profiles
    for update
    to authenticated
    using ((select auth.uid()) = id)
    with check ((select auth.uid()) = id);

-- Sem policy de delete: profile morre junto com auth.users via
-- on delete cascade, nao pela mao do cliente.

-- Defesa em profundidade. As policies acima ja sao to authenticated (anon
-- nao casa com nenhuma e por isso nao le nada), mas remover o grant deixa
-- explicito que a role anonima nao tem nada a fazer aqui.
revoke all on table public.profiles from anon;
grant select, insert, update on table public.profiles to authenticated;
