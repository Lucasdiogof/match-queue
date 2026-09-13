-- Pedido de entrada de um usuario num time (usuario -> time). Direcao
-- oposta de team_invitations (time -> usuario), criada na proxima migration.
--
-- Guarda fc_account_id desde o pedido porque quem aprova precisa ver "qual
-- Elenco" antes de decidir, e porque aprovar ja deixa o Elenco vinculado ao
-- time na mesma transacao (evita um segundo passo manual em
-- link_fc_account_to_team logo depois de aceitar).
--
-- Sem coluna "reviewed_by" separada de resolved_by: sao a mesma pessoa,
-- no mesmo instante, e uma linha so guarda decisao final.
create table public.team_join_requests (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    user_id uuid not null references public.profiles (id) on delete cascade,
    fc_account_id uuid not null references public.user_fc_accounts (id) on delete cascade,
    status text not null default 'PENDING'
        check (status in ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    created_at timestamptz not null default now(),
    resolved_at timestamptz,
    resolved_by uuid references public.profiles (id)
);

comment on table public.team_join_requests is
    'Pedido de um usuario para entrar num time com um Elenco especifico. Aprovar cria team_members (PLAYER) e vincula o Elenco na mesma transacao.';

create index team_join_requests_team_pending_idx
    on public.team_join_requests (team_id)
    where status = 'PENDING';

create index team_join_requests_user_idx
    on public.team_join_requests (user_id);

-- No maximo um pedido PENDING por Elenco+time: reenviar so faz sentido depois
-- que o anterior foi resolvido (aprovado/recusado/cancelado).
create unique index team_join_requests_pending_unique_idx
    on public.team_join_requests (team_id, fc_account_id)
    where status = 'PENDING';

alter table public.team_join_requests enable row level security;

-- Mesmo padrao de team_invite_links: zero policy, toda escrita e leitura
-- estruturada passam por RPC security definer. A unica excecao e o proprio
-- solicitante enxergar os proprios pedidos (usado pela tab Solicitacoes) e
-- quem administra o time enxergar os pedidos do time.
create policy team_join_requests_select_own_or_admin
    on public.team_join_requests
    for select
    to authenticated
    using (
        user_id = (select auth.uid())
        or public.is_team_admin(team_id)
    );

revoke all on public.team_join_requests from public, anon;
grant select on public.team_join_requests to authenticated;

-- Solicitar entrada. O Elenco precisa ser do proprio usuario (nunca de
-- outra pessoa) e o usuario ainda nao pode ser membro do time.
create function public.request_team_join(p_team_id uuid, p_fc_account_id uuid)
returns public.team_join_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (select 1 from public.teams where id = p_team_id) then
        raise exception 'team not found' using errcode = 'FQ053';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if public.is_team_member(p_team_id) then
        raise exception 'already a team member' using errcode = 'FQ054';
    end if;

    if exists (
        select 1 from public.team_join_requests
        where team_id = p_team_id
          and fc_account_id = p_fc_account_id
          and status = 'PENDING'
    ) then
        raise exception 'a pending request already exists' using errcode = 'FQ055';
    end if;

    insert into public.team_join_requests (team_id, user_id, fc_account_id)
    values (p_team_id, v_user_id, p_fc_account_id)
    returning * into v_row;

    return v_row;
end;
$$;

comment on function public.request_team_join(uuid, uuid) is
    'Cria um pedido PENDING de entrada num time com um Elenco do proprio usuario. Bloqueia se ja e membro ou se ja existe pedido PENDING para o mesmo Elenco+time.';

-- Cancelar o proprio pedido enquanto PENDING.
create function public.cancel_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and user_id = v_user_id and status = 'PENDING';

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    update public.team_join_requests
    set status = 'CANCELLED', resolved_at = now(), resolved_by = v_user_id
    where id = p_request_id;
end;
$$;

comment on function public.cancel_team_join_request(uuid) is
    'So o proprio solicitante cancela, e so enquanto PENDING.';

-- Aprovar: cria membership PLAYER + vincula o Elenco ao time, tudo na mesma
-- transacao. is_team_admin cobre OWNER e ADMIN (gerente).
create function public.approve_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    if exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and user_id = v_row.user_id
    ) then
        -- Ja virou membro por outro caminho enquanto o pedido esperava:
        -- fecha o pedido como aprovado sem tentar inserir de novo.
        update public.team_join_requests
        set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
        where id = p_request_id;
        return;
    end if;

    insert into public.team_members (team_id, user_id, role)
    values (v_row.team_id, v_row.user_id, 'PLAYER');

    insert into public.fc_account_teams (fc_account_id, team_id)
    values (v_row.fc_account_id, v_row.team_id)
    on conflict (fc_account_id, team_id) do nothing;

    update public.team_join_requests
    set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;
end;
$$;

comment on function public.approve_team_join_request(uuid) is
    'OWNER/ADMIN aprova: cria team_members (PLAYER) e vincula o Elenco na mesma transacao. Idempotente se o solicitante ja virou membro por outro caminho.';

create function public.reject_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_join_requests
    where id = p_request_id and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'request not found' using errcode = 'FQ056';
    end if;

    if not public.is_team_admin(v_row.team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    update public.team_join_requests
    set status = 'REJECTED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;
end;
$$;

comment on function public.reject_team_join_request(uuid) is
    'OWNER/ADMIN recusa um pedido PENDING. Nao cria membership.';

revoke execute on function public.request_team_join(uuid, uuid) from public, anon;
revoke execute on function public.cancel_team_join_request(uuid) from public, anon;
revoke execute on function public.approve_team_join_request(uuid) from public, anon;
revoke execute on function public.reject_team_join_request(uuid) from public, anon;

grant execute on function public.request_team_join(uuid, uuid) to authenticated;
grant execute on function public.cancel_team_join_request(uuid) to authenticated;
grant execute on function public.approve_team_join_request(uuid) to authenticated;
grant execute on function public.reject_team_join_request(uuid) to authenticated;
