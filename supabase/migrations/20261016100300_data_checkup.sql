-- Funcao de diagnostico TEMPORARIA -- roda uma vez via REST (service_role),
-- resultado lido, depois removida numa migration de limpeza. Nunca deve
-- ficar no schema definitivo.
create function public._data_checkup()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_result jsonb := '{}'::jsonb;
    v_part jsonb;
begin
    -- 1. Nomes duplicados (case-insensitive) em catalogos de referencia --
    -- mesmo padrao do bug ja corrigido em fc_nations (Brasil/Brazil).
    select coalesce(jsonb_agg(jsonb_build_object(
        'table', 'fc_nations', 'name', lower(name), 'count', cnt,
        'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select lower(name) as name, count(*) as cnt, jsonb_agg(id) as ids
        from public.fc_nations group by lower(name) having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_nation_names', v_part);

    select coalesce(jsonb_agg(jsonb_build_object(
        'table', 'fc_leagues', 'name', lower(name), 'count', cnt, 'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select lower(name) as name, count(*) as cnt, jsonb_agg(id) as ids
        from public.fc_leagues group by lower(name) having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_league_names', v_part);

    select coalesce(jsonb_agg(jsonb_build_object(
        'name', lower(name), 'count', cnt, 'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select lower(name) as name, count(*) as cnt, jsonb_agg(id) as ids
        from public.fc_managers group by lower(name) having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_manager_names', v_part);

    -- Clube: mesmo nome DENTRO da mesma liga e suspeito (entre ligas
    -- diferentes e esperado, ja tratado como valido no importador).
    select coalesce(jsonb_agg(jsonb_build_object(
        'name', lower(name), 'league_id', league_id, 'count', cnt, 'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select lower(name) as name, league_id, count(*) as cnt, jsonb_agg(id) as ids
        from public.fc_clubs group by lower(name), league_id having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_clubs_same_league', v_part);

    -- 2. Cartoes/jogadores com provider_card_id/provider_player_id
    -- duplicado (o unique index so cobre provider+id NOT NULL -- confere
    -- tambem se sobrou algo sem nenhum dos dois, que nunca deveria ter
    -- sido importado).
    select coalesce(jsonb_agg(jsonb_build_object(
        'provider', provider, 'provider_card_id', provider_card_id,
        'count', cnt, 'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select provider, provider_card_id, count(*) as cnt, jsonb_agg(id) as ids
        from public.fc_player_cards
        where provider_card_id is not null
        group by provider, provider_card_id having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_player_cards', v_part);

    select to_jsonb(count(*)) into v_part
    from public.fc_player_cards
    where provider_card_id is null;
    v_result := v_result || jsonb_build_object('player_cards_without_provider_id', v_part);

    -- 3. weekend_league_events: verifica a correcao do incidente de hoje
    -- (uma linha por numero de semana, starts_at unico -- ja tem unique
    -- index, isto so confirma que nao ha OUTRO tipo de duplicata por
    -- numero com starts_at diferente).
    select coalesce(jsonb_agg(jsonb_build_object(
        'number', number, 'count', cnt, 'ids', ids
    )), '[]'::jsonb) into v_part
    from (
        select number, count(*) as cnt, jsonb_agg(id) as ids
        from public.weekend_league_events group by number having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_weekend_league_numbers', v_part);

    -- 4. team_members: exatamente 1 OWNER por time (ja garantido por
    -- unique index parcial, isto so confirma 0 tambem nao acontece --
    -- time sem dono nenhum, o que o index NAO pega sozinho), e user_id
    -- desnormalizado batendo com o dono real da fc_account (o trigger de
    -- sync deveria garantir isto sempre, confere se nao ha regressao).
    select coalesce(jsonb_agg(jsonb_build_object(
        'team_id', team_id, 'owner_count', cnt
    )), '[]'::jsonb) into v_part
    from (
        select team_id, count(*) as cnt
        from public.team_members where role = 'OWNER'
        group by team_id having count(*) <> 1
    ) t;
    v_result := v_result || jsonb_build_object('teams_without_exactly_one_owner', v_part);

    select coalesce(jsonb_agg(jsonb_build_object(
        'team_id', tm.team_id, 'fc_account_id', tm.fc_account_id,
        'stored_user_id', tm.user_id, 'real_owner_user_id', a.user_id
    )), '[]'::jsonb) into v_part
    from public.team_members as tm
    join public.user_fc_accounts as a on a.id = tm.fc_account_id
    where tm.user_id is distinct from a.user_id;
    v_result := v_result || jsonb_build_object('team_members_user_id_out_of_sync', v_part);

    -- Todo time tem que ter dono -- pega times sem NENHUMA linha OWNER
    -- (o check acima so ve times com >=1 linha e conta errada; este cobre
    -- times com zero).
    select coalesce(jsonb_agg(t.id), '[]'::jsonb) into v_part
    from public.teams as t
    where not exists (
        select 1 from public.team_members as tm
        where tm.team_id = t.id and tm.role = 'OWNER'
    );
    v_result := v_result || jsonb_build_object('teams_with_zero_owner_rows', v_part);

    -- 5. fc_account_teams sem a linha correspondente em team_members --
    -- nao e necessariamente erro (sao conceitos diferentes por design),
    -- mas informativo.
    select coalesce(jsonb_agg(jsonb_build_object(
        'fc_account_id', fat.fc_account_id, 'team_id', fat.team_id
    )), '[]'::jsonb) into v_part
    from public.fc_account_teams as fat
    where not exists (
        select 1 from public.team_members as tm
        where tm.fc_account_id = fat.fc_account_id and tm.team_id = fat.team_id
    );
    v_result := v_result || jsonb_build_object('fc_account_teams_without_membership', v_part);

    -- 6. team_invite_links: codigo duplicado (ja tem unique index --
    -- confirmacao).
    select coalesce(jsonb_agg(jsonb_build_object(
        'code', code, 'count', cnt
    )), '[]'::jsonb) into v_part
    from (
        select code, count(*) as cnt
        from public.team_invite_links group by code having count(*) > 1
    ) t;
    v_result := v_result || jsonb_build_object('duplicate_invite_codes', v_part);

    return v_result;
end;
$$;

grant execute on function public._data_checkup() to service_role;
