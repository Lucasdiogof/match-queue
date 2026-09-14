-- _expire_team_search_if_needed marcava a sessao como EXPIRED e mandava o
-- push (SEARCH_EXPIRED), mas so notificava o Realtime do time (
-- _notify_matchmaking_changed) DENTRO de _promote_next_queued_player_for_team
-- -- e essa funcao so notifica quando de fato promove alguem da fila. Fila
-- vazia (ninguem esperando) = ninguem e notificado = quem estava buscando
-- fica olhando pro cronometro parado em 00:00 ate o proximo refresh de
-- seguranca (90s) ou ate reabrir a tela.
--
-- O cron de 30s (process_expired_searches) ja cobre o caso "app fechado" --
-- este fix e sobre o caso "app aberto, olhando a propria tela": notifica
-- sempre que uma busca de fato expira, promovendo alguem ou nao.
create or replace function public._expire_team_search_if_needed(p_team_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_session public.match_search_sessions;
begin
    select * into v_session
    from public.match_search_sessions
    where team_id = p_team_id and status = 'SEARCHING';

    if v_session.id is null or v_session.expires_at > now() then
        return false;
    end if;

    update public.match_search_sessions
    set status = 'EXPIRED', finish_reason = 'EXPIRED', finished_at = now()
    where id = v_session.id;

    perform public._enqueue_notification(
        v_session.user_id, 'SEARCH_EXPIRED', p_team_id, v_session.id, '{}'::jsonb
    );

    perform public._promote_next_queued_player_for_team(p_team_id);
    perform public._notify_matchmaking_changed(p_team_id);

    if v_session.fc_account_id is not null then
        perform public._retry_promotion_for_fc_account_queues(
            v_session.fc_account_id, p_team_id
        );
    end if;

    return true;
end;
$$;
