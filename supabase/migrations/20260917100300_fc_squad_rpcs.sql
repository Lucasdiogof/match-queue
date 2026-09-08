-- RPCs do Squad Builder.
--
-- Codigos novos desta etapa (FQ014 segue livre, nao inventar uso):
--   FQ029 squad inexistente ou de outro usuario
--   FQ030 nome de squad invalido
--   FQ031 formacao invalida
--   FQ032 slot invalido para a formacao/banco
--   FQ033 carta nao joga na posicao do slot
--   FQ034 squad em uso numa busca ativa
--
-- OWNERSHIP: auth.uid() -> user_fc_accounts.user_id -> fc_squads.
-- fc_account_id. Time NAO entra nessa cadeia: squad e pessoal, e admin de
-- time nao edita squad de ninguem (item 58).

-- Banco de 7, como o Ultimate Team. Reservas (os 5 extras) ficam para
-- depois; a funcao existe pra esse numero nao ficar espalhado em literal.
create function public._fc_bench_size()
returns integer language sql immutable set search_path = '' as $$
    select 7;
$$;

create function public._owns_fc_squad(p_squad_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.fc_squads as s
        join public.user_fc_accounts as a on a.id = s.fc_account_id
        where s.id = p_squad_id and a.user_id = (select auth.uid())
    );
$$;

revoke execute on function public._owns_fc_squad(uuid) from public, anon;
revoke execute on function public._fc_bench_size() from public, anon;

-- Elegibilidade: a carta joga na posicao se for a primaria dela ou uma das
-- alternativas. Nada de quimica aqui -- isso e Etapa futura.
create function public._fc_card_can_play(p_card_id uuid, p_position text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1 from public.fc_player_cards
        where id = p_card_id
          and (primary_position = p_position
               or p_position = any(alternative_positions))
    );
$$;

revoke execute on function public._fc_card_can_play(uuid, text)
    from public, anon;

-- Serializacao unica da carta. Existe para o formato nao divergir entre o
-- read model do builder, a busca do picker e o snapshot da partida.
create function public._fc_card_json(p_card public.fc_player_cards)
returns jsonb
language sql
immutable
set search_path = ''
as $$
    select jsonb_build_object(
        'id', p_card.id,
        'provider', p_card.provider,
        'player_name', p_card.player_name,
        'common_name', p_card.common_name,
        'rating', p_card.rating,
        'primary_position', p_card.primary_position,
        'alternative_positions', to_jsonb(p_card.alternative_positions),
        'pace', p_card.pace,
        'shooting', p_card.shooting,
        'passing', p_card.passing,
        'dribbling', p_card.dribbling,
        'defending', p_card.defending,
        'physical', p_card.physical,
        'player_image_url', p_card.player_image_url,
        'card_image_url', p_card.card_image_url,
        'club_name', p_card.club_name,
        'league_name', p_card.league_name,
        'nation_name', p_card.nation_name,
        'card_type', p_card.card_type
    );
$$;

revoke execute on function public._fc_card_json(public.fc_player_cards)
    from public, anon;

-- Read model completo do builder numa chamada so: squad + formacao + slots
-- do catalogo + cartas + tecnico. Evita N+1 e evita a UI montar a grade a
-- partir de conhecimento proprio de formacao.
create function public.get_fc_squad_builder(p_squad_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_squad public.fc_squads;
    v_result jsonb;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select * into v_squad from public.fc_squads where id = p_squad_id;

    select jsonb_build_object(
        'id', v_squad.id,
        'fc_account_id', v_squad.fc_account_id,
        'name', v_squad.name,
        'formation_code', v_squad.formation_code,
        'is_default', v_squad.is_default,
        'is_active', v_squad.is_active,
        'bench_size', public._fc_bench_size(),
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
                    'card', public._fc_card_json(c)
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

revoke execute on function public.get_fc_squad_builder(uuid) from public, anon;
grant execute on function public.get_fc_squad_builder(uuid) to authenticated;

create function public.list_fc_squads(p_fc_account_id uuid)
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
                )
            ) order by s.is_default desc, s.created_at
        ), '[]'::jsonb)
        from public.fc_squads as s
        where s.fc_account_id = p_fc_account_id and s.is_active
    );
