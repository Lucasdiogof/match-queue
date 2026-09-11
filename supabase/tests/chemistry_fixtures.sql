-- Fixtures de quimica: congela o comportamento da regra com entradas
-- conhecidas e saidas esperadas.
--
-- Como rodar (mesmas credenciais do db push, sem Docker e sem psql):
--
--     npx supabase db query --linked -f supabase/tests/chemistry_fixtures.sql
--
-- Passou quando a ultima linha devolve 'ALL CHEMISTRY FIXTURES PASSED'.
-- Qualquer assercao que falha levanta excecao, a transacao aborta e o
-- comando sai com erro.
--
-- TUDO roda dentro de begin/rollback: nenhuma linha destes fixtures
-- sobrevive, inclusive as funcoes auxiliares criadas aqui.
--
-- Por que fixtures sinteticos alem da prova embutida na migration: producao
-- so tem dois elencos, que nao exercitam thresholds, capping nem as
-- variacoes de match do tecnico. Aqui as entradas sao escolhidas para
-- atravessar cada faixa da regra.

begin;

-- ---------------------------------------------------------------------
-- Helpers (somem no rollback)
-- ---------------------------------------------------------------------
create function pg_temp.assert_eq(p_actual anyelement, p_expected anyelement, p_label text)
returns void language plpgsql as $$
begin
    if p_actual is distinct from p_expected then
        raise exception 'FAIL [%]: esperado %, veio %', p_label, p_expected, p_actual;
    end if;
end;
$$;

-- Total de quimica de um lineup, pela regra unica.
create function pg_temp.total(p_slots jsonb, p_manager uuid default null, p_league uuid default null)
returns int language sql as $$
    select (public._fc_lineup_chemistry('TESTFORM', p_slots, p_manager, p_league) ->> 'total')::int;
$$;

-- ---------------------------------------------------------------------
-- Catalogo sintetico
-- ---------------------------------------------------------------------
insert into public.fc_formations (code, display_name, sort_order, is_active)
values ('TESTFORM', 'Fixture 4-4-2', 999, true);

insert into public.fc_formation_slots (formation_code, slot_code, position_code, x, y, sort_order)
values
    ('TESTFORM', 'GK',  'GK', 0.50, 0.05, 1),
    ('TESTFORM', 'S2',  'CB', 0.20, 0.25, 2),
    ('TESTFORM', 'S3',  'CB', 0.40, 0.25, 3),
    ('TESTFORM', 'S4',  'CB', 0.60, 0.25, 4),
    ('TESTFORM', 'S5',  'CB', 0.80, 0.25, 5),
    ('TESTFORM', 'S6',  'CM', 0.20, 0.55, 6),
    ('TESTFORM', 'S7',  'CM', 0.40, 0.55, 7),
    ('TESTFORM', 'S8',  'CM', 0.60, 0.55, 8),
    ('TESTFORM', 'S9',  'CM', 0.80, 0.55, 9),
    ('TESTFORM', 'S10', 'ST', 0.40, 0.85, 10),
    ('TESTFORM', 'S11', 'ST', 0.60, 0.85, 11);

insert into public.fc_nations (id, name)
values ('11111111-1111-1111-1111-111111111111', 'Fixturelandia');

insert into public.fc_leagues (id, name)
values ('22222222-2222-2222-2222-222222222222', 'Liga Fixture');

insert into public.fc_managers (id, name, nation_id)
values
    ('33333333-3333-3333-3333-333333333333', 'Tecnico Nacao', '11111111-1111-1111-1111-111111111111'),
    ('44444444-4444-4444-4444-444444444444', 'Tecnico Sem Match', null);

-- 10 jogadores de linha (CB/CM/ST) + 1 goleiro, todos elegiveis nos seus
-- slots. Clube/liga/nacao sao atribuidos por cenario logo abaixo.
insert into public.fc_player_cards
    (id, provider, player_name, rating, primary_position, alternative_positions, is_active)
