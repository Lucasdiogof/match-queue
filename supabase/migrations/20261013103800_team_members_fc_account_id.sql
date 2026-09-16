-- Redesenho: membership/ownership de time passa a ser por Conta FC
-- (fc_account_id), nao por login (user_id). Ate aqui team_members era
-- (team_id, user_id): um login com duas Contas (ex. uma no PC, outra no
-- Console) so podia ter UMA linha de membership por time -- a segunda Conta
-- nao conseguia entrar/pedir vaga no mesmo time porque o servidor ja via o
-- login como membro. Contas de um mesmo login nao tem vinculo nenhum entre
-- si (cada uma pode ter times diferentes, ou participar do mesmo time
-- independentemente) -- ver doc de arquitetura combinada com o usuario.
--
-- user_id continua na tabela, mas deixa de ser identidade: vira coluna
-- desnormalizada, sincronizada por trigger a partir de fc_account_id. Toda
-- leitura que so precisa "de quem e essa linha" (perfil, notificacoes,
-- exclusao de conta) continua igual, sem tocar nesta migration -- so quem
-- precisa saber "QUAL conta" (criar time, entrar, remover, promover, status
-- de matchmaking por membro) muda.
--
-- fc_account_teams (link "esta Conta joga por este Time", usado por
-- matchmaking/squads) e um conceito diferente e continua existindo do jeito
-- que esta -- nao e todo membro que ja escolheu/vinculou uma Conta pra jogar
-- partidas, e um membro pode multiplas Contas vinculadas.

-- 1) Coluna nova, ainda opcional pra poder popular antes do NOT NULL.
alter table public.team_members
    add column fc_account_id uuid references public.user_fc_accounts (id) on delete restrict;

-- 2) Backfill: cada linha (team_id, user_id) hoje tem no maximo uma Conta
-- daquele login ja vinculada aquele time via fc_account_teams -- usa essa
-- como a Conta "dona" da membership. Verificado contra o dado real de
-- producao antes de escrever isto: toda linha existente tinha exatamente um
-- candidato (nunca zero, nunca mais de um).
update public.team_members as tm
set fc_account_id = fat.fc_account_id
from public.fc_account_teams as fat
join public.user_fc_accounts as a on a.id = fat.fc_account_id
where fat.team_id = tm.team_id
  and a.user_id = tm.user_id
  and tm.fc_account_id is null;

-- Fail loud, nao silencioso: se sobrar alguma linha sem Conta resolvida (dado
-- mudou entre a checagem manual e este deploy), a migration para aqui em vez
-- de deixar o NOT NULL falhar com um erro generico ou, pior, escolher uma
-- Conta arbitraria sem ninguem perceber.
do $$
declare
    v_missing integer;
begin
    select count(*) into v_missing
    from public.team_members
    where fc_account_id is null;

    if v_missing > 0 then
        raise exception
            'team_members backfill incomplete: % row(s) without a resolvable fc_account_id',
            v_missing;
    end if;
end;
$$;

alter table public.team_members
    alter column fc_account_id set not null;

-- 3) Chave: (team_id, fc_account_id) em vez de (team_id, user_id). E
-- exatamente isto que permite duas Contas do mesmo login serem duas linhas
-- (dois papeis, ate dois OWNER de times diferentes) no mesmo time.
alter table public.team_members drop constraint team_members_pkey;
alter table public.team_members add primary key (team_id, fc_account_id);

create index team_members_fc_account_id_idx
    on public.team_members (fc_account_id);

comment on column public.team_members.fc_account_id is
    'Identidade real da membership. Chave primaria junto com team_id.';
comment on column public.team_members.user_id is
    'Desnormalizado a partir de fc_account_id (trigger team_members_sync_user_id) -- nunca setado direto. Mantido para leituras que so precisam "de quem e essa linha" (perfil, notificacoes, exclusao de conta), sem join extra.';

-- 4) user_id sempre derivado da Conta, nunca aceito como input direto --
-- fecha a porta pra um RPC (hoje ou futuro) gravar um user_id que nao bate
-- com o dono real de fc_account_id.
create function public.team_members_sync_user_id()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    select user_id into new.user_id
    from public.user_fc_accounts
    where id = new.fc_account_id;

    return new;
end;
$$;

create trigger team_members_sync_user_id
    before insert or update on public.team_members
    for each row
    execute function public.team_members_sync_user_id();

