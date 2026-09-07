-- Participacao de um jogador num time. Relacao N:N: um usuario participa de
-- varios times, um time tem varios jogadores.
--
-- A PK e composta (team_id, user_id) em vez de um id proprio. A regra "uma
-- pessoa aparece no maximo uma vez no mesmo time" nao e uma constraint extra
-- sobre a linha, e a identidade da linha -- e o indice da PK e exatamente o
-- que a RLS consulta o tempo todo. Um id surrogate seria uma segunda chave
-- candidata que nada referencia.
--
-- Nao existe coluna status. Linha presente = membro ativo. Quando existir
-- saida de time com historico, entra um left_at ou um status proprio; criar o
-- enum agora seria adivinhar estados que nenhum fluxo produz.
--
-- user_id aponta para public.profiles, nao para auth.users: alem de ser o que
-- a listagem de membros realmente precisa (o PostgREST consegue embutir o
-- profile), o ON DELETE RESTRICT faz a exclusao de conta falhar enquanto a
-- pessoa estiver em algum time. Isso e proposital -- ver docs/database.md.

create table public.team_members (
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete restrict,
    role public.team_role not null default 'PLAYER',
    joined_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    primary key (team_id, user_id)
);

comment on table public.team_members is
    'Membros de um time. Linha presente = membro ativo.';

-- "Quais times eu participo" filtra so por user_id e nao aproveita a PK, cuja
-- coluna lider e team_id.
create index team_members_user_id_idx on public.team_members (user_id);

-- Garante no maximo um OWNER por time no proprio banco, sem trigger.
create unique index team_members_single_owner_idx
    on public.team_members (team_id)
    where role = 'OWNER';

create trigger team_members_set_updated_at
    before update on public.team_members
    for each row
    execute function public.set_updated_at();

-- Transferencia e remocao de dono nao existem nesta etapa. Combinado com o
-- indice unico acima e com create_team (unico caminho que cria time), isso
-- garante exatamente um OWNER por time: nunca zero, nunca dois.
create function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'DELETE' then
        -- Quando a exclusao vem em cascata de teams, a linha do time ja foi
        -- removida quando este trigger roda, e a cascata passa livre.
        if old.role = 'OWNER'
            and exists (select 1 from public.teams where id = old.team_id)
        then
            raise exception 'team owner cannot be removed'
                using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.user_id is distinct from old.user_id
    then
        raise exception 'team membership identity is immutable'
            using errcode = 'FQ004';
    end if;

    if old.role = 'OWNER' and new.role <> 'OWNER' then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    new.joined_at := old.joined_at;
    return new;
end;
$$;

create trigger team_members_protect_owner
    before update or delete on public.team_members
    for each row
    execute function public.team_members_protect_owner();
