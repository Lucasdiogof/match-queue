-- Escalar fora de posicao deixa de ser bloqueado no save. Decisao explicita
-- do dono do produto: o jogador pode colocar qualquer carta em qualquer
-- slot -- a unica regra que continua e nunca repetir a mesma carta em dois
-- slots (FQ051, intocado). Fora de posicao ja tinha efeito real sem
-- precisar de bloqueio nenhum: a quimica do slot fica zerada e
-- position_eligible vira false (ver _fc_squad_chemistry/get_fc_squad_builder,
-- ambos intocados aqui) -- isso e a penalidade, nao um erro de validacao.
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

    -- Mesmo jogador em dois slots -- unica regra de elegibilidade que
    -- continua existindo.
    if exists (
        select 1
        from jsonb_array_elements(coalesce(p_slots, '[]'::jsonb)) as item
        group by item->>'player_card_id'
        having count(*) > 1
    ) then
        raise exception 'duplicated player' using errcode = 'FQ051';
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
    'Grava o Elenco inteiro numa transacao. Revalida tudo e usa updated_at como controle de concorrencia (FQ049). Fora de posicao e permitido -- so carta duplicada (FQ051) bloqueia.';

revoke execute on function public.save_fc_squad_lineup(
    uuid, text, jsonb, uuid, uuid, timestamptz
) from public, anon;
grant execute on function public.save_fc_squad_lineup(
    uuid, text, jsonb, uuid, uuid, timestamptz
) to authenticated;
