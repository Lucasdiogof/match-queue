-- Link de convite de um time. No maximo uma linha is_active=true por
-- team_id (indice unico parcial abaixo). Girar ou desativar um link nao
-- apaga a linha antiga -- so marca is_active=false e revoked_at, mantendo
-- historico para auditoria.
--
-- expires_at/max_uses ficam sempre null na V1: a UI nao expoe essa
-- configuracao ainda, mas o schema ja esta pronto para quando existir.
--
-- created_by aponta para profiles (nao auth.users) pelo mesmo motivo de
-- team_members.user_id na Etapa 3: ON DELETE RESTRICT trava a exclusao de
-- conta de quem gerou um link enquanto o time existir. Coerente com o
-- padrao ja usado ali.

create table public.team_invite_links (
    id uuid primary key default gen_random_uuid(),
    team_id uuid not null references public.teams (id) on delete cascade,
    code text not null,
    created_by uuid not null references public.profiles (id) on delete restrict,
    is_active boolean not null default true,
    expires_at timestamptz,
    max_uses integer,
    usage_count integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    revoked_at timestamptz,

    constraint team_invite_links_code_unique
        unique (code),
    constraint team_invite_links_code_format
        check (code ~ '^[A-Z0-9]{10,16}$'),
    constraint team_invite_links_max_uses_positive
        check (max_uses is null or max_uses > 0),
    constraint team_invite_links_usage_count_non_negative
        check (usage_count >= 0)
);

comment on table public.team_invite_links is
    'Links de convite por time. No maximo um is_active=true por team_id. '
    'Sem policy de select/insert/update -- todo acesso passa pelas RPCs '
    'security definer (resolve/join/get_or_create/rotate/revoke).';
comment on column public.team_invite_links.expires_at is
    'Null na V1. Schema pronto para expiracao futura; sem UI ainda.';
comment on column public.team_invite_links.max_uses is
    'Null na V1. Schema pronto para limite de usos futuro; sem UI ainda.';

create index team_invite_links_team_id_idx on public.team_invite_links (team_id);

-- Garante no maximo um link ativo por time no proprio banco, sem trigger.
create unique index team_invite_links_one_active_per_team
    on public.team_invite_links (team_id)
    where is_active;

create trigger team_invite_links_set_updated_at
    before update on public.team_invite_links
    for each row
    execute function public.set_updated_at();

alter table public.team_invite_links enable row level security;

-- Sem policies de proposito: a tabela guarda o codigo do convite, que
-- funciona como uma capability -- nao deve ser enumeravel nem por membros
-- do time via select direto. Toda leitura/escrita passa pelas RPCs
-- (resolve_team_invite, join_team_by_invite, get_or_create_team_invite,
-- rotate_team_invite, revoke_team_invite), que sao security definer e
-- decidem o que cada papel pode ver.
revoke all on table public.team_invite_links from anon, authenticated, public;