select
    ('55555555-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
    'FIXTURE', 'Jogador ' || i, 80,
    case when i = 1 then 'GK' when i <= 5 then 'CB' when i <= 9 then 'CM' else 'ST' end,
    '{}'::text[], true
from generate_series(1, 11) as i;

-- Carta de atacante usada para provar que INELEGIVEL nao contribui.
insert into public.fc_player_cards
    (id, provider, player_name, rating, primary_position, alternative_positions, is_active)
values ('55555555-9999-9999-9999-999999999999', 'FIXTURE', 'Atacante Fora de Posicao',
        80, 'ST', '{}'::text[], true);

-- Atalho: ids das 11 cartas na ordem dos slots.
create temporary view fixture_cards as
select i,
       ('55555555-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid as id,
       (array['GK','S2','S3','S4','S5','S6','S7','S8','S9','S10','S11'])[i] as slot
from generate_series(1, 11) as i;

create function pg_temp.lineup_of(p_n int)
returns jsonb language sql as $$
    select coalesce(jsonb_agg(jsonb_build_object(
        'slot_code', slot, 'player_card_id', id
    )), '[]'::jsonb)
    from fixture_cards where i <= p_n;
$$;

-- Reseta clube/liga/nacao de todas as cartas do fixture.
create procedure pg_temp.reset_keys()
language sql as $$
    update public.fc_player_cards
    set club_name = 'Clube ' || player_name,
        league_name = 'Liga ' || player_name,
        nation_name = 'Nacao ' || player_name,
        club_id = null, league_id = null, nation_id = null
    where provider = 'FIXTURE';
$$;

-- Marca as N primeiras cartas com a mesma chave do tipo indicado.
create procedure pg_temp.share(p_kind text, p_n int)
language plpgsql as $$
begin
    if p_kind = 'club' then
        update public.fc_player_cards set club_name = 'Clube Comum'
        where id in (select id from fixture_cards where i <= p_n);
    elsif p_kind = 'league' then
        update public.fc_player_cards set league_name = 'Liga Comum'
        where id in (select id from fixture_cards where i <= p_n);
    else
        update public.fc_player_cards set nation_name = 'Nacao Comum'
        where id in (select id from fixture_cards where i <= p_n);
    end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 1. Lineup vazio e parcial
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
select pg_temp.assert_eq(pg_temp.total('[]'::jsonb), 0, 'lineup vazio');
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(1)), 0,
    'um jogador sozinho, nenhuma chave compartilhada');
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(5)), 0,
    'lineup parcial sem chave compartilhada');

-- ---------------------------------------------------------------------
-- 2. Thresholds de CLUBE: >=2 vale 1, >=4 vale 2, >=7 vale 3
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('club', 1);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 0, 'clube com 1: abaixo do threshold');

call pg_temp.reset_keys();
call pg_temp.share('club', 2);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 2, 'clube com 2: 1 ponto para cada um');

call pg_temp.reset_keys();
call pg_temp.share('club', 3);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 3, 'clube com 3: ainda 1 ponto cada');

call pg_temp.reset_keys();
call pg_temp.share('club', 4);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 8, 'clube com 4: 2 pontos cada');

call pg_temp.reset_keys();
call pg_temp.share('club', 7);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 21, 'clube com 7: 3 pontos cada');

-- ---------------------------------------------------------------------
-- 3. Thresholds de LIGA: >=3 vale 1, >=5 vale 2, >=8 vale 3
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('league', 2);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 0, 'liga com 2: abaixo do threshold');

call pg_temp.reset_keys();
call pg_temp.share('league', 3);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 3, 'liga com 3: 1 ponto cada');

call pg_temp.reset_keys();
call pg_temp.share('league', 5);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 10, 'liga com 5: 2 pontos cada');

call pg_temp.reset_keys();
call pg_temp.share('league', 8);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 24, 'liga com 8: 3 pontos cada');

-- ---------------------------------------------------------------------
-- 4. Thresholds de NACAO: >=2 vale 1, >=5 vale 2, >=8 vale 3
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('nation', 1);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 0, 'nacao com 1: abaixo do threshold');

call pg_temp.reset_keys();
call pg_temp.share('nation', 2);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 2, 'nacao com 2: 1 ponto cada');

call pg_temp.reset_keys();
call pg_temp.share('nation', 5);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 10, 'nacao com 5: 2 pontos cada');

call pg_temp.reset_keys();
call pg_temp.share('nation', 8);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 24, 'nacao com 8: 3 pontos cada');

-- ---------------------------------------------------------------------
-- 5. Acumulo entre eixos e capping individual em 3
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('club', 2);
call pg_temp.share('nation', 2);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 4,
    'clube 2 + nacao 2 nos mesmos dois: 1+1 para cada');

