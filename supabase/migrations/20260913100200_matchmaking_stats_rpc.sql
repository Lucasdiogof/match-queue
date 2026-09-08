-- Estatisticas de matchmaking de um time.
--
-- Uma chamada devolve totais do time E a quebra por jogador. O Flutter nunca
-- faz N queries nem agrega no cliente: o read model ja chega pronto.
--
-- DEFINICOES (as mesmas em toda a UI):
--   * So entram sessoes CONCLUIDAS. A sessao SEARCHING em andamento nao tem
--     desfecho ainda -- conta-la como fracasso ou como sucesso seria mentira
--     nos dois sentidos, entao ela fica fora ate terminar.
--   * sucesso = MATCH_FOUND. CANCELLED e EXPIRED nao sao sucesso. Nao ha
--     terceira interpretacao.
--   * taxa de sucesso = MATCH_FOUND / sessoes concluidas no periodo.
--   * duracao = finished_at - started_at, medida pelo relogio do servidor.
--     O timer do cliente e so desenho e nunca alimenta metrica.
--
-- "MATCH_FOUND" e "partida encontrada", nao "partida jogada" nem "vitoria":
-- o produto sabe que a busca terminou com partida achada, e nada alem disso.
create function public.get_team_matchmaking_stats(
    p_team_id uuid,
    p_from timestamptz default null,
    p_to timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_totals jsonb;
    v_players jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    with finished as (
        select
            s.user_id,
            s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    )
    select
        jsonb_build_object(
            'total', count(*),
            'match_found', count(*) filter (where status = 'MATCH_FOUND'),
            'cancelled', count(*) filter (where status = 'CANCELLED'),
            'expired', count(*) filter (where status = 'EXPIRED'),
            -- null, nao zero: sem sessao concluida nao existe taxa, e zero
            -- leria como "nunca acharam partida".
            'success_rate', case
                when count(*) = 0 then null
                else round(
                    count(*) filter (where status = 'MATCH_FOUND')::numeric
                        / count(*), 4)
            end,
            'avg_duration_seconds', case
                when count(*) = 0 then null
                else round(avg(duration))::int
            end
        )
    into v_totals
    from finished;

    with finished as (
        select
            s.user_id,
            s.status,
            extract(epoch from (s.finished_at - s.started_at)) as duration
        from public.match_search_sessions as s
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
    ),
    per_player as (
        select
            f.user_id,
            count(*) as total,
            count(*) filter (where f.status = 'MATCH_FOUND') as match_found,
            count(*) filter (where f.status = 'CANCELLED') as cancelled,
            count(*) filter (where f.status = 'EXPIRED') as expired,
            round(
                count(*) filter (where f.status = 'MATCH_FOUND')::numeric
                    / count(*), 4) as success_rate,
            round(avg(f.duration))::int as avg_duration_seconds
        from finished as f
        group by f.user_id
    )
    -- A lista sai de quem REALMENTE buscou no periodo, nao da membership
    -- atual: quem saiu do time continua aparecendo no historico dele, e o
    -- filtro por jogador da UI se alimenta daqui em vez de team_members.
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'user_id', pp.user_id,
            'display_name', coalesce(pr.display_name, ''),
            'avatar_url', pr.avatar_url,
            'total', pp.total,
            'match_found', pp.match_found,
            'cancelled', pp.cancelled,
            'expired', pp.expired,
            'success_rate', pp.success_rate,
            'avg_duration_seconds', pp.avg_duration_seconds
        )
        order by pp.total desc, coalesce(pr.display_name, '') asc
    ), '[]'::jsonb)
    into v_players
    from per_player as pp
    left join public.profiles as pr on pr.id = pp.user_id;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'from', to_jsonb(p_from),
        'to', to_jsonb(p_to),
        'totals', v_totals,
        'players', v_players
    );
end;
$$;

revoke execute on function public.get_team_matchmaking_stats(
    uuid, timestamptz, timestamptz
) from public, anon;

grant execute on function public.get_team_matchmaking_stats(
    uuid, timestamptz, timestamptz
) to authenticated;
