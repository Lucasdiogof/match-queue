-- Criar time e criar a membership de OWNER precisam acontecer juntos ou nao
-- acontecer. Duas chamadas independentes do Flutter deixariam time orfao se a
-- segunda falhasse; aqui as duas escritas rodam na transacao do statement.
--
-- security definer e necessario: teams e team_members nao tem policy de
-- insert justamente para que esta funcao seja o unico caminho de criacao.
--
-- O dono e sempre auth.uid(). Nao existe parametro de owner: o cliente nao
-- tem como criar time em nome de outra pessoa.

create function public.create_team(
    p_name text,
    p_tag text default null,
    p_default_search_duration_seconds integer default 180
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

    insert into public.team_members (team_id, user_id, role)
    values (v_team.id, v_user_id, 'OWNER');

    return v_team;
end;
$$;

comment on function public.create_team(text, text, integer) is
    'Cria um time e a membership OWNER do chamador numa unica transacao.';

revoke execute on function public.create_team(text, text, integer)
    from public, anon;
grant execute on function public.create_team(text, text, integer)
    to authenticated;