call pg_temp.reset_keys();
call pg_temp.share('club', 7);
call pg_temp.share('league', 8);
call pg_temp.share('nation', 8);
-- 7 primeiros: 3+3+3 = 9 bruto, capado em 3. O 8o: 0+3+3 = 6, capado em 3.
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 24,
    'capping individual: ninguem passa de 3');

-- ---------------------------------------------------------------------
-- 6. Quimica maxima: 11 iguais em tudo -> 3 cada -> 33
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('club', 11);
call pg_temp.share('league', 11);
call pg_temp.share('nation', 11);
select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 33, 'quimica maxima e 33');

-- ---------------------------------------------------------------------
-- 7. Tecnico
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
-- Sem chave compartilhada entre jogadores: qualquer ponto vem do tecnico.
update public.fc_player_cards
set nation_id = '11111111-1111-1111-1111-111111111111'
where id in (select id from fixture_cards where i <= 3);

select pg_temp.assert_eq(pg_temp.total(pg_temp.lineup_of(11)), 3,
    'nacao por ID tambem conta como chave compartilhada (3 jogadores -> 1 cada)');

select pg_temp.assert_eq(
    pg_temp.total(pg_temp.lineup_of(11), '33333333-3333-3333-3333-333333333333'),
    6, 'tecnico com match SO de nacao: +1 para os 3 da nacao dele');

select pg_temp.assert_eq(
    pg_temp.total(pg_temp.lineup_of(11), '44444444-4444-4444-4444-444444444444'),
    3, 'tecnico sem match nenhum: nao adiciona ponto');

call pg_temp.reset_keys();
update public.fc_player_cards
set league_id = '22222222-2222-2222-2222-222222222222'
where id in (select id from fixture_cards where i <= 3);
-- 3 na mesma liga -> 1 cada = 3. Tecnico com a liga aplicada -> +1 nos 3.
select pg_temp.assert_eq(
    pg_temp.total(pg_temp.lineup_of(11), '44444444-4444-4444-4444-444444444444',
                  '22222222-2222-2222-2222-222222222222'),
    6, 'tecnico com match SO de liga: +1 para os 3 da liga dele');

call pg_temp.reset_keys();
update public.fc_player_cards
set nation_id = '11111111-1111-1111-1111-111111111111',
    league_id = '22222222-2222-2222-2222-222222222222'
where id in (select id from fixture_cards where i <= 3);
-- nacao 3 (1 cada) + liga 3 (1 cada) = 2 cada = 6; tecnico casa nos dois
-- eixos mas o bonus e UM so -> +1 cada = 9.
select pg_temp.assert_eq(
    pg_temp.total(pg_temp.lineup_of(11), '33333333-3333-3333-3333-333333333333',
                  '22222222-2222-2222-2222-222222222222'),
    9, 'tecnico casando nacao E liga continua valendo 1 ponto, nao 2');

-- ---------------------------------------------------------------------
-- 8. Inelegivel nao pontua E nao entra no pool dos outros
--
-- Montagem escolhida para a diferenca ser visivel: 4 titulares elegiveis
-- compartilham a nacao, e o atacante escalado no gol tem a MESMA nacao.
-- Com 4 no pool cada um ganha 1 ponto (total 4). Se o inelegivel contasse,
-- o pool viraria 5, cada um ganharia 2, e o total seria 8. O numero separa
-- os dois comportamentos.
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
update public.fc_player_cards set nation_name = 'Nacao Comum'
where id in (select id from fixture_cards where i between 2 and 5);
update public.fc_player_cards set nation_name = 'Nacao Comum'
where id = '55555555-9999-9999-9999-999999999999';

select pg_temp.assert_eq(
    pg_temp.total(
        (select jsonb_agg(jsonb_build_object('slot_code', slot, 'player_card_id', id))
         from fixture_cards where i between 2 and 11)
        || jsonb_build_array(jsonb_build_object(
            'slot_code', 'GK',
            'player_card_id', '55555555-9999-9999-9999-999999999999'))
    ),
    4,
    'atacante no gol nao pontua nem infla a contagem dos elegiveis');

-- ---------------------------------------------------------------------
-- 9. PREVIEW == PERSISTIDO
--
-- Cria conta e elenco reais (rollback derruba tudo), grava o mesmo lineup e
-- compara o preview com a quimica do estado persistido.
-- ---------------------------------------------------------------------
call pg_temp.reset_keys();
call pg_temp.share('club', 4);
call pg_temp.share('league', 5);
call pg_temp.share('nation', 8);