-- 5) Trigger de protecao existente, so trocando a identidade que ela tranca
-- de user_id para fc_account_id (a invariante em si -- OWNER nunca some,
-- nunca muda de linha -- continua igual).
create or replace function public.team_members_protect_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'DELETE' then
        if old.role = 'OWNER'
            and exists (select 1 from public.teams where id = old.team_id)
        then
            raise exception 'team owner cannot be removed'
                using errcode = 'FQ005';
        end if;
        return old;
    end if;

    if new.team_id is distinct from old.team_id
        or new.fc_account_id is distinct from old.fc_account_id
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

-- 6) Variantes precisas dos helpers de membership, para os poucos pontos
-- onde "algum das minhas Contas e membro" (as 4 funcoes originais, que
-- continuam do jeito que estao -- ainda usam user_id, que segue valido pela
-- sincronizacao acima) nao serve: fluxos onde uma Conta especifica esta
-- entrando/ja e membro, e permitir uma segunda Conta do mesmo login exige
-- checar so aquela linha, nao "qualquer uma".
create function public.is_team_member_as(p_team_id uuid, p_fc_account_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.team_members
        where team_id = p_team_id
          and fc_account_id = p_fc_account_id
    );
$$;

revoke execute on function public.is_team_member_as(uuid, uuid) from public, anon;
grant execute on function public.is_team_member_as(uuid, uuid) to authenticated;

-- 7) create_team: quem cria escolhe com qual Conta se torna OWNER. Continua
-- nao aceitando um "dono" arbitrario -- a Conta precisa ser do proprio
-- auth.uid(), validado aqui, do mesmo jeito que request_match_search ja
-- valida Conta contra dono em outras etapas.
--
-- drop antes do create: p_fc_account_id novo com default muda a assinatura
-- (3 args -> 4), entao "create or replace" criaria um segundo overload em
-- vez de substituir -- uma chamada com 3 args ficaria ambigua entre os dois.
drop function if exists public.create_team(text, text, integer);

create function public.create_team(
    p_name text,
    p_tag text default null,
    p_default_search_duration_seconds integer default 180,
    p_fc_account_id uuid default null
)
returns public.teams
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_name text;
    v_tag text;
    v_duration integer;
    v_team public.teams;
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    if not exists (select 1 from public.profiles where id = v_user_id) then
        raise exception 'profile is missing for the current user'
            using errcode = 'FQ006';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    v_name := btrim(coalesce(p_name, ''));
    if char_length(v_name) < 2 or char_length(v_name) > 40 then
        raise exception 'team name must have between 2 and 40 characters'
            using errcode = 'FQ001';
    end if;

    v_tag := nullif(upper(btrim(coalesce(p_tag, ''))), '');
    if v_tag is not null and v_tag !~ '^[A-Z0-9]{2,6}$' then
        raise exception 'team tag must have 2 to 6 letters or digits'
            using errcode = 'FQ002';
    end if;

    v_duration := coalesce(p_default_search_duration_seconds, 180);
    if v_duration < 30 or v_duration > 600 then
        raise exception 'search duration must be between 30 and 600 seconds'
            using errcode = 'FQ007';
    end if;

    insert into public.teams (name, tag, default_search_duration_seconds)
    values (v_name, v_tag, v_duration)
    returning * into v_team;

    insert into public.team_members (team_id, fc_account_id, role)
    values (v_team.id, p_fc_account_id, 'OWNER');

    return v_team;
end;
$$;

comment on function public.create_team(text, text, integer, uuid) is
    'Cria um time e a membership OWNER da Conta FC informada numa unica transacao.';

revoke execute on function public.create_team(text, text, integer, uuid)
    from public, anon;
grant execute on function public.create_team(text, text, integer, uuid)
    to authenticated;

-- 8) join_team_by_invite: mesma logica, agora com Conta explicita. A
-- checagem de "ja e membro" passa a ser por Conta (is_team_member_as), nao
-- mais por login -- e exatamente isto que deixa uma segunda Conta do mesmo
-- login entrar no mesmo time por codigo de convite.
--
-- Mesmo motivo do drop acima: p_fc_account_id novo muda 1 arg -> 2.
drop function if exists public.join_team_by_invite(text);

