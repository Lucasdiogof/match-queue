-- Geracao de codigo e as duas RPCs publicas do lado de quem recebe um
-- convite: resolver (preview, anon + authenticated) e entrar (join,
-- authenticated). As demais RPCs (get_or_create/rotate/revoke, do lado de
-- quem gerencia o link) ficam na proxima migration.
--
-- Continuamos o namespace de erro FQ00x da Etapa 3 (nao PTxxx -- ver
-- comentario em 20260908090400_create_team_rpc.sql sobre a colisao com o
-- prefixo que o PostgREST reserva para status HTTP).
--   FQ008 invite nao encontrado
--   FQ009 invite existe mas nao esta ativo (revogado/substituido)
--   FQ010 invite expirado
--   FQ011 invite esgotou max_uses
--   FQ012 permissao negada (nao e membro / nao e admin, conforme a RPC)
--   FQ013 nao foi possivel gerar um codigo unico (colisao persistente)

-- Gera um codigo de 12 caracteres a partir de bytes aleatorios do pgcrypto
-- (nao math.random, nao client-side). Alfabeto de 32 simbolos sem 0/O/1/I
-- para evitar ambiguidade visual; 32 e potencia de 2, entao "% 32" nao
-- introduz nenhum vies estatistico entre os simbolos. 12 * 5 bits = 60 bits
-- de entropia.
--
-- Privada de proposito: sem grant para nenhum papel de PostgREST, so quem
-- possui as functions (dono das migrations) consegue chamar.
create function public._generate_invite_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    v_length constant integer := 12;
    v_bytes bytea;
    v_code text := '';
    i integer;
begin
    v_bytes := extensions.gen_random_bytes(v_length);
    for i in 0..v_length - 1 loop
        v_code := v_code || substr(
            v_alphabet,
            (get_byte(v_bytes, i) % length(v_alphabet)) + 1,
            1
        );
    end loop;
    return v_code;
end;
$$;

revoke execute on function public._generate_invite_code() from public, anon, authenticated;

-- Retorna o link ativo do time, criando um se ainda nao existir. Usada
-- tanto pela RPC publica get_or_create_team_invite (proxima migration)
-- quanto pelo backfill dos times que existiam antes desta etapa.
--
-- pg_advisory_xact_lock serializa chamadas concorrentes para o MESMO time
-- (duas pessoas abrindo a tela Time ao mesmo tempo, ou um ensure disputando
-- com um rotate): a segunda chamada espera a primeira commitar e entao
-- reveem o estado real, em vez de as duas tentarem inserir uma linha ativa
-- e uma esbarrar no indice unico parcial. O retry em unique_violation cobre
-- soh a colisao (astronomicamente rara) de codigo entre times diferentes.
create function public._ensure_active_team_invite(
    p_team_id uuid,
    p_actor_id uuid
)
returns public.team_invite_links
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_link public.team_invite_links;
    v_attempt integer := 0;
begin
    perform pg_advisory_xact_lock(hashtext('team_invite:' || p_team_id::text));

    select * into v_link
    from public.team_invite_links
    where team_id = p_team_id and is_active
    limit 1;

    if v_link.id is not null then
        return v_link;
    end if;

    loop
        v_attempt := v_attempt + 1;
        begin
            insert into public.team_invite_links (team_id, code, created_by)
            values (p_team_id, public._generate_invite_code(), p_actor_id)
            returning * into v_link;
            return v_link;
        exception when unique_violation then
            if v_attempt >= 5 then
                raise exception 'could not generate a unique invite code'
                    using errcode = 'FQ013';
            end if;
        end;
    end loop;
end;
$$;

revoke execute on function public._ensure_active_team_invite(uuid, uuid)
    from public, anon, authenticated;