insert into public.user_fc_accounts (id, user_id, name)
select '66666666-6666-6666-6666-666666666666', user_id, 'Conta Fixture'
from public.user_fc_accounts limit 1;

insert into public.fc_squads (id, fc_account_id, name, formation_code)
values ('77777777-7777-7777-7777-777777777777',
        '66666666-6666-6666-6666-666666666666', 'Elenco Fixture', 'TESTFORM');

insert into public.fc_squad_slots (squad_id, slot_type, slot_code, player_card_id)
select '77777777-7777-7777-7777-777777777777', 'STARTING', slot, id
from fixture_cards;

update public.fc_squads
set manager_id = '33333333-3333-3333-3333-333333333333',
    manager_league_id = '22222222-2222-2222-2222-222222222222'
where id = '77777777-7777-7777-7777-777777777777';

select pg_temp.assert_eq(
    public._fc_squad_chemistry('77777777-7777-7777-7777-777777777777'),
    public._fc_lineup_chemistry('TESTFORM', pg_temp.lineup_of(11),
        '33333333-3333-3333-3333-333333333333',
        '22222222-2222-2222-2222-222222222222'),
    'wrapper persistido devolve exatamente o mesmo jsonb do core');

-- Agora pela porta publica, com o usuario dono autenticado.
select set_config('request.jwt.claims',
    json_build_object('sub', (select user_id from public.user_fc_accounts
                              where id = '66666666-6666-6666-6666-666666666666'))::text,
    true);

select pg_temp.assert_eq(
    (public.preview_fc_squad_lineup(
        '77777777-7777-7777-7777-777777777777', 'TESTFORM', pg_temp.lineup_of(11),
        '33333333-3333-3333-3333-333333333333',
        '22222222-2222-2222-2222-222222222222') -> 'chemistry'),
    public._fc_squad_chemistry('77777777-7777-7777-7777-777777777777'),
    'PREVIEW == PERSISTIDO');

-- ---------------------------------------------------------------------
-- 10. Preview nao escreve nada
-- ---------------------------------------------------------------------
create temporary table before_preview as
select
    (select count(*) from public.fc_squad_slots
      where squad_id = '77777777-7777-7777-7777-777777777777') as slots,
    (select formation_code from public.fc_squads
      where id = '77777777-7777-7777-7777-777777777777') as formation,
    (select manager_id from public.fc_squads
      where id = '77777777-7777-7777-7777-777777777777') as manager,
    (select manager_league_id from public.fc_squads
      where id = '77777777-7777-7777-7777-777777777777') as league,
    (select updated_at from public.fc_squads
      where id = '77777777-7777-7777-7777-777777777777') as updated_at;

-- Preview com um lineup COMPLETAMENTE diferente do persistido.
select public.preview_fc_squad_lineup(
    '77777777-7777-7777-7777-777777777777', 'TESTFORM', pg_temp.lineup_of(3), null, null);

do $$
declare b record; a record;
begin
    select * into b from before_preview;
    select
        (select count(*) from public.fc_squad_slots
          where squad_id = '77777777-7777-7777-7777-777777777777') as slots,
        (select formation_code from public.fc_squads
          where id = '77777777-7777-7777-7777-777777777777') as formation,
        (select manager_id from public.fc_squads
          where id = '77777777-7777-7777-7777-777777777777') as manager,
        (select manager_league_id from public.fc_squads
          where id = '77777777-7777-7777-7777-777777777777') as league,
        (select updated_at from public.fc_squads
          where id = '77777777-7777-7777-7777-777777777777') as updated_at
    into a;
    if b is distinct from a then
        raise exception 'FAIL: preview alterou estado. antes=% depois=%', b, a;
    end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 11. Preview e save rejeitam as mesmas coisas
-- ---------------------------------------------------------------------
do $$
declare
    v_dup jsonb;
    v_bad_slot jsonb;
    v_ineligible jsonb;
    v_ok boolean;