create function public.join_team_by_invite(
    p_code text,
    p_fc_account_id uuid default null
)
returns table (
    already_member boolean,
    team_id uuid,
    team_name text,
    team_tag text,
    role text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_code text := upper(btrim(coalesce(p_code, '')));
    v_link public.team_invite_links;
    v_existing public.team_members;
    v_team public.teams;
    v_joiner_name text;
    v_member record;
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    select * into v_link
    from public.team_invite_links
    where code = v_code
    for update;

    if v_link.id is null then
        raise exception 'invite not found'
            using errcode = 'FQ008';
    end if;

    if not v_link.is_active then
        raise exception 'invite is not active'
            using errcode = 'FQ009';
    end if;

    if v_link.expires_at is not null and v_link.expires_at < now() then
        raise exception 'invite has expired'
            using errcode = 'FQ010';
    end if;

    if v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        raise exception 'invite has been exhausted'
            using errcode = 'FQ011';
    end if;

    select * into v_existing
    from public.team_members as tm
    where tm.team_id = v_link.team_id and tm.fc_account_id = p_fc_account_id;

    if v_existing.team_id is not null then
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end if;

    begin
        insert into public.team_members (team_id, fc_account_id, role)
        values (v_link.team_id, p_fc_account_id, 'PLAYER');
    exception when unique_violation then
        select * into v_existing
        from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.fc_account_id = p_fc_account_id;
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end;

    update public.team_invite_links
    set usage_count = usage_count + 1
    where id = v_link.id;

    select * into v_team from public.teams where id = v_link.team_id;
    select display_name into v_joiner_name from public.profiles where id = v_user_id;

    for v_member in
        select tm.user_id
        from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.fc_account_id <> p_fc_account_id
    loop
        perform public._emit_user_notification(
            v_member.user_id, 'TEAMS', 'TEAM_MEMBER_JOINED',
            'TEAM_MEMBER_JOINED:' || v_link.team_id || ':' || v_user_id,
            'notification_team_member_joined',
            jsonb_build_object(
                'team_id', v_link.team_id,
                'team_name', v_team.name,
                'user_id', v_user_id,
                'display_name', coalesce(v_joiner_name, '')
            ),
            'team_detail', jsonb_build_object('team_id', v_link.team_id),
            'team', v_link.team_id
        );
    end loop;

    return query select
        false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$$;

comment on function public.join_team_by_invite(text, uuid) is
    'Entrada atomica no time via convite com uma Conta FC explicita. Sempre role=PLAYER. Ja membro (com esta Conta) devolve already_member=true sem duplicar linha nem incrementar uso. Membros existentes recebem TEAM_MEMBER_JOINED; quem entrou, nao.';

revoke execute on function public.join_team_by_invite(text, uuid) from public, anon;
grant execute on function public.join_team_by_invite(text, uuid) to authenticated;

-- 9) remove_team_member / set_team_member_role: alvo passa a ser a Conta,
-- nao o login. O ator continua resolvido pelo papel mais privilegiado entre
-- as proprias Contas no time (is_team_admin/is_team_owner, que nao mudam) --
-- suficiente hoje porque nenhuma tela pede "agir como esta Conta
-- especifica"; so o alvo da acao precisa ser preciso.
--
-- drop antes do create: Postgres recusa "create or replace" quando so o
-- NOME do parametro muda (p_target_user_id -> p_target_fc_account_id),
-- mesmo com o tipo identico.
drop function if exists public.remove_team_member(uuid, uuid);

