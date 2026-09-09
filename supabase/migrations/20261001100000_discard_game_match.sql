-- "Nao informar esta partida": encerrar uma partida IN_MATCH sem resultado.
--
-- O caminho implicito ja existia (report_match_found_and_start_game marca a
-- anterior como ABANDONED ao comecar outra), mas nao havia acao explicita: o
-- usuario que nao quisesse registrar o resultado tinha que esperar a
-- expiracao de 20 min ou buscar outra partida so para limpar o card.
--
-- ABANDONED e o estado certo, nao EXPIRED: EXPIRED e o cron dizendo "ninguem
-- respondeu"; aqui foi uma decisao do dono da partida. A constraint
-- game_matches_result_consistency ja garante que ABANDONED nunca carrega
-- result -- registrar nada continua sendo diferente de registrar derrota.

create function public.discard_game_match(p_match_id uuid)
returns public.game_matches
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_match public.game_matches;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select * into v_match
    from public.game_matches
    where id = p_match_id
    for update;

    if v_match.id is null or v_match.user_id <> v_user_id then
        raise exception 'game match not found' using errcode = 'FQ021';
    end if;
    if v_match.status <> 'IN_MATCH' then
        raise exception 'game match already finalized' using errcode = 'FQ022';
    end if;

    update public.game_matches
    set status = 'ABANDONED',
        ended_at = now()
    where id = v_match.id
    returning * into v_match;

    return v_match;
end;
$$;

comment on function public.discard_game_match(uuid) is
    'Encerra uma partida IN_MATCH como ABANDONED, sem resultado. Registrar resultado e opcional.';

revoke execute on function public.discard_game_match(uuid) from public, anon;
grant execute on function public.discard_game_match(uuid) to authenticated;
