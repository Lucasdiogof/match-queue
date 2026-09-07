-- Backstop server-side da expiracao: varre TODOS os times com um
-- SEARCHING vencido (o indice parcial em expires_at mantem isso barato) e
-- processa cada um sob o proprio lock, reaproveitando exatamente a mesma
-- logica da expiracao lazy -- nao existe um segundo caminho de "expirar".
--
-- Nunca executavel por anon/authenticated: so o agendador (pg_cron, que
-- roda com privilegio de banco, nao pelas roles de API) chama isto.
create function public.process_expired_searches()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_team record;
    v_count integer := 0;
begin
    for v_team in
        select distinct team_id
        from public.match_search_sessions
        where status = 'SEARCHING' and expires_at <= now()
    loop
        perform public._lock_team_matchmaking(v_team.team_id);
        perform public._expire_team_search_if_needed(v_team.team_id);
        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;

comment on function public.process_expired_searches() is
    'Varredura server-side: expira toda busca vencida e promove o proximo. So o cron chama.';

revoke execute on function public.process_expired_searches()
    from public, anon, authenticated;

-- pg_cron: minimo do agendador e granularidade de segundos com uma string
-- de intervalo (nao so cron expression de minuto) desde a 1.5 -- a 1.6.4
-- disponivel aqui suporta. 30 segundos e um meio-termo: nao e "a cada
-- milissegundo" (nem precisa, a expiracao lazy ja cobre o caso de alguem
-- interagir antes disso), mas corrige o estado no maximo 30s depois do
-- prazo mesmo com o app fechado em todo mundo -- bem abaixo da duracao
-- minima de busca (30s) que a Etapa 3 permite configurar.
create extension if not exists pg_cron with schema cron;

select cron.schedule(
    'matchmaking-expire-searches',
    '30 seconds',
    $$select public.process_expired_searches();$$
);