create function public.remove_team_member(
    p_team_id uuid,
    p_target_fc_account_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_actor_role public.team_role;
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select m.role into v_actor_role
    from public.team_members as m
    join public.user_fc_accounts as a on a.id = m.fc_account_id
    where m.team_id = p_team_id and a.user_id = v_actor_id
    order by case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end
    limit 1;

    if v_actor_role is null or v_actor_role = 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and fc_account_id = p_target_fc_account_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team owner cannot be removed' using errcode = 'FQ005';
    end if;

    if v_actor_role = 'ADMIN' and v_target_role <> 'PLAYER' then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    delete from public.team_members
    where team_id = p_team_id and fc_account_id = p_target_fc_account_id;
end;
$$;

comment on function public.remove_team_member(uuid, uuid) is
    'OWNER remove PLAYER ou ADMIN; ADMIN remove so PLAYER. Nunca remove OWNER (trigger de protecao cobre isso tambem na propria escrita). Alvo e a Conta FC, nao o login.';

drop function if exists public.set_team_member_role(uuid, uuid, public.team_role);

create function public.set_team_member_role(
    p_team_id uuid,
    p_target_fc_account_id uuid,
    p_role public.team_role
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_target_role public.team_role;
begin
    if v_actor_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if p_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    if not public.is_team_owner(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select role into v_target_role
    from public.team_members
    where team_id = p_team_id and fc_account_id = p_target_fc_account_id;

    if v_target_role is null then
        raise exception 'target is not a member of this team' using errcode = 'FQ012';
    end if;

    if v_target_role = 'OWNER' then
        raise exception 'team ownership transfer is not supported yet'
            using errcode = 'FQ005';
    end if;

    update public.team_members
    set role = p_role
    where team_id = p_team_id and fc_account_id = p_target_fc_account_id;
end;
$$;

comment on function public.set_team_member_role(uuid, uuid, public.team_role) is
    'Somente OWNER promove PLAYER->ADMIN ou rebaixa ADMIN->PLAYER. Nunca atribui OWNER. Alvo e a Conta FC, nao o login.';

revoke execute on function public.remove_team_member(uuid, uuid) from public, anon;
revoke execute on function public.set_team_member_role(uuid, uuid, public.team_role) from public, anon;
grant execute on function public.remove_team_member(uuid, uuid) to authenticated;
grant execute on function public.set_team_member_role(uuid, uuid, public.team_role) to authenticated;

-- 10) request_team_join: a checagem "ja e membro" era ambigua (qualquer
-- Conta minha) e bloqueava uma segunda Conta de pedir vaga no mesmo time --
-- exatamente o bug reportado. Passa a checar so a Conta que esta pedindo.
create or replace function public.request_team_join(p_team_id uuid, p_fc_account_id uuid)
returns public.team_join_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_requester_name text;
    v_team_name text;
    v_admin record;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select name into v_team_name from public.teams where id = p_team_id;
    if v_team_name is null then
        raise exception 'team not found' using errcode = 'FQ053';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if public.is_team_member_as(p_team_id, p_fc_account_id) then
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

    perform public._notify_team_admins_requests_changed(p_team_id);

    select display_name into v_requester_name
    from public.profiles where id = v_user_id;

    for v_admin in
        select user_id from public.team_members
        where team_id = p_team_id and role in ('OWNER', 'ADMIN')
    loop
        perform public._emit_user_notification(
            v_admin.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_RECEIVED',
            'TEAM_JOIN_REQUEST_RECEIVED:' || v_row.id || ':' || v_admin.user_id,
            'notification_team_join_request_received',
            jsonb_build_object(
                'team_id', p_team_id,
                'requester_display_name', coalesce(v_requester_name, ''),
                'team_name', v_team_name
            ),
            'requests', jsonb_build_object('team_id', p_team_id)
        );
    end loop;

    return v_row;
end;
$$;

-- 11) approve_team_join_request: ja-membro e insert passam a ser por Conta.
create or replace function public.approve_team_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_actor_id uuid := (select auth.uid());
    v_row public.team_join_requests;
    v_team_name text;
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

    select name into v_team_name from public.teams where id = v_row.team_id;

    if exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and fc_account_id = v_row.fc_account_id
    ) then
        update public.team_join_requests
        set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
        where id = p_request_id;
        perform public._notify_team_admins_requests_changed(v_row.team_id);
        return;
    end if;

    insert into public.team_members (team_id, fc_account_id, role)
    values (v_row.team_id, v_row.fc_account_id, 'PLAYER');

    insert into public.fc_account_teams (fc_account_id, team_id)
    values (v_row.fc_account_id, v_row.team_id)
    on conflict (fc_account_id, team_id) do nothing;

    update public.team_join_requests
    set status = 'APPROVED', resolved_at = now(), resolved_by = v_actor_id
    where id = p_request_id;

    perform public._notify_team_admins_requests_changed(v_row.team_id);

    perform public._emit_user_notification(
        v_row.user_id, 'TEAMS', 'TEAM_JOIN_REQUEST_APPROVED',
        'TEAM_JOIN_REQUEST_APPROVED:' || v_row.id,
        'notification_team_join_request_approved',
        jsonb_build_object('team_id', v_row.team_id, 'team_name', v_team_name),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;

-- 12) respond_team_invitation: aceitar agora exige a Conta FC explicita (o
-- fc_account_id do convite e so o "preview" de quando foi enviado -- o
-- proprio comentario da tabela ja avisa que pode ser outra na hora de
-- aceitar). Recusar nao precisa de Conta nenhuma.
--
-- Mesmo motivo dos drops acima: p_fc_account_id novo muda 2 args -> 3.
drop function if exists public.respond_team_invitation(uuid, boolean);