end;
$$;

revoke execute on function public.list_fc_squads(uuid) from public, anon;
grant execute on function public.list_fc_squads(uuid) to authenticated;

create function public.create_fc_squad(
    p_fc_account_id uuid,
    p_name text,
    p_formation_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_name text := btrim(coalesce(p_name, ''));
    v_squad_id uuid;
    v_is_first boolean;
begin
    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id
          and user_id = (select auth.uid())
          and is_active
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if char_length(v_name) < 1 or char_length(v_name) > 40 then
        raise exception 'invalid squad name' using errcode = 'FQ030';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    -- Primeiro squad do elenco ja nasce default: sem isso o usuario teria de
    -- marcar manualmente para o Jogar pre-selecionar alguma coisa.
    select not exists (
        select 1 from public.fc_squads
        where fc_account_id = p_fc_account_id and is_active
    ) into v_is_first;

    insert into public.fc_squads (fc_account_id, name, formation_code, is_default)
    values (p_fc_account_id, v_name, p_formation_code, v_is_first)
    returning id into v_squad_id;

    return public.get_fc_squad_builder(v_squad_id);
end;
$$;

revoke execute on function public.create_fc_squad(uuid, text, text)
    from public, anon;
grant execute on function public.create_fc_squad(uuid, text, text)
    to authenticated;

create function public.update_fc_squad(p_squad_id uuid, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_name text := btrim(coalesce(p_name, ''));
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if char_length(v_name) < 1 or char_length(v_name) > 40 then
        raise exception 'invalid squad name' using errcode = 'FQ030';
    end if;

    update public.fc_squads set name = v_name where id = p_squad_id;
    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.update_fc_squad(uuid, text) from public, anon;
grant execute on function public.update_fc_squad(uuid, text) to authenticated;

create function public.set_default_fc_squad(p_squad_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_account_id uuid;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    select fc_account_id into v_account_id
    from public.fc_squads where id = p_squad_id;

    -- Limpa antes de marcar: o indice unico parcial so admite um default
    -- ativo por elenco, entao os dois updates precisam desta ordem.
    update public.fc_squads set is_default = false
    where fc_account_id = v_account_id and is_default and id <> p_squad_id;

    update public.fc_squads set is_default = true where id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.set_default_fc_squad(uuid) from public, anon;
grant execute on function public.set_default_fc_squad(uuid) to authenticated;

create function public.archive_fc_squad(p_squad_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_account_id uuid;
    v_was_default boolean;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    -- Arquivar squad que esta numa busca viva quebraria a partida que ainda
    -- vai nascer dela. Bloqueia em vez de deixar o estado inconsistente.
    if exists (
        select 1 from public.match_search_sessions
        where fc_squad_id = p_squad_id and status = 'SEARCHING'
    ) or exists (
        select 1 from public.match_search_queue where fc_squad_id = p_squad_id
    ) then
        raise exception 'squad is in use by an active search'
            using errcode = 'FQ034';
    end if;

    select fc_account_id, is_default into v_account_id, v_was_default
    from public.fc_squads where id = p_squad_id;

    update public.fc_squads
    set is_active = false, is_default = false
    where id = p_squad_id;

    -- Elenco nao pode ficar sem default enquanto houver squad ativo: promove
    -- o mais antigo, deterministicamente.
    if v_was_default then
        update public.fc_squads set is_default = true
        where id = (
            select id from public.fc_squads
            where fc_account_id = v_account_id and is_active
            order by created_at
            limit 1
        );
    end if;
end;
$$;

revoke execute on function public.archive_fc_squad(uuid) from public, anon;
grant execute on function public.archive_fc_squad(uuid) to authenticated;

-- Trocar de formacao NUNCA apaga jogador (item 33).
--
-- Remapeamento deterministico em quatro passadas, da correspondencia mais
-- forte para a mais fraca:
--   1. mesmo slot_code na formacao nova e a carta joga ali;
--   2. algum slot livre com a MESMA posicao em que ela estava;
--   3. slot livre elegivel mais proximo das coordenadas antigas;
--   4. slot livre mais proximo, mesmo fora de posicao.
--
-- A passada 4 existe porque toda formacao tem exatamente 11 titulares: com
-- 11 cartas e 11 vagas, sempre sobra lugar. Ela e o que garante que a troca
-- e lossless -- preferimos um jogador fora de posicao (visivel, o usuario
-- corrige) a um jogador sumindo em silencio. O banco nao e tocado.
create function public.set_fc_squad_formation(
    p_squad_id uuid,
    p_formation_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old text;
    v_card uuid[];
    v_oslot text[];
    v_opos text[];
    v_ox numeric[];
    v_oy numeric[];
    v_assigned text[];

    v_nslot text[];
    v_npos text[];
    v_nx numeric[];
    v_ny numeric[];
    v_taken boolean[];

    i integer;
    j integer;
    v_n integer;
    v_m integer;
    v_best integer;
    v_best_d numeric;
    v_d numeric;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if not exists (
        select 1 from public.fc_formations
        where code = p_formation_code and is_active
    ) then
        raise exception 'invalid formation' using errcode = 'FQ031';
    end if;

    select formation_code into v_old
    from public.fc_squads where id = p_squad_id;

    if v_old = p_formation_code then
        return public.get_fc_squad_builder(p_squad_id);
    end if;

    select
        array_agg(sl.player_card_id order by coalesce(fs.sort_order, 99)),
        array_agg(sl.slot_code order by coalesce(fs.sort_order, 99)),
        array_agg(coalesce(fs.position_code, c.primary_position)
                  order by coalesce(fs.sort_order, 99)),
        array_agg(coalesce(fs.x, 0.5) order by coalesce(fs.sort_order, 99)),
        array_agg(coalesce(fs.y, 0.5) order by coalesce(fs.sort_order, 99))
    into v_card, v_oslot, v_opos, v_ox, v_oy
    from public.fc_squad_slots as sl
    join public.fc_player_cards as c on c.id = sl.player_card_id
    left join public.fc_formation_slots as fs
        on fs.formation_code = v_old and fs.slot_code = sl.slot_code
    where sl.squad_id = p_squad_id and sl.slot_type = 'STARTING';

    select
        array_agg(fs.slot_code order by fs.sort_order),
        array_agg(fs.position_code order by fs.sort_order),
        array_agg(fs.x order by fs.sort_order),
        array_agg(fs.y order by fs.sort_order)
    into v_nslot, v_npos, v_nx, v_ny
    from public.fc_formation_slots as fs
    where fs.formation_code = p_formation_code;

    v_n := coalesce(array_length(v_card, 1), 0);
    v_m := coalesce(array_length(v_nslot, 1), 0);

    if v_n = 0 then
        update public.fc_squads
        set formation_code = p_formation_code where id = p_squad_id;
        return public.get_fc_squad_builder(p_squad_id);
    end if;

    v_taken := array_fill(false, array[v_m]);
    v_assigned := array_fill(null::text, array[v_n]);

    -- Passada 1
    for i in 1 .. v_n loop
        for j in 1 .. v_m loop
            if not v_taken[j]
               and v_nslot[j] = v_oslot[i]
               and public._fc_card_can_play(v_card[i], v_npos[j])
            then
                v_assigned[i] := v_nslot[j];
                v_taken[j] := true;
                exit;
            end if;
        end loop;
    end loop;

    -- Passada 2
    for i in 1 .. v_n loop
        if v_assigned[i] is null then
            for j in 1 .. v_m loop
                if not v_taken[j] and v_npos[j] = v_opos[i]
                   and public._fc_card_can_play(v_card[i], v_npos[j])
                then
                    v_assigned[i] := v_nslot[j];
                    v_taken[j] := true;
                    exit;
                end if;
            end loop;
        end if;
    end loop;

    -- Passada 3 e 4: mais proximo, primeiro exigindo elegibilidade e depois
    -- sem exigir.
    for i in 1 .. v_n loop
        if v_assigned[i] is null then
            v_best := null;
            v_best_d := null;
            for j in 1 .. v_m loop
                if not v_taken[j]
                   and public._fc_card_can_play(v_card[i], v_npos[j])
                then
                    v_d := (v_nx[j] - v_ox[i]) ^ 2 + (v_ny[j] - v_oy[i]) ^ 2;
                    if v_best_d is null or v_d < v_best_d then
                        v_best_d := v_d;
                        v_best := j;
                    end if;
                end if;
            end loop;

            if v_best is null then
                for j in 1 .. v_m loop
                    if not v_taken[j] then
                        v_d := (v_nx[j] - v_ox[i]) ^ 2 + (v_ny[j] - v_oy[i]) ^ 2;
                        if v_best_d is null or v_d < v_best_d then
                            v_best_d := v_d;
                            v_best := j;
                        end if;
                    end if;
                end loop;
            end if;

            if v_best is not null then
                v_assigned[i] := v_nslot[v_best];
                v_taken[v_best] := true;
            end if;
        end if;
    end loop;

    delete from public.fc_squad_slots
    where squad_id = p_squad_id and slot_type = 'STARTING';

    for i in 1 .. v_n loop
        if v_assigned[i] is not null then
            insert into public.fc_squad_slots
                (squad_id, slot_type, slot_code, player_card_id)
            values (p_squad_id, 'STARTING', v_assigned[i], v_card[i]);
        end if;
    end loop;

    update public.fc_squads
    set formation_code = p_formation_code where id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.set_fc_squad_formation(uuid, text)
    from public, anon;
grant execute on function public.set_fc_squad_formation(uuid, text)
    to authenticated;

-- Valida que o slot existe de verdade: titular tem de ser um slot_code da
-- formacao ATUAL do squad, banco tem de estar dentro do tamanho do banco.
-- O client nunca inventa slot (item 76).
create function public._fc_slot_position(
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

    if p_slot_type <> 'BENCH' then
        raise exception 'invalid slot type' using errcode = 'FQ032';
    end if;

    if p_slot_code !~ '^BENCH_[0-9]+$' then
        raise exception 'invalid bench slot' using errcode = 'FQ032';
    end if;

    v_index := substring(p_slot_code from 7)::integer;
    if v_index < 1 or v_index > public._fc_bench_size() then
        raise exception 'invalid bench slot' using errcode = 'FQ032';
    end if;

    -- Banco nao exige posicao: qualquer carta senta em qualquer lugar.
    return null;
end;
$$;

revoke execute on function public._fc_slot_position(uuid, text, text)
    from public, anon;

create function public.set_fc_squad_slot(
    p_squad_id uuid,
    p_slot_type text,
    p_slot_code text,
    p_player_card_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_pos text;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if not exists (
        select 1 from public.fc_player_cards where id = p_player_card_id
    ) then
        raise exception 'player card not found' using errcode = 'FQ032';
    end if;

    v_pos := public._fc_slot_position(p_squad_id, p_slot_type, p_slot_code);

    if v_pos is not null
       and not public._fc_card_can_play(p_player_card_id, v_pos)
    then
        raise exception 'card cannot play in this position'
            using errcode = 'FQ033';
    end if;

    -- A mesma carta nao pode ocupar dois slots: coloca-la num lugar novo a
    -- REMOVE do anterior, que e o que o usuario espera ao trazer alguem do
    -- banco para o time.
    delete from public.fc_squad_slots
    where squad_id = p_squad_id and player_card_id = p_player_card_id;

    insert into public.fc_squad_slots
        (squad_id, slot_type, slot_code, player_card_id)
    values (p_squad_id, p_slot_type, p_slot_code, p_player_card_id)
    on conflict (squad_id, slot_type, slot_code) do update
        set player_card_id = excluded.player_card_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.set_fc_squad_slot(uuid, text, text, uuid)
    from public, anon;
grant execute on function public.set_fc_squad_slot(uuid, text, text, uuid)
    to authenticated;

create function public.clear_fc_squad_slot(
    p_squad_id uuid,
    p_slot_type text,
    p_slot_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    delete from public.fc_squad_slots
    where squad_id = p_squad_id
      and slot_type = p_slot_type
      and slot_code = p_slot_code;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.clear_fc_squad_slot(uuid, text, text)
    from public, anon;
grant execute on function public.clear_fc_squad_slot(uuid, text, text)
    to authenticated;

-- Troca as cartas de dois slots. Slot vazio de um dos lados vira movimento
-- simples. Valida elegibilidade nos DOIS destinos antes de escrever nada.
create function public.swap_fc_squad_slots(
    p_squad_id uuid,
    p_from_type text,
    p_from_code text,
    p_to_type text,
    p_to_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_from_card uuid;
    v_to_card uuid;
    v_from_pos text;
    v_to_pos text;
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    v_from_pos := public._fc_slot_position(p_squad_id, p_from_type, p_from_code);
    v_to_pos := public._fc_slot_position(p_squad_id, p_to_type, p_to_code);

    select player_card_id into v_from_card from public.fc_squad_slots
    where squad_id = p_squad_id and slot_type = p_from_type
      and slot_code = p_from_code;

    select player_card_id into v_to_card from public.fc_squad_slots
    where squad_id = p_squad_id and slot_type = p_to_type
      and slot_code = p_to_code;

    if v_from_card is null and v_to_card is null then
        return public.get_fc_squad_builder(p_squad_id);
    end if;

    if v_from_card is not null and v_to_pos is not null
       and not public._fc_card_can_play(v_from_card, v_to_pos) then
        raise exception 'card cannot play in this position'
            using errcode = 'FQ033';
    end if;

    if v_to_card is not null and v_from_pos is not null
       and not public._fc_card_can_play(v_to_card, v_from_pos) then
        raise exception 'card cannot play in this position'
            using errcode = 'FQ033';
    end if;

    -- Apaga os dois antes de reinserir: o unique (squad_id, player_card_id)
    -- rejeitaria um update direto no meio da troca.
    delete from public.fc_squad_slots
    where squad_id = p_squad_id
      and ((slot_type = p_from_type and slot_code = p_from_code)
        or (slot_type = p_to_type and slot_code = p_to_code));

    if v_from_card is not null then
        insert into public.fc_squad_slots
            (squad_id, slot_type, slot_code, player_card_id)
        values (p_squad_id, p_to_type, p_to_code, v_from_card);
    end if;

    if v_to_card is not null then
        insert into public.fc_squad_slots
            (squad_id, slot_type, slot_code, player_card_id)
        values (p_squad_id, p_from_type, p_from_code, v_to_card);
    end if;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function
    public.swap_fc_squad_slots(uuid, text, text, text, text)
    from public, anon;
grant execute on function
    public.swap_fc_squad_slots(uuid, text, text, text, text)
    to authenticated;

create function public.set_fc_squad_manager(
    p_squad_id uuid,
    p_manager_id uuid,
    p_manager_league_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not public._owns_fc_squad(p_squad_id) then
        raise exception 'squad not found' using errcode = 'FQ029';
    end if;

    if p_manager_id is not null and not exists (
        select 1 from public.fc_managers where id = p_manager_id
    ) then
        raise exception 'manager not found' using errcode = 'FQ032';
    end if;

    if p_manager_league_id is not null and not exists (
        select 1 from public.fc_leagues where id = p_manager_league_id
    ) then
        raise exception 'league not found' using errcode = 'FQ032';
    end if;

    -- Tirar o tecnico tira a liga junto: liga sem tecnico nao significa nada.
    update public.fc_squads
    set manager_id = p_manager_id,
        manager_league_id = case
            when p_manager_id is null then null else p_manager_league_id
        end
    where id = p_squad_id;

    return public.get_fc_squad_builder(p_squad_id);
end;
$$;

revoke execute on function public.set_fc_squad_manager(uuid, uuid, uuid)
    from public, anon;
grant execute on function public.set_fc_squad_manager(uuid, uuid, uuid)
    to authenticated;