begin
    select jsonb_build_array(
        jsonb_build_object('slot_code', 'S2', 'player_card_id',
            (select id from fixture_cards where i = 2)),
        jsonb_build_object('slot_code', 'S3', 'player_card_id',
            (select id from fixture_cards where i = 2))
    ) into v_dup;

    select jsonb_build_array(jsonb_build_object('slot_code', 'NAO_EXISTE',
        'player_card_id', (select id from fixture_cards where i = 2))) into v_bad_slot;

    select jsonb_build_array(jsonb_build_object('slot_code', 'GK',
        'player_card_id', '55555555-9999-9999-9999-999999999999')) into v_ineligible;

    -- Jogador duplicado
    v_ok := false;
    begin
        perform public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_dup);
    exception when sqlstate 'FQ051' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: preview aceitou jogador duplicado'; end if;

    v_ok := false;
    begin
        perform public.save_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_dup);
    exception when sqlstate 'FQ051' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: save aceitou jogador duplicado'; end if;

    -- Slot que nao existe na formacao
    v_ok := false;
    begin
        perform public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_bad_slot);
    exception when sqlstate 'FQ050' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: preview aceitou slot invalido'; end if;

    v_ok := false;
    begin
        perform public.save_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_bad_slot);
    exception when sqlstate 'FQ050' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: save aceitou slot invalido'; end if;

    -- Jogador inelegivel para o slot
    v_ok := false;
    begin
        perform public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_ineligible);
    exception when sqlstate 'FQ052' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: preview aceitou jogador inelegivel'; end if;

    v_ok := false;
    begin
        perform public.save_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', v_ineligible);
    exception when sqlstate 'FQ052' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: save aceitou jogador inelegivel'; end if;

    -- Formacao invalida
    v_ok := false;
    begin
        perform public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'NAO_EXISTE', '[]'::jsonb);
    exception when sqlstate 'FQ031' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: preview aceitou formacao invalida'; end if;

    -- Tecnico inexistente
    v_ok := false;
    begin
        perform public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
            'TESTFORM', '[]'::jsonb, '00000000-0000-0000-0000-0000000000ff');
    exception when sqlstate 'FQ032' then v_ok := true;
    end;
    if not v_ok then raise exception 'FAIL: preview aceitou tecnico inexistente'; end if;
end;
$$;

-- ---------------------------------------------------------------------
-- 12. Overall: exatamente o que o Dart precisa replicar
--
-- round(avg(rating)) sobre os titulares PREENCHIDOS. avg devolve numeric,
-- e round() em numeric arredonda meio para longe do zero -- igual ao
-- .round() do Dart para positivos. O caso .5 esta coberto abaixo porque e
-- justamente onde as duas linguagens poderiam divergir.
-- ---------------------------------------------------------------------
create function pg_temp.overall_of(p_n int)
returns int language sql as $$
    select (public.preview_fc_squad_lineup('77777777-7777-7777-7777-777777777777',
        'TESTFORM', pg_temp.lineup_of(p_n)) ->> 'overall')::int;
$$;

update public.fc_player_cards set rating = 80 where provider = 'FIXTURE';
select pg_temp.assert_eq(pg_temp.overall_of(1), 80, 'overall com 1 jogador');
select pg_temp.assert_eq(pg_temp.overall_of(5), 80, 'overall de lineup parcial');
select pg_temp.assert_eq(pg_temp.overall_of(11), 80, 'overall de 11 iguais');

-- Media inteira exata: 5x90 + 5x80 = 85
update public.fc_player_cards set rating = 90
where id in (select id from fixture_cards where i <= 5);
select pg_temp.assert_eq(pg_temp.overall_of(10), 85, 'overall com media inteira exata');

-- Media terminando em .5: 1x81 + 1x80 = 80.5 -> 81 (meio para cima)
update public.fc_player_cards set rating = 80 where provider = 'FIXTURE';
update public.fc_player_cards set rating = 81
where id in (select id from fixture_cards where i = 1);
select pg_temp.assert_eq(pg_temp.overall_of(2), 81, 'overall .5 arredonda para cima');

-- E o .5 no sentido inverso: 1x80 + 1x79 = 79.5 -> 80
update public.fc_player_cards set rating = 80 where provider = 'FIXTURE';
update public.fc_player_cards set rating = 79
where id in (select id from fixture_cards where i = 1);
select pg_temp.assert_eq(pg_temp.overall_of(2), 80, 'overall .5 inverso');

-- Heterogeneo: 5x81 + 6x80 = 885/11 = 80.4545 -> 80
update public.fc_player_cards set rating = 80 where provider = 'FIXTURE';
update public.fc_player_cards set rating = 81
where id in (select id from fixture_cards where i <= 5);
select pg_temp.assert_eq(pg_temp.overall_of(11), 80, 'overall heterogeneo arredonda para baixo');

rollback;

select 'ALL CHEMISTRY FIXTURES PASSED' as result;