create function public.respond_team_invitation(
    p_invitation_id uuid,
    p_accept boolean,
    p_fc_account_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_row public.team_invitations;
    v_team_name text;
    v_display_name text;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_row
    from public.team_invitations
    where id = p_invitation_id
      and invitee_user_id = v_user_id
      and status = 'PENDING'
    for update;

    if v_row.id is null then
        raise exception 'invitation not found' using errcode = 'FQ056';
    end if;

    if not p_accept then
        update public.team_invitations
        set status = 'REJECTED', resolved_at = now(), resolved_by = v_user_id
        where id = p_invitation_id;
        return;
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if not exists (
        select 1 from public.team_members
        where team_id = v_row.team_id and fc_account_id = p_fc_account_id
    ) then
        insert into public.team_members (team_id, fc_account_id, role)
        values (v_row.team_id, p_fc_account_id, 'PLAYER');

        insert into public.fc_account_teams (fc_account_id, team_id)
        values (p_fc_account_id, v_row.team_id)
        on conflict (fc_account_id, team_id) do nothing;
    end if;

    update public.team_invitations
    set status = 'ACCEPTED', resolved_at = now(), resolved_by = v_user_id
    where id = p_invitation_id;

    select name into v_team_name from public.teams where id = v_row.team_id;
    select display_name into v_display_name from public.profiles where id = v_user_id;

    perform public._emit_user_notification(
        v_row.inviter_id, 'TEAMS', 'TEAM_INVITATION_ACCEPTED',
        'TEAM_INVITATION_ACCEPTED:' || v_row.id,
        'notification_team_invitation_accepted',
        jsonb_build_object(
            'team_id', v_row.team_id,
            'team_name', v_team_name,
            'display_name', coalesce(v_display_name, '')
        ),
        'team', jsonb_build_object('team_id', v_row.team_id)
    );
end;
$$;

revoke execute on function public.respond_team_invitation(uuid, boolean, uuid) from public, anon;
grant execute on function public.respond_team_invitation(uuid, boolean, uuid) to authenticated;

-- 13) get_team_player_statuses: cada linha de team_members agora e uma
-- Conta especifica, entao o status (em partida / buscando / na fila) tem
-- que filtrar pela Conta da propria linha, nao pelo login -- do jeito antigo
-- duas Contas do mesmo login no mesmo time mostrariam o status uma da
-- outra.
create or replace function public.get_team_player_statuses(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_members jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;
    if not public.is_team_member(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', m.user_id,
            'fc_account_id', m.fc_account_id,
            'display_name', coalesce(p.display_name, ''),
            'avatar_url', p.avatar_url,
            'role', m.role,
            'last_active_at', to_jsonb(p.last_active_at),
            'status', case
                when exists (
                    select 1 from public.game_matches g
                    where g.fc_account_id = m.fc_account_id and g.status = 'IN_MATCH'
                ) then 'IN_MATCH'
                when exists (
                    select 1 from public.match_search_sessions s
                    where s.team_id = p_team_id and s.fc_account_id = m.fc_account_id
                      and s.status = 'SEARCHING'
                ) then 'SEARCHING'
                when exists (
                    select 1 from public.match_search_queue q
                    where q.team_id = p_team_id and q.fc_account_id = m.fc_account_id
                ) then 'QUEUED'
                when p.last_active_at is not null
                    and p.last_active_at >= now() - interval '60 minutes'
                    then 'RECENTLY_ACTIVE'
                else 'OFFLINE'
            end,
            'queue_position', (
                select row_number() over (order by q.sequence)
                from public.match_search_queue as q
                where q.team_id = p_team_id and q.fc_account_id = m.fc_account_id
            )
        )
        order by
            case m.role when 'OWNER' then 0 when 'ADMIN' then 1 else 2 end,
            coalesce(p.display_name, '')
    ), '[]'::jsonb)
    into v_members
    from public.team_members as m
    join public.profiles as p on p.id = m.user_id
    where m.team_id = p_team_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'members', v_members
    );
end;
$$;
