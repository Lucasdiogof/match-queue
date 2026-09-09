-- UI/UX refresh: times ganham visibilidade Publico/Privado para alimentar a
-- aba Explorar. Nasce PUBLICO por padrao (decisao explicita do dono do
-- produto) -- times ja existentes na producao viram publicos com esta
-- migration, o que e o comportamento pedido, nao um efeito colateral.
--
-- Mesmo principio de get_public_profile (ver 20260925100000): nenhuma policy
-- de RLS nova para leitura publica. list_public_teams/get_public_team sao
-- SECURITY DEFINER e montam o jsonb campo a campo -- nunca select *, nunca
-- email, nunca token de convite, nunca configuracao interna. Membros so
-- aparecem nomeados se o proprio membro tiver o perfil publico (Etapa 16)
-- habilitado -- o time nao pode "destravar" a exposicao de alguem que nao
-- optou.
--
-- Codigo novo: FQ045 (visibilidade invalida / time nao encontrado ao
-- alternar Publico/Privado).

alter table public.teams
    add column is_public boolean not null default true;

comment on column public.teams.is_public is
    'Controla se o time aparece em Explorar e tem pagina publica (get_public_team). Default TRUE por decisao de produto.';

create index teams_public_created_idx
    on public.teams (created_at desc)
    where is_public;

-- Alterna Publico/Privado. Mesmo padrao de autorizacao de
-- update_team_search_duration: RLS ja restringe update a OWNER/ADMIN, esta
-- RPC so troca o "nao encontrado" enganoso por FQ012 honesto.
create function public.set_team_visibility(p_team_id uuid, p_is_public boolean)
returns public.teams
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_team public.teams;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_admin(p_team_id) then
        raise exception 'only an owner or admin can change team visibility'
            using errcode = 'FQ012';
    end if;

    if p_is_public is null then
        raise exception 'visibility is required' using errcode = 'FQ045';
    end if;

    update public.teams
    set is_public = p_is_public
    where id = p_team_id
    returning * into v_team;

    return v_team;
end;
$$;

revoke execute on function public.set_team_visibility(uuid, boolean)
    from public, anon;
grant execute on function public.set_team_visibility(uuid, boolean)
    to authenticated;

-- Listagem da aba Explorar: so colunas seguras, so times publicos. Sem
-- policy nova em teams -- authenticated continua sem select direto na
-- tabela fora do que ja e membro; este RPC e o unico jeito de ver times
-- alheios.
create function public.list_public_teams(p_limit integer default 50)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'name', t.name,
            'tag', t.tag,
            'logo_url', t.logo_url,
            'primary_color', t.primary_color,
            'secondary_color', t.secondary_color,
            'member_count', (
                select count(*) from public.team_members as tm
                where tm.team_id = t.id
            )
        )
        order by t.created_at desc
    ), '[]'::jsonb)
    from public.teams as t
    where t.is_public
    limit greatest(1, least(coalesce(p_limit, 50), 100));
$$;

revoke execute on function public.list_public_teams(integer) from public, anon;
grant execute on function public.list_public_teams(integer) to authenticated;

-- Pagina publica de um time. Mesma postura honesta de get_public_profile:
-- time inexistente e time privado devolvem a mesma resposta
-- {found: false} -- nunca revela que um id existe mas esta privado.
create function public.get_public_team(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_team public.teams;
    v_members jsonb;
    v_record jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_team from public.teams where id = p_team_id and is_public;

    if v_team.id is null then
        return jsonb_build_object('schema_version', 1, 'found', false);
    end if;

    -- So membros que optaram pelo proprio perfil publico (Etapa 16) aparecem
    -- nomeados aqui -- o time nunca "destrava" a exposicao de alguem.
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'display_name', p.display_name,
            'avatar_url', p.avatar_url,
            'slug', upp.slug,
            'role', tm.role
        )
        order by tm.role, p.display_name
    ), '[]'::jsonb)
    into v_members
    from public.team_members as tm
    join public.profiles as p on p.id = tm.user_id
    join public.user_public_profiles as upp
        on upp.user_id = tm.user_id and upp.is_enabled
    where tm.team_id = v_team.id;

    select jsonb_build_object(
        'wins', count(*) filter (where gm.result = 'WIN'),
        'losses', count(*) filter (where gm.result = 'LOSS'),
        'goals_for', coalesce(sum(gm.goals_for), 0),
        'goals_against', coalesce(sum(gm.goals_against), 0)
    )
    into v_record
    from public.game_matches as gm
    where gm.team_id = v_team.id and gm.status = 'FINISHED';

    return jsonb_build_object(
        'schema_version', 1,
        'found', true,
        'team', jsonb_build_object(
            'id', v_team.id,
            'name', v_team.name,
            'tag', v_team.tag,
            'logo_url', v_team.logo_url,
            'primary_color', v_team.primary_color,
            'secondary_color', v_team.secondary_color,
            'member_count', (
                select count(*) from public.team_members as tm
                where tm.team_id = v_team.id
            )
        ),
        'members', v_members,
        'record', v_record
    );
end;
$$;

revoke execute on function public.get_public_team(uuid) from public, anon;
grant execute on function public.get_public_team(uuid) to authenticated;
