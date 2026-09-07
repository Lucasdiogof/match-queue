-- Sinal de invalidacao do matchmaking para o Realtime.
--
-- POR QUE UMA TABELA NOVA EM VEZ DE ASSINAR match_search_sessions/queue
-- DIRETAMENTE: a Etapa 5 deixou aquelas duas tabelas com RLS ativa, ZERO
-- policies e ZERO grants -- todo acesso passa por RPC security definer.
-- Postgres Changes so entrega linha que o assinante consegue SELECIONAR,
-- entao assina-las exigiria abrir SELECT nelas para authenticated. Isso
-- desmontaria a postura de seguranca da Etapa 5 (a fila e os horarios de
-- busca de um time passariam a ser legiveis por qualquer membro via
-- PostgREST, fora do read model controlado) so para ganhar um aviso de
-- "algo mudou".
--
-- Esta tabela existe exatamente para ser legivel: ela nao contem estado de
-- matchmaking nenhum, so "o time X mudou, versao N". Mesmo se vazasse, o
-- unico fato revelado seria que houve atividade -- e ainda assim a RLS
-- limita isso a quem ja e membro do time.
--
-- O estado oficial continua vindo SO de get_team_matchmaking_state. Esta
-- tabela e um sino, nao uma fonte de verdade.

create table public.team_matchmaking_revisions (
    team_id uuid primary key references public.teams (id) on delete cascade,
    revision bigint not null default 1,
    updated_at timestamptz not null default now()
);

comment on table public.team_matchmaking_revisions is
    'Sinal de invalidacao por time para o Realtime. Nao guarda estado de matchmaking.';
comment on column public.team_matchmaking_revisions.revision is
    'Contador monotonico. Serve para log/diagnostico, nao para reconstruir estado.';

alter table public.team_matchmaking_revisions enable row level security;

-- Mesmo helper de membership das Etapas 3-5. Como e security definer, a
-- policy nao recursa e o Realtime consegue avaliar a visibilidade da linha
-- com o JWT do assinante.
create policy team_matchmaking_revisions_select_member
    on public.team_matchmaking_revisions
    for select
    to authenticated
    using (public.is_team_member(team_id));

-- Sem policy de insert/update/delete: o cliente nunca escreve aqui. Quem
-- incrementa e _notify_matchmaking_changed, chamada de dentro das RPCs
-- security definer -- ou seja, ninguem consegue forjar um evento de
-- invalidacao para outro time (nem para o proprio).
revoke all on table public.team_matchmaking_revisions from anon;
grant select on table public.team_matchmaking_revisions to authenticated;

-- Postgres Changes so replica tabelas que estao na publication do Realtime.
alter publication supabase_realtime add table public.team_matchmaking_revisions;

-- Ponto unico de emissao. Chamado pelas RPCs do matchmaking DEPOIS que o
-- estado final da operacao ja foi escrito, e nunca no meio dela. Como e um
-- INSERT/UPDATE comum, participa da mesma transacao: se a RPC falhar e der
-- rollback, o evento simplesmente nao acontece -- nenhum cliente recebe
-- aviso de uma mudanca que nao existiu.
--
-- A serializacao ja vem de graca: toda escrita de matchmaking de um time
-- roda sob pg_advisory_xact_lock do proprio time (_lock_team_matchmaking),
-- entao duas transacoes nunca disputam esta linha em paralelo.
create function public._notify_matchmaking_changed(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.team_matchmaking_revisions as r (team_id, revision, updated_at)
    values (p_team_id, 1, now())
    on conflict (team_id) do update
        set revision = r.revision + 1,
            updated_at = now();
end;
$$;

comment on function public._notify_matchmaking_changed(uuid) is
    'Incrementa a revisao do time para o Realtime avisar os clientes. So as RPCs chamam.';

revoke execute on function public._notify_matchmaking_changed(uuid)
    from public, anon, authenticated;
