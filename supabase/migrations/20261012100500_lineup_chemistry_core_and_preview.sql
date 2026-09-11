-- Quimica passa a ter UM core, alimentado por uma escalacao explicita.
--
-- Motivo: o builder virou rascunho local, entao a tela precisa mostrar a
-- quimica do que o usuario esta montando, nao a do que esta gravado. Portar
-- a regra para o Dart criaria uma segunda implementacao de 131 linhas que ja
-- foi corrigida tres vezes -- ela ia divergir, e divergir em silencio.
--
-- Desenho:
--   _fc_lineup_chemistry(formation, slots, manager, league)  <- a regra
--   _fc_squad_chemistry(squad_id)                            <- wrapper
--   preview_fc_squad_lineup(...)                             <- porta nova
--
-- ISTO E REFATORACAO. Nenhum limiar, peso ou capping muda. A prova esta no
-- fim do arquivo: a quimica de todos os elencos existentes e capturada
-- ANTES, recalculada DEPOIS, e qualquer diferenca aborta a migration -- como
-- tudo roda numa transacao so, um erro aqui desfaz o deploy inteiro.

-- ---------------------------------------------------------------------
-- Fotografia do comportamento atual, antes de trocar qualquer coisa.
-- ---------------------------------------------------------------------
create temporary table _chem_before on commit drop as
select id as squad_id, public._fc_squad_chemistry(id) as result
from public.fc_squads;