-- Preview de um convite a partir do codigo. Nunca expoe lista de membros,
-- emails, roles ou internals do link (created_by, max_uses) -- so o minimo
-- para montar a BottomSheet. Sempre devolve exatamente uma linha, mesmo
-- para codigo inexistente, para o cliente nao precisar tratar "zero linhas"
-- como um caso a parte.
--
-- is_already_member so e calculado quando ha auth.uid() (anon recebe null).
-- Quando o chamador ja e membro, o status "valid" vira "already_member" --
-- a UI decide o CTA (ENTRAR NO TIME vs ABRIR TIME) direto por esse campo,
-- sem precisar tentar o join primeiro.
create function public.resolve_team_invite(p_code text)
returns table (
    status text,
    team_id uuid,
    team_name text,
    team_tag text,
    team_logo_url text,
    member_count integer,
    is_already_member boolean
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_code text := upper(btrim(coalesce(p_code, '')));
    v_link public.team_invite_links;
    v_status text;
    v_is_member boolean;
begin
    select * into v_link from public.team_invite_links where code = v_code;

    if v_link.id is null then
        return query select
            'invalid'::text, null::uuid, null::text, null::text,
            null::text, null::integer, null::boolean;
        return;
    end if;

    if not v_link.is_active then
        v_status := 'revoked';
    elsif v_link.expires_at is not null and v_link.expires_at < now() then
        v_status := 'expired';
    elsif v_link.max_uses is not null and v_link.usage_count >= v_link.max_uses then
        v_status := 'exhausted';
    else
        v_status := 'valid';
    end if;

    if v_user_id is not null then
        v_is_member := exists (
            select 1 from public.team_members as tm
            where tm.team_id = v_link.team_id and tm.user_id = v_user_id
        );
        if v_status = 'valid' and v_is_member then
            v_status := 'already_member';
        end if;
    else
        v_is_member := null;
    end if;

    return query
    select
        v_status,
        t.id,
        t.name,
        t.tag,
        t.logo_url,
        (select count(*)::integer from public.team_members as tm where tm.team_id = t.id),
        v_is_member
    from public.teams t
    where t.id = v_link.team_id;
end;
$$;

comment on function public.resolve_team_invite(text) is
    'Preview publico de um convite. anon e authenticated. Nunca devolve '
    'membros, emails, roles ou dados internos do link.';

revoke execute on function public.resolve_team_invite(text) from public;
grant execute on function public.resolve_team_invite(text) to anon, authenticated;

-- Entrada efetiva no time. Sempre PLAYER -- nao existe parametro de role,
-- entao o cliente nao tem como pedir ADMIN/OWNER na entrada.
--
-- "select ... for update" trava a linha do link: duas chamadas concorrentes
-- com o mesmo codigo (o mesmo usuario clicando duas vezes, por exemplo)
-- serializam nessa linha. A segunda so le apos a primeira commitar, entao
-- ve a membership ja criada e devolve already_member em vez de duplicar. O
-- catch de unique_violation no insert e um segundo cinto de seguranca caso
-- a serializacao acima falhe por algum motivo.
create function public.join_team_by_invite(p_code text)
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
begin
    if v_user_id is null then
        raise exception 'authentication required'
            using errcode = 'FQ003';
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
    where tm.team_id = v_link.team_id and tm.user_id = v_user_id;

    if v_existing.team_id is not null then
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end if;

    begin
        insert into public.team_members (team_id, user_id, role)
        values (v_link.team_id, v_user_id, 'PLAYER');
    exception when unique_violation then
        select * into v_existing
        from public.team_members as tm
        where tm.team_id = v_link.team_id and tm.user_id = v_user_id;
        select * into v_team from public.teams where id = v_link.team_id;
        return query select
            true, v_team.id, v_team.name, v_team.tag, v_existing.role::text;
        return;
    end;

    update public.team_invite_links
    set usage_count = usage_count + 1
    where id = v_link.id;

    select * into v_team from public.teams where id = v_link.team_id;

    return query select
        false, v_team.id, v_team.name, v_team.tag, 'PLAYER'::text;
end;
$$;

comment on function public.join_team_by_invite(text) is
    'Entrada atomica no time via convite. Sempre role=PLAYER. Ja membro '
    'devolve already_member=true sem duplicar linha nem incrementar uso.';

revoke execute on function public.join_team_by_invite(text) from public, anon;
grant execute on function public.join_team_by_invite(text) to authenticated;
