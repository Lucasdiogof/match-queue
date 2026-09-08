-- Alterar o tempo de busca do time.
--
-- A RLS de teams ja restringe update a OWNER/ADMIN desde a Etapa 3, entao a
-- autorizacao nunca dependeu de esconder botao. O que essa RPC acrescenta e
-- uma resposta HONESTA quando a autorizacao falha: pelo caminho do update
-- direto, um PLAYER recebe zero linhas e o cliente traduz isso como "nao
-- encontrado", que e enganoso. Aqui ele recebe FQ012 -- permissao negada --
-- e a UI consegue dizer a verdade.
--
-- IMPORTANTE: esta funcao NAO toca em match_search_sessions. Isso e a
-- garantia, por construcao e nao por cuidado, de que mudar a configuracao
-- nunca mexe na sessao que ja esta rodando: o expires_at de quem esta
-- buscando foi calculado no momento da promocao e continua valendo. A
-- duracao nova entra em vigor na PROXIMA sessao, porque
-- _promote_next_queued_player le teams.default_search_duration_seconds na
-- hora em que promove.
create function public.update_team_search_duration(
    p_team_id uuid,
    p_seconds integer
)
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
        raise exception 'only an owner or admin can change the search duration'
            using errcode = 'FQ012';
    end if;

    -- Mesma faixa da constraint teams_search_duration_range. Checar aqui
    -- devolve FQ007 (que o app ja sabe traduzir) em vez do 23514 cru do
    -- Postgres.
    if p_seconds is null or p_seconds < 30 or p_seconds > 600 then
        raise exception 'search duration must be between 30 and 600 seconds'
            using errcode = 'FQ007';
    end if;

    update public.teams
    set default_search_duration_seconds = p_seconds
    where id = p_team_id
    returning * into v_team;

    -- Sem checagem de "time nao encontrado": is_team_admin so retorna true
    -- se existir linha em team_members, que tem FK para teams. Chegar aqui
    -- ja prova que o time existe, e o update nao tem como nao casar.
    return v_team;
end;
$$;

revoke execute on function public.update_team_search_duration(uuid, integer)
    from public, anon;

grant execute on function public.update_team_search_duration(uuid, integer)
    to authenticated;
