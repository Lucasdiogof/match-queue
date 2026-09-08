-- Etapa 13: overall + quimica do squad (server-side), reservas (5, alem do
-- banco de 7), e "Limpar escalacao".
--
-- ESCOPO: so backend. Nenhuma migration antiga foi editada -- get_fc_squad_
-- builder/list_fc_squads ganham campos novos via create or replace (mesma
-- assinatura, aditivo puro: quem ja consome essas RPCs ignora chave nova sem
-- quebrar).
--
-- Quimica: pesquisada (nao inventada) em 2026-09-08, fontes:
--   https://fifauteam.com/fc-25-chemistry/
--   https://estnn.com/ea-fc-25-chemistry-system-explained/
-- Regra do sistema simplificado introduzido em FIFA 23 e mantido em
-- FC24/FC25 (33 pontos totais, 0-3 por titular). Documentado e isolado na
-- funcao _compute_fc_squad_chemistry / _fc_squad_chemistry, versionado por
-- public._fc_chemistry_rule_version() = 'FC_MODERN_V1' -- nunca espalhado
-- pelo resto do SQL. Uma regra futura (Icons/Heroes, versoes especiais)
-- troca so essa funcao e o texto da versao, sem mexer em quem consome.
--
-- Regra FC_MODERN_V1, exatamente como pesquisada:
--   - So titulares (STARTING) pontuam quimica. Banco e reservas NUNCA
--     entram (item 34/57).
--   - Jogador fora de posicao (nem primaria nem alternativa bate com a
--     posicao do slot) tem quimica = 0 E nao conta para a quimica de
--     ninguem mais -- exatamente a regra pesquisada ("won't be taken into
--     consideration for the teammate's chemistry").
--   - Para titulares NA posicao, conta-se quantos outros titulares (tambem
--     na posicao) compartilham clube/liga/nacao:
--       clube:  2 -> +1, 4 -> +2, 7 -> +3
--       liga:   3 -> +1, 5 -> +2, 8 -> +3
--       nacao:  2 -> +1, 5 -> +2, 8 -> +3
--   - Tecnico: +1 se o titular compartilha nacao OU liga com o
--     nation_id/manager_league_id do squad -- capado em +1 mesmo batendo
--     os dois (regra pesquisada: "capped at one point").
--   - Soma dos quatro componentes, capada em 3 por jogador (min(3, soma)).
--   - Extensivel a tipos especiais de carta (Icons/Heroes contam para
--     qualquer liga/nacao no jogo real) -- NAO implementado agora, so a
--     estrutura (uma funcao isolada, chave por card) fica pronta para essa
--     excecao entrar depois sem reescrever quem consome.

create function public._fc_chemistry_rule_version()
returns text
language sql
immutable
set search_path = ''
as $$
    select 'FC_MODERN_V1';
$$;

comment on function public._fc_chemistry_rule_version() is
    'Versao da regra de quimica em uso. Trocar a regra = trocar este texto + o corpo de _fc_squad_chemistry, nunca espalhar a decisao em outro lugar.';

revoke execute on function public._fc_chemistry_rule_version()
    from public, anon;

-- Reservas: 5, alem do banco de 7 ja existente (item 34). Numero de produto,
-- nao um limite oficial de UT (a pesquisa desta etapa nao encontrou um
-- limite claro/publico para replicar) -- 11 titulares + 7 banco + 5
-- reservas = 23, tamanho compativel com uma convocacao real de partida.
-- Nunca entram na quimica, exatamente como o banco.
create function public._fc_reserve_size()
returns integer
language sql
immutable
set search_path = ''
as $$
    select 5;
$$;

comment on function public._fc_reserve_size() is
    'Tamanho do slot de reservas (5). Numero de produto, documentado no handoff da Etapa 13 -- nao e um limite oficial replicado de nenhuma fonte.';

revoke execute on function public._fc_reserve_size() from public, anon;

alter table public.fc_squad_slots drop constraint fc_squad_slots_type_check;
alter table public.fc_squad_slots add constraint fc_squad_slots_type_check
    check (slot_type in ('STARTING', 'BENCH', 'RESERVE'));

comment on table public.fc_squad_slots is
    'Somente slots PREENCHIDOS. Slot vazio = ausencia de linha. RESERVE (Etapa 13) segue o mesmo padrao de BENCH: sem posicao imposta, nunca conta para quimica.';

-- Generaliza a validacao de slot para aceitar RESERVE_1..RESERVE_5 no mesmo
-- padrao de BENCH_1..BENCH_7 -- mesma assinatura, so o corpo muda.
create or replace function public._fc_slot_position(
    p_squad_id uuid,
    p_slot_type text,
    p_slot_code text
)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_pos text;
    v_index integer;
    v_max integer;
begin
    if p_slot_type = 'STARTING' then
        select fs.position_code into v_pos
        from public.fc_squads as s
        join public.fc_formation_slots as fs
            on fs.formation_code = s.formation_code
        where s.id = p_squad_id and fs.slot_code = p_slot_code;

        if v_pos is null then
            raise exception 'invalid slot for this formation'
                using errcode = 'FQ032';
        end if;
        return v_pos;
    end if;

    if p_slot_type = 'BENCH' then
        v_max := public._fc_bench_size();
    elsif p_slot_type = 'RESERVE' then
        v_max := public._fc_reserve_size();
    else
        raise exception 'invalid slot type' using errcode = 'FQ032';
    end if;

    if p_slot_code !~ ('^' || p_slot_type || '_[0-9]+$') then
        raise exception 'invalid slot code' using errcode = 'FQ032';
    end if;

    v_index := substring(p_slot_code from (char_length(p_slot_type) + 2))::integer;
    if v_index < 1 or v_index > v_max then
        raise exception 'invalid slot index' using errcode = 'FQ032';
    end if;

    -- Banco e reservas nao exigem posicao: qualquer carta senta ali.
    return null;
end;
$$;

-- Overall: media dos titulares PREENCHIDOS, arredondamento padrao do
-- Postgres (round() -> 0.5 arredonda para cima). Slot vazio nao entra na
-- media; sem nenhum titular preenchido, overall e null (nunca 0, que
-- pareceria "carta de rating zero"). filled_starters/starter_count deixam
-- claro quantos titulares existem preenchidos vs a grade da formacao atual.
create function public._fc_squad_overall(p_squad_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'overall', (
            select case when count(*) = 0 then null
                        else round(avg(c.rating))::int end
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = p_squad_id and sl.slot_type = 'STARTING'
        ),
        'filled_starters', (
            select count(*) from public.fc_squad_slots
            where squad_id = p_squad_id and slot_type = 'STARTING'
        )
    );
$$;

comment on function public._fc_squad_overall(uuid) is
    'Overall = media dos titulares preenchidos (round() padrao), null sem nenhum. Nunca conta banco/reservas.';

revoke execute on function public._fc_squad_overall(uuid) from public, anon;

-- Nucleo isolado da regra de quimica (FC_MODERN_V1). So titulares entram;
-- fora de posicao vira 0 e sai do "pool" que conta link de clube/liga/nacao
-- para os outros -- exatamente a regra pesquisada.
create function public._fc_squad_chemistry(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_manager_nation_id uuid;
    v_manager_league_id uuid;
    v_result jsonb;
begin
    select m.nation_id, s.manager_league_id
    into v_manager_nation_id, v_manager_league_id
    from public.fc_squads as s
    left join public.fc_managers as m on m.id = s.manager_id
    where s.id = p_squad_id;

    with starters as (
        select
            sl.slot_code,
            coalesce(c.club_id::text, nullif(btrim(c.club_name), '')) as club_key,
            coalesce(c.league_id::text, nullif(btrim(c.league_name), '')) as league_key,
            coalesce(c.nation_id::text, nullif(btrim(c.nation_name), '')) as nation_key,
            (
                (v_manager_nation_id is not null and c.nation_id = v_manager_nation_id)
                or (v_manager_league_id is not null and c.league_id = v_manager_league_id)
            ) as manager_bonus,
            public._fc_card_can_play(c.id, fs.position_code) as eligible
        from public.fc_squad_slots as sl
        join public.fc_squads as sq on sq.id = sl.squad_id
        join public.fc_formation_slots as fs
            on fs.formation_code = sq.formation_code and fs.slot_code = sl.slot_code
        join public.fc_player_cards as c on c.id = sl.player_card_id
        where sl.squad_id = p_squad_id and sl.slot_type = 'STARTING'
    ),
    -- Pool de contagem: so quem esta NA posicao. Um jogador fora de posicao
    -- nunca soma para o link de outro titular (regra pesquisada).
    pool as (
        select * from starters where eligible
    ),
    scored as (
        select
            st.slot_code,
            st.eligible,
            case when not st.eligible then 0 else least(3,
                (case
                    when st.club_key is null then 0
                    when (select count(*) from pool where pool.club_key = st.club_key) >= 7 then 3
                    when (select count(*) from pool where pool.club_key = st.club_key) >= 4 then 2
                    when (select count(*) from pool where pool.club_key = st.club_key) >= 2 then 1
                    else 0
                end)
                + (case
                    when st.league_key is null then 0
                    when (select count(*) from pool where pool.league_key = st.league_key) >= 8 then 3
                    when (select count(*) from pool where pool.league_key = st.league_key) >= 5 then 2
                    when (select count(*) from pool where pool.league_key = st.league_key) >= 3 then 1
                    else 0
                end)
                + (case
                    when st.nation_key is null then 0
                    when (select count(*) from pool where pool.nation_key = st.nation_key) >= 8 then 3
                    when (select count(*) from pool where pool.nation_key = st.nation_key) >= 5 then 2
                    when (select count(*) from pool where pool.nation_key = st.nation_key) >= 2 then 1
                    else 0
                end)
                + (case when st.manager_bonus then 1 else 0 end)
            ) end as chemistry
        from starters as st
    )
    select jsonb_build_object(
        'version', public._fc_chemistry_rule_version(),
        'total', coalesce((select sum(chemistry) from scored), 0),
        'per_slot', coalesce(
            (select jsonb_object_agg(slot_code, chemistry) from scored), '{}'::jsonb
        ),
        'out_of_position_slots', coalesce(
            (select jsonb_agg(slot_code) from scored where not eligible), '[]'::jsonb
        )
    ) into v_result;

    return v_result;
end;
$$;

comment on function public._fc_squad_chemistry(uuid) is
    'Regra FC_MODERN_V1 (ver comentario no topo da migration desta etapa e docs/handoff_etapa13.md). Nunca chamada pelo cliente diretamente -- so get_fc_squad_builder/list_fc_squads a consomem.';

revoke execute on function public._fc_squad_chemistry(uuid) from public, anon;

-- Read model do builder ganha overall/quimica/reservas -- mesma assinatura,
-- aditivo. Quem ja consumia esta RPC (create/rename/setFormation/etc, que
-- todas retornam o resultado dela) ganha os campos novos de graca.
create or replace function public.get_fc_squad_builder(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_squad public.fc_squads;
    v_chem jsonb;
    v_overall jsonb;
    v_result jsonb;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select * into v_squad from public.fc_squads where id = p_squad_id;
    v_chem := public._fc_squad_chemistry(p_squad_id);
    v_overall := public._fc_squad_overall(p_squad_id);

    select jsonb_build_object(
        'id', v_squad.id,
        'fc_account_id', v_squad.fc_account_id,
        'name', v_squad.name,
        'formation_code', v_squad.formation_code,
        'is_default', v_squad.is_default,
        'is_active', v_squad.is_active,
        'bench_size', public._fc_bench_size(),
        'reserve_size', public._fc_reserve_size(),
        'chemistry_rule_version', public._fc_chemistry_rule_version(),
        'chemistry', coalesce(v_chem -> 'total', '0'::jsonb),
        'overall', v_overall -> 'overall',
        'filled_starters', v_overall -> 'filled_starters',
        'starter_count', (
            select count(*) from public.fc_formation_slots
            where formation_code = v_squad.formation_code
        ),
        'formation', (
            select jsonb_build_object(
                'code', f.code,
                'display_name', f.display_name,
                'slots', (
                    select coalesce(jsonb_agg(
                        jsonb_build_object(
                            'slot_code', fs.slot_code,
                            'position_code', fs.position_code,
                            'x', fs.x,
                            'y', fs.y,
                            'sort_order', fs.sort_order
                        ) order by fs.sort_order
                    ), '[]'::jsonb)
                    from public.fc_formation_slots as fs
                    where fs.formation_code = f.code
                )
            )
            from public.fc_formations as f
            where f.code = v_squad.formation_code
        ),
        'slots', (
            select coalesce(jsonb_agg(
                jsonb_build_object(
                    'slot_type', sl.slot_type,
                    'slot_code', sl.slot_code,
                    'card', public._fc_card_json(c),
                    'chemistry', case when sl.slot_type = 'STARTING'
                        then (v_chem -> 'per_slot' -> sl.slot_code)
                        else null end,
                    'position_eligible', case when sl.slot_type = 'STARTING'
                        then not (
                            coalesce(v_chem -> 'out_of_position_slots', '[]'::jsonb)
                            ? sl.slot_code
                        )
                        else true end
                ) order by sl.slot_type, sl.slot_code
            ), '[]'::jsonb)
            from public.fc_squad_slots as sl
            join public.fc_player_cards as c on c.id = sl.player_card_id
            where sl.squad_id = p_squad_id
        ),
        'manager', (
            select jsonb_build_object(
                'id', m.id,
                'name', m.name,
                'image_url', m.image_url,
                'nation', case when n.id is null then null else jsonb_build_object(
                    'id', n.id, 'name', n.name, 'flag_image_url', n.flag_image_url
                ) end
            )
            from public.fc_managers as m
            left join public.fc_nations as n on n.id = m.nation_id
            where m.id = v_squad.manager_id
        ),
        'manager_league', (
            select jsonb_build_object('id', l.id, 'name', l.name,
                                      'logo_image_url', l.logo_image_url)
            from public.fc_leagues as l
            where l.id = v_squad.manager_league_id
        )
    ) into v_result;

    return v_result;
end;
$$;

-- Lista de squads (seletor de Conta/Jogar, Etapa 13 item 10) ganha overall/
-- quimica/reservas por linha -- mesma assinatura.
create or replace function public.list_fc_squads(p_fc_account_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = (select auth.uid())
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    return (
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'id', s.id,
                'fc_account_id', s.fc_account_id,
                'name', s.name,
                'formation_code', s.formation_code,
                'is_default', s.is_default,
                'is_active', s.is_active,
                'starting_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'STARTING'
                ),
                'bench_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'BENCH'
                ),
                'reserve_count', (
                    select count(*) from public.fc_squad_slots
                    where squad_id = s.id and slot_type = 'RESERVE'
                ),
                'overall', (public._fc_squad_overall(s.id)) -> 'overall',
                'chemistry', coalesce(
                    (public._fc_squad_chemistry(s.id)) -> 'total', '0'::jsonb
                )
            ) order by s.is_default desc, s.created_at
        ), '[]'::jsonb)
        from public.fc_squads as s
        where s.fc_account_id = p_fc_account_id and s.is_active
    );
end;
$$;

-- "Limpar escalacao" (item 13 do pedido): apaga so os SLOTS (titulares +
-- banco + reservas), nunca o squad em si. Confirmacao mora no Flutter.
create function public.clear_fc_squad_slots(p_squad_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    delete from public.fc_squad_slots where squad_id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.clear_fc_squad_slots(uuid) from public, anon;
grant execute on function public.clear_fc_squad_slots(uuid) to authenticated;
