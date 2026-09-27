-- Regressao da ordem de lock do matchmaking (migration 20261021100000).
--
-- A correcao de 20261011110000 ja foi desfeita uma vez por um
-- "create or replace" posterior copiado de uma versao antiga. Este teste
-- falha se isso acontecer de novo: cancel/report precisam passar pela ordem
-- canonica (times ordenados -> usuario) e nao podem travar o usuario direto.
-- Tambem confere que o comportamento visivel (cancelar promove o proximo da
-- fila; iniciar partida cria game_matches) continua igual.
--
-- COMO RODAR
--   Cole o arquivo inteiro no SQL Editor ou rode
--   `npx.cmd supabase db query -f supabase/tests/database/matchmaking_lock_ordering_test.sql --linked`.
--   Saida TAP; tudo em begin/rollback, nada persiste.
--
-- Deadlock real depende de duas sessoes concorrentes e nao cabe num teste
-- de uma transacao so -- por isso a parte estrutural confere a ORDEM no
-- corpo das funcoes, que e exatamente o que regrediu.

begin;

create extension if not exists pgtap;
set local search_path = public, extensions, pg_temp;

create temp table tap_out (line text);

insert into pg_temp.tap_out select plan(12);

-- ---------------------------------------------------------------------
-- Estrutura: ordem dos locks
-- ---------------------------------------------------------------------

create function pg_temp.body(p_sig text)
returns text
language sql
as $fn$
    select pg_get_functiondef(p_sig::regprocedure);
$fn$;

insert into pg_temp.tap_out select ok(
    position('_lock_teams_matchmaking' in pg_temp.body('public._lock_user_search_for_update(uuid)'))
        between 1 and
    position('_lock_user_matchmaking' in pg_temp.body('public._lock_user_search_for_update(uuid)')) - 1,
    '_lock_user_search_for_update trava os times ANTES do usuario'
);

insert into pg_temp.tap_out select ok(
    pg_temp.body('public.cancel_match_search()') like '%_lock_user_search_for_update%',
    'cancel_match_search usa a ordem canonica'
);

insert into pg_temp.tap_out select ok(
    pg_temp.body('public.cancel_match_search()') not like '%_lock_user_matchmaking%'
    and pg_temp.body('public.cancel_match_search()') not like '%_lock_team_matchmaking(%',
    'cancel_match_search nao trava usuario/time por fora da ordem canonica'
);

insert into pg_temp.tap_out select ok(
    pg_temp.body('public.report_match_found_and_start_game()') like '%_lock_user_search_for_update%',
    'report_match_found_and_start_game usa a ordem canonica'
);

insert into pg_temp.tap_out select ok(
    pg_temp.body('public.report_match_found_and_start_game()') not like '%_lock_user_matchmaking%'
    and pg_temp.body('public.report_match_found_and_start_game()') not like '%_lock_team_matchmaking(%',
    'report_match_found_and_start_game nao trava usuario/time por fora da ordem canonica'
);

insert into pg_temp.tap_out select ok(
    position('_lock_team_matchmaking' in pg_temp.body('public.request_match_search(uuid,uuid,text)'))
        between 1 and
    position('_lock_user_matchmaking' in pg_temp.body('public.request_match_search(uuid,uuid,text)')) - 1,
    'request_match_search continua travando time antes do usuario'
);

-- ---------------------------------------------------------------------
-- Comportamento
-- ---------------------------------------------------------------------

create function pg_temp.mk_user(p_id uuid, p_name text)
returns void
language sql
as $fn$
    insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
    values (
        p_id,
        p_name || '@example.test',
        jsonb_build_object('display_name', p_name),
        now(),
        now()
    );
    update public.users set platforms = array['PS'] where id = p_id;
$fn$;

create function pg_temp.as_user(p_id uuid)
returns void
language sql
as $fn$
    select set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', p_id, 'role', 'authenticated')::text,
        true
    );
$fn$;

select pg_temp.mk_user('77777777-7777-7777-7777-777777777701', 'lock_a');
select pg_temp.mk_user('77777777-7777-7777-7777-777777777702', 'lock_b');

insert into public.teams (id, name)
values ('77777777-7777-7777-7777-7777777777f1', 'Lock Test');

insert into public.team_members (team_id, user_id, role)
values
    ('77777777-7777-7777-7777-7777777777f1', '77777777-7777-7777-7777-777777777701', 'OWNER'),
    ('77777777-7777-7777-7777-7777777777f1', '77777777-7777-7777-7777-777777777702', 'PLAYER');

-- A comeca a buscar (time livre), B entra na fila do mesmo (time, modo).
select pg_temp.as_user('77777777-7777-7777-7777-777777777701');
select public.request_match_search(
    '77777777-7777-7777-7777-7777777777f1', null, 'DIVISION_RIVALS'
);
select pg_temp.as_user('77777777-7777-7777-7777-777777777702');
select public.request_match_search(
    '77777777-7777-7777-7777-7777777777f1', null, 'DIVISION_RIVALS'
);

insert into pg_temp.tap_out select is(
    (select count(*)::int from public.match_search_queue
     where user_id = '77777777-7777-7777-7777-777777777702'),
    1,
    'fixture: B esta na fila enquanto A busca'
);

select pg_temp.as_user('77777777-7777-7777-7777-777777777701');
select public.cancel_match_search();

insert into pg_temp.tap_out select is(
    (select status from public.match_search_sessions
     where user_id = '77777777-7777-7777-7777-777777777701'
     order by started_at desc limit 1),
    'CANCELLED',
    'cancelar encerra a busca de A'
);

insert into pg_temp.tap_out select is(
    (select status from public.match_search_sessions
     where user_id = '77777777-7777-7777-7777-777777777702'
     order by started_at desc limit 1),
    'SEARCHING',
    'cancelar promove B, o proximo da fila'
);

insert into pg_temp.tap_out select throws_ok(
    $q$select public.cancel_match_search()$q$,
    'FQ015'::text,
    null::text,
    'cancelar sem busca ativa continua devolvendo FQ015'
);

select pg_temp.as_user('77777777-7777-7777-7777-777777777702');
select public.report_match_found_and_start_game();

insert into pg_temp.tap_out select is(
    (select status from public.match_search_sessions
     where user_id = '77777777-7777-7777-7777-777777777702'
     order by started_at desc limit 1),
    'MATCH_FOUND',
    'iniciar partida encerra a busca de B'
);

insert into pg_temp.tap_out select is(
    (select count(*)::int from public.game_matches
     where user_id = '77777777-7777-7777-7777-777777777702' and status = 'IN_MATCH'),
    1,
    'iniciar partida cria a partida IN_MATCH de B'
);

insert into pg_temp.tap_out select * from finish();

select line from pg_temp.tap_out;

rollback;