-- ---------------------------------------------------------------------
-- O core. Recebe a escalacao; nao sabe o que e um squad.
--
-- A derivacao por titular e exatamente a de antes: chaves de clube/liga/
-- nacao com id quando existe e nome quando nao (catalogo importado por nome
-- ainda pontua), bonus do tecnico pelas mesmas quatro comparacoes, e
-- elegibilidade por _fc_card_can_play contra a posicao do slot na formacao.
-- A unica coisa que mudou e de onde vem a lista.
-- ---------------------------------------------------------------------
create or replace function public._fc_lineup_chemistry(
    p_formation_code text,
    p_slots jsonb,
    p_manager_id uuid default null,
    p_manager_league_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_mgr_nation_id uuid;
    v_mgr_nation_name text;
    v_mgr_league_id uuid;
    v_mgr_league_name text;
    v_result jsonb;
begin
    select m.nation_id, nullif(btrim(n.name), '')
    into v_mgr_nation_id, v_mgr_nation_name
    from public.fc_managers as m
    left join public.fc_nations as n on n.id = m.nation_id
    where m.id = p_manager_id;

    select p_manager_league_id, nullif(btrim(l.name), '')
    into v_mgr_league_id, v_mgr_league_name
    from public.fc_leagues as l
    where l.id = p_manager_league_id;

    with given as (
        select
            item->>'slot_code' as slot_code,
            (item->>'player_card_id')::uuid as card_id
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ),
    starters as (
        select
            g.slot_code,
            coalesce(c.club_id::text, nullif(btrim(c.club_name), '')) as club_key,
            coalesce(c.league_id::text, nullif(btrim(c.league_name), '')) as league_key,
            coalesce(c.nation_id::text, nullif(btrim(c.nation_name), '')) as nation_key,
            (
                (v_mgr_nation_id is not null and c.nation_id = v_mgr_nation_id)
                or (v_mgr_nation_name is not null
                    and btrim(c.nation_name) = v_mgr_nation_name)
                or (v_mgr_league_id is not null and c.league_id = v_mgr_league_id)
                or (v_mgr_league_name is not null
                    and btrim(c.league_name) = v_mgr_league_name)
            ) as manager_bonus,
            public._fc_card_can_play(c.id, fs.position_code) as eligible
        from given as g
        join public.fc_formation_slots as fs
            on fs.formation_code = p_formation_code and fs.slot_code = g.slot_code
        join public.fc_player_cards as c on c.id = g.card_id
    ),
    -- Pool de contagem: so quem esta NA posicao. Um jogador fora de posicao
    -- nunca soma para o link de outro titular.
    pool as (
        select * from starters where eligible
    ),
    counted as (
        select
            st.slot_code,
            st.eligible,
            st.manager_bonus,
            case when st.club_key is null then 0 else
                (select count(*) from pool where pool.club_key = st.club_key) end as club_count,
            case when st.league_key is null then 0 else
                (select count(*) from pool where pool.league_key = st.league_key) end as league_count,
            case when st.nation_key is null then 0 else
                (select count(*) from pool where pool.nation_key = st.nation_key) end as nation_count
        from starters as st
    ),
    scored as (
        select
            ct.slot_code,
            ct.eligible,
            case when not ct.eligible then 0
                when ct.club_count >= 7 then 3
                when ct.club_count >= 4 then 2
                when ct.club_count >= 2 then 1
                else 0 end as club_points,
            case when not ct.eligible then 0
                when ct.league_count >= 8 then 3
                when ct.league_count >= 5 then 2
                when ct.league_count >= 3 then 1
                else 0 end as league_points,
            case when not ct.eligible then 0
                when ct.nation_count >= 8 then 3
                when ct.nation_count >= 5 then 2
                when ct.nation_count >= 2 then 1
                else 0 end as nation_points,
            case when ct.eligible and ct.manager_bonus then 1 else 0 end as manager_points,
            ct.club_count,
            ct.league_count,
            ct.nation_count
        from counted as ct
    ),
    final as (
        select
            sc.*,
            (sc.club_points + sc.league_points + sc.nation_points
                + sc.manager_points) as raw_points,
            least(3, sc.club_points + sc.league_points + sc.nation_points
                + sc.manager_points) as chemistry
        from scored as sc
    )
    select jsonb_build_object(
        'version', public._fc_chemistry_rule_version(),
        'total', coalesce((select sum(chemistry) from final), 0),
        'per_slot', coalesce(
            (select jsonb_object_agg(slot_code, chemistry) from final), '{}'::jsonb
        ),
        'out_of_position_slots', coalesce(
            (select jsonb_agg(slot_code) from final where not eligible), '[]'::jsonb
        ),
        'breakdown_per_slot', coalesce(
            (select jsonb_object_agg(slot_code, jsonb_build_object(
                'total', chemistry,
                'eligible', eligible,
                'capped', raw_points > chemistry,
                'club', club_points,
                'league', league_points,
                'nation', nation_points,
                'manager', manager_points,
                'club_count', club_count,
                'league_count', league_count,
                'nation_count', nation_count
            )) from final), '{}'::jsonb
        )
    ) into v_result;

    return v_result;
end;
$$;

comment on function public._fc_lineup_chemistry(text, jsonb, uuid, uuid) is
    'Regra de quimica. Unica implementacao: o squad persistido e o preview do rascunho passam os dois por aqui.';

revoke execute on function public._fc_lineup_chemistry(text, jsonb, uuid, uuid)
    from public, anon;

-- ---------------------------------------------------------------------
-- A funcao antiga vira wrapper: monta a representacao e delega. Continua
-- existindo com a mesma assinatura porque get_fc_squad_builder,
-- _public_squad_card_json e o snapshot de partida chamam ela.
-- ---------------------------------------------------------------------
create or replace function public._fc_squad_chemistry(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_formation text;
    v_manager_id uuid;
    v_manager_league_id uuid;
    v_slots jsonb;
begin
    select formation_code, manager_id, manager_league_id
    into v_formation, v_manager_id, v_manager_league_id
    from public.fc_squads where id = p_squad_id;

    select coalesce(
        jsonb_agg(jsonb_build_object(
            'slot_code', sl.slot_code,
            'player_card_id', sl.player_card_id
        )), '[]'::jsonb
    )
    into v_slots
    from public.fc_squad_slots as sl
    where sl.squad_id = p_squad_id and sl.slot_type = 'STARTING';

    return public._fc_lineup_chemistry(
        v_formation, v_slots, v_manager_id, v_manager_league_id
    );
end;
$$;

-- ---------------------------------------------------------------------
-- Validacao compartilhada entre preview e save.
--
-- Extraida para que as duas portas leiam o mesmo rascunho do mesmo jeito:
-- se o preview aceitasse algo que o save recusa, a tela diria "quimica 28" e
-- o Salvar falharia depois -- pior que nao mostrar nada.
-- ---------------------------------------------------------------------
create or replace function public._assert_valid_lineup(
    p_formation_code text,
    p_slots jsonb,
    p_manager_id uuid default null,
    p_manager_league_id uuid default null
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_invalid text;
    v_slot_count integer;
    v_given integer;
begin
    if jsonb_typeof(coalesce(p_slots, '[]'::jsonb)) <> 'array' then
        raise exception 'invalid slots payload' using errcode = 'FQ050';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    select count(*) into v_given
    from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item;

    select count(*) into v_slot_count
    from public.fc_formation_slots where formation_code = p_formation_code;

    if v_given > v_slot_count then
        raise exception 'too many starters' using errcode = 'FQ050';
    end if;

    select g.slot_code into v_invalid
    from (
        select item->>'slot_code' as slot_code
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ) as g
    where not exists (
        select 1 from public.fc_formation_slots as fs
        where fs.formation_code = p_formation_code and fs.slot_code = g.slot_code
    )
    limit 1;
    if v_invalid is not null then
        raise exception 'slot % not in formation', v_invalid using errcode = 'FQ050';
    end if;

    if exists (
        select 1 from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
        group by item->>'slot_code' having count(*) > 1
    ) then
        raise exception 'duplicated slot' using errcode = 'FQ050';
    end if;

    if exists (
        select 1 from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
        group by item->>'player_card_id' having count(*) > 1
    ) then
        raise exception 'duplicated player' using errcode = 'FQ051';
    end if;

    -- Carta inexistente: sem isto o join silenciosamente descartaria o slot
    -- e a quimica sairia calculada sobre menos gente do que o cliente mandou.
    select g.slot_code into v_invalid
    from (
        select item->>'slot_code' as slot_code,
               (item->>'player_card_id')::uuid as card_id
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ) as g
    where not exists (
        select 1 from public.fc_player_cards where id = g.card_id
    )
    limit 1;
    if v_invalid is not null then
        raise exception 'card not found for slot %', v_invalid using errcode = 'FQ050';
    end if;

    select g.slot_code into v_invalid
    from (
        select item->>'slot_code' as slot_code,
               (item->>'player_card_id')::uuid as card_id
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ) as g
    join public.fc_formation_slots as fs
        on fs.formation_code = p_formation_code and fs.slot_code = g.slot_code
    where not public._fc_card_can_play(g.card_id, fs.position_code)
    limit 1;
    if v_invalid is not null then
        raise exception 'card not eligible for slot %', v_invalid using errcode = 'FQ052';
    end if;

    if p_manager_id is not null
       and not exists (select 1 from public.fc_managers where id = p_manager_id) then
        raise exception 'manager not found' using errcode = 'FQ032';
    end if;

    if p_manager_league_id is not null
       and not exists (select 1 from public.fc_leagues where id = p_manager_league_id) then
        raise exception 'league not found' using errcode = 'FQ032';
    end if;
end;
$$;

revoke execute on function public._assert_valid_lineup(text, jsonb, uuid, uuid)
    from public, anon;

-- ---------------------------------------------------------------------
-- Preview: calcula, nao escreve.
--
-- Declarada STABLE, que no Postgres ja proibe a funcao de gravar -- a
-- garantia de "nao persiste" e do motor, nao da leitura do codigo.
-- ---------------------------------------------------------------------
create or replace function public.preview_fc_squad_lineup(
    p_squad_id uuid,
    p_formation_code text,
    p_slots jsonb default '[]'::jsonb,
    p_manager_id uuid default null,
    p_manager_league_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    perform public._assert_valid_lineup(
        p_formation_code, p_slots, p_manager_id, p_manager_league_id
    );

    return jsonb_build_object(
        'chemistry', public._fc_lineup_chemistry(
            p_formation_code, p_slots, p_manager_id, p_manager_league_id
        ),
        -- Overall vai junto para a tela nao precisar de duas fontes; o Dart
        -- calcula o mesmo localmente para responder na hora, e isto serve de
        -- conferencia.
        'overall', (
            select round(avg(c.rating))::int
            from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
            join public.fc_player_cards as c
                on c.id = (item->>'player_card_id')::uuid
        )
    );
end;
$$;

comment on function public.preview_fc_squad_lineup(uuid, text, jsonb, uuid, uuid) is
    'Quimica/overall de um rascunho, sem persistir. Mesma regra e mesmas validacoes do save.';

revoke execute on function public.preview_fc_squad_lineup(uuid, text, jsonb, uuid, uuid)
    from public, anon;
grant execute on function public.preview_fc_squad_lineup(uuid, text, jsonb, uuid, uuid)
    to authenticated;

-- ---------------------------------------------------------------------
-- PROVA DE PARIDADE.
--
-- Recalcula a quimica de todos os elencos existentes pelo caminho novo e
-- compara com a fotografia tirada no inicio do arquivo. Qualquer diferenca
-- levanta excecao e, como migration roda em transacao, desfaz tudo -- o
-- deploy nao passa com a regra alterada.
-- ---------------------------------------------------------------------
do $$
declare
    v_diff integer;
    v_example text;
begin
    select count(*), min(b.squad_id::text)
    into v_diff, v_example
    from _chem_before as b
    where b.result is distinct from public._fc_squad_chemistry(b.squad_id);

    if v_diff > 0 then
        raise exception
            'chemistry refactor changed results for % squad(s), first: %',
            v_diff, v_example;
    end if;

    raise notice 'chemistry parity verified for % squad(s)',
        (select count(*) from _chem_before);
end;
$$;
