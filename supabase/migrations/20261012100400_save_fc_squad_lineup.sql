-- Commit atomico do Elenco.
--
-- O builder persistia a cada toque: trocar formacao, escolher jogador e
-- limpar slot eram RPCs independentes. Com rascunho local, salvar viraria
-- uma sequencia de ate 13 chamadas, e uma falha no meio deixaria o elenco
-- pela metade no servidor. Aqui e uma transacao so: ou grava o elenco
-- inteiro, ou nao grava nada.
--
-- O cliente NAO e autoridade. Tudo que ele manda e revalidado aqui, com os
-- mesmos helpers que as RPCs antigas usam (_owns_fc_squad,
-- _fc_card_can_play) -- regra duplicada e regra que diverge.
--
-- Concorrencia: fc_squads ja tem updated_at mantido por trigger, entao nao
-- foi preciso inventar coluna de revisao. O draft carrega o updated_at de
-- quando foi carregado e o devolve em p_expected_updated_at; se o registro
-- mudou desde entao (outro aparelho salvou), levanta FQ049 em vez de
-- sobrescrever em silencio.
--
-- Banco/reservas nao sao tocados: esta funcao so mexe nos titulares. As
-- linhas BENCH que existirem continuam onde estao -- sumiram da interface,
-- mas nao vao ser apagadas por um save de escalacao.

create or replace function public.save_fc_squad_lineup(
    p_squad_id uuid,
    p_formation_code text,
    p_slots jsonb default '[]'::jsonb,
    p_manager_id uuid default null,
    p_manager_league_id uuid default null,
    p_expected_updated_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_updated_at timestamptz;
    v_is_active boolean;
    v_slot_count integer;
    v_given integer;
    v_invalid text;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select updated_at, is_active into v_updated_at, v_is_active
    from public.fc_squads
    where id = p_squad_id
    for update;

    if not v_is_active then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    -- Comparacao exata de propósito: updated_at vem do proprio servidor, o
    -- cliente so devolve o que recebeu. Tolerancia aqui abriria a janela que
    -- a checagem existe para fechar.
    if p_expected_updated_at is not null
       and v_updated_at is distinct from p_expected_updated_at then
        raise exception 'squad changed elsewhere' using errcode = 'FQ049';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    -- ---------------------------------------------------------------
    -- Validacao do payload. Tudo antes de qualquer escrita.
    -- ---------------------------------------------------------------
    if jsonb_typeof(p_slots) <> 'array' then
        raise exception 'invalid slots payload' using errcode = 'FQ050';
    end if;

    with given as (
        select
            item->>'slot_code' as slot_code,
            (item->>'player_card_id')::uuid as card_id
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    )
    select count(*) into v_given from given;

    select count(*) into v_slot_count
    from public.fc_formation_slots
    where formation_code = p_formation_code;

    if v_given > v_slot_count then
        raise exception 'too many starters' using errcode = 'FQ050';
    end if;

    -- Slot que nao pertence a formacao.
    select g.slot_code into v_invalid
    from (
        select item->>'slot_code' as slot_code
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ) as g
    where not exists (
        select 1 from public.fc_formation_slots as fs
        where fs.formation_code = p_formation_code
          and fs.slot_code = g.slot_code
    )
    limit 1;
    if v_invalid is not null then
        raise exception 'slot % not in formation', v_invalid
            using errcode = 'FQ050';
    end if;

    -- Slot repetido no payload.
    if exists (
        select 1
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
        group by item->>'slot_code'
        having count(*) > 1
    ) then
        raise exception 'duplicated slot' using errcode = 'FQ050';
    end if;

    -- Mesmo jogador em dois slots.
    if exists (
        select 1
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
        group by item->>'player_card_id'
        having count(*) > 1
    ) then
        raise exception 'duplicated player' using errcode = 'FQ051';
    end if;

    -- Jogador que nao atua na posicao do slot. Mesma regra do resto do
    -- sistema: posicao principal ou alternativa declarada.
    select g.slot_code into v_invalid
    from (
        select
            item->>'slot_code' as slot_code,
            (item->>'player_card_id')::uuid as card_id
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
    ) as g
    join public.fc_formation_slots as fs
        on fs.formation_code = p_formation_code and fs.slot_code = g.slot_code
    where not public._fc_card_can_play(g.card_id, fs.position_code)
    limit 1;
    if v_invalid is not null then
        raise exception 'card not eligible for slot %', v_invalid
            using errcode = 'FQ052';
    end if;

    if p_manager_id is not null
       and not exists (select 1 from public.fc_managers where id = p_manager_id)
    then
        raise exception 'manager not found' using errcode = 'FQ032';
    end if;

    if p_manager_league_id is not null
       and not exists (
           select 1 from public.fc_leagues where id = p_manager_league_id
       )
    then
        raise exception 'league not found' using errcode = 'FQ032';
    end if;

    -- ---------------------------------------------------------------
    -- Escrita. So daqui pra baixo.
    -- ---------------------------------------------------------------
    delete from public.fc_squad_slots
    where squad_id = p_squad_id and slot_type = 'STARTING';

    insert into public.fc_squad_slots (squad_id, slot_type, slot_code, player_card_id)
    select
        p_squad_id,
        'STARTING',
        item->>'slot_code',
        (item->>'player_card_id')::uuid
    from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item;

    update public.fc_squads
    set formation_code = p_formation_code,
        manager_id = p_manager_id,
        manager_league_id = p_manager_league_id
    where id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

comment on function public.save_fc_squad_lineup(
    uuid, text, jsonb, uuid, uuid, timestamptz
) is
    'Grava o Elenco inteiro numa transacao. Revalida tudo e usa updated_at como controle de concorrencia (FQ049).';

revoke execute on function public.save_fc_squad_lineup(
    uuid, text, jsonb, uuid, uuid, timestamptz
) from public, anon;
grant execute on function public.save_fc_squad_lineup(
    uuid, text, jsonb, uuid, uuid, timestamptz
) to authenticated;

-- ---------------------------------------------------------------------
-- O builder passa a devolver updated_at.
--
-- Sem isso o cliente nao teria o que mandar em p_expected_updated_at e o
-- controle de concorrencia acima seria letra morta. E o mesmo read model de
-- 20260922100000 com UM campo a mais -- nenhuma outra linha mudou.
-- ---------------------------------------------------------------------
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
        -- Baseline de concorrencia do rascunho: volta em
        -- p_expected_updated_at no save.
        'updated_at', v_squad.updated_at,
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
                    'chemistry_sources', case when sl.slot_type = 'STARTING'
                        then (v_chem -> 'breakdown_per_slot' -> sl.slot_code)
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
