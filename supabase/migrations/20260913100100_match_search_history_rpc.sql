-- Leitura do historico de buscas de um time.
--
-- Mesma postura das Etapas 4-5: match_search_sessions continua sem policy e
-- sem grant nenhum. Ninguem faz select direto -- nem para "so ler o proprio
-- historico". A unica porta e esta funcao, que confere membership antes de
-- devolver qualquer coisa. Filtrar no cliente depois de baixar tudo nunca
-- foi opcao: o dado nao sai do banco sem a checagem.
--
-- Paginacao e por cursor keyset, nunca OFFSET. O cursor e o par
-- (finished_at, id) da ultima linha entregue, e a proxima pagina pede
-- estritamente o que vem depois dele. Isso mantem a pagina estavel mesmo
-- com sessoes novas sendo encerradas entre uma pagina e outra: uma linha
-- nova entra no topo, nao no meio da janela que o usuario ja passou.
create function public.get_team_match_search_history(
    p_team_id uuid,
    p_limit integer default 20,
    p_cursor_finished_at timestamptz default null,
    p_cursor_id uuid default null,
    p_status text default null,
    p_user_id uuid default null,
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
    v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
    v_rows jsonb;
    v_count integer;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not public.is_team_member(p_team_id) then
        raise exception 'not a member of this team' using errcode = 'FQ012';
    end if;

    -- p_status nao ganha validacao explicita nem codigo de erro proprio: o
    -- conjunto e fechado ('MATCH_FOUND', 'CANCELLED', 'EXPIRED') e vem de
    -- chips da UI, nunca de texto livre. Um valor fora dele simplesmente nao
    -- casa com nenhuma linha, que ja e a resposta honesta -- inventar um FQ
    -- para uma validacao que a UI torna inalcancavel seria ruido.

    -- Busca v_limit + 1 para saber se existe proxima pagina sem precisar de
    -- um count() separado sobre o historico inteiro.
    select coalesce(jsonb_agg(item order by ord), '[]'::jsonb), count(*)
    into v_rows, v_count
    from (
        select
            row_number() over (
                order by s.finished_at desc, s.id desc
            ) as ord,
            jsonb_build_object(
                'session_id', s.id,
                'user_id', s.user_id,
                -- Sem snapshot de nome de proposito: user_id referencia
                -- profiles com on delete restrict, entao o perfil nao pode
                -- sumir enquanto houver historico dele, e este join nunca
                -- fica orfao. Sair do time tambem nao apaga o profile. Ver
                -- docs/database.md.
                'display_name', coalesce(p.display_name, ''),
                'avatar_url', p.avatar_url,
                'status', s.status,
                'finish_reason', s.finish_reason,
                'started_at', to_jsonb(s.started_at),
                'finished_at', to_jsonb(s.finished_at),
                'duration_seconds',
                    round(extract(epoch from (s.finished_at - s.started_at)))::int,
                -- A duracao configurada NAQUELE momento nao precisa ser
                -- guardada: ela e exatamente a janela que a sessao recebeu
                -- ao nascer. Mudar a configuracao do time depois nao
                -- reescreve o passado.
                'configured_duration_seconds',
                    round(extract(epoch from (s.expires_at - s.started_at)))::int
            ) as item
        from public.match_search_sessions as s
        left join public.profiles as p on p.id = s.user_id
        where s.team_id = p_team_id
          and s.finished_at is not null
          and (p_status is null or s.status = p_status)
          and (p_user_id is null or s.user_id = p_user_id)
          and (p_from is null or s.finished_at >= p_from)
          and (p_to is null or s.finished_at < p_to)
          and (
              p_cursor_finished_at is null
              or p_cursor_id is null
              or (s.finished_at, s.id) < (p_cursor_finished_at, p_cursor_id)
          )
        order by s.finished_at desc, s.id desc
        limit v_limit + 1
    ) as page;

    v_items := case
        when v_count > v_limit then
            (select jsonb_agg(value)
             from jsonb_array_elements(v_rows) with ordinality as t(value, i)
             where i <= v_limit)
        else v_rows
    end;

    return jsonb_build_object(
        'server_now', to_jsonb(now()),
        'team_id', p_team_id,
        'items', coalesce(v_items, '[]'::jsonb),
        'has_more', v_count > v_limit,
        'next_cursor', case
            when v_count > v_limit then jsonb_build_object(
                'finished_at', v_items -> (v_limit - 1) -> 'finished_at',
                'id', v_items -> (v_limit - 1) -> 'session_id'
            )
            else null
        end
    );
end;
$$;

revoke execute on function public.get_team_match_search_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) from public, anon;

grant execute on function public.get_team_match_search_history(
    uuid, integer, timestamptz, uuid, text, uuid, timestamptz, timestamptz
) to authenticated;
