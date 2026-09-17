-- Testes de exclusao de CONTA (delete_my_account) e transferencia de posse
-- (transfer_team_ownership).
--
-- COMO RODAR
--   Cole este arquivo inteiro no SQL Editor do Supabase e execute. A saida
--   e TAP: linhas "ok N - ..." passam, "not ok N - ..." falham.
--   Alternativa: `supabase test db` (a CLI ja envolve cada arquivo numa
--   transacao, e o begin/rollback daqui continua valido).
--
-- NADA PERSISTE: tudo roda dentro de uma transacao que termina em
-- rollback -- inclusive a propria extensao pgtap, que e criada aqui em vez
-- de numa migration justamente pra nao deixar rastro em producao. Os
-- fixtures criam usuarios/times de mentira e somem junto.
--
-- POR QUE INSERT DIRETO E NAO AS RPCs: os cenarios de sucessao dependem da
-- ORDEM DE ENTRADA dos membros (joined_at). Entrar via convite carimbaria
-- now() em todos, e os tres membros ficariam com o mesmo instante -- sem
-- forma de testar "o mais antigo assume". team_members_protect_owner so
-- guarda UPDATE/DELETE, entao o insert continua passando pelas mesmas
-- regras que a producao usa.
--
-- O QUE delete_my_account() NAO FAZ: apagar auth.users. Isso e da Edge
-- Function delete-account (admin API), fora do alcance do pgTAP. Aqui se
-- testa exatamente o que a RPC promete: cancelar busca, anonimizar
-- historico e resolver os times antes de sair deles.

begin;

create extension if not exists pgtap;

-- pgtap pode estar instalada em public ou em extensions dependendo do
-- projeto; sem isto as funcoes de assercao podem nao resolver.
set local search_path = public, extensions, pg_temp;

-- Cada assercao vai pra uma tabela temporaria em vez de virar um result
-- set solto: o SQL Editor do Supabase so exibe o retorno da ULTIMA query,
-- entao sem isto as primeiras ficam invisiveis e um "not ok" passa
-- despercebido.
create temp table tap_out (line text);

insert into pg_temp.tap_out select plan(22);

-- ---------------------------------------------------------------------
-- Helpers de fixture
-- ---------------------------------------------------------------------

-- O trigger on_auth_user_created cria public.profiles sozinho a partir do
-- raw_user_meta_data -- por isso aqui so nasce o auth.users.
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
$fn$;

create function pg_temp.mk_team(p_id uuid, p_name text)
returns void
language sql
as $fn$
    insert into public.teams (id, name) values (p_id, p_name);
$fn$;

create function pg_temp.mk_member(
    p_team_id uuid,
    p_user_id uuid,
    p_role public.team_role,
    p_joined_at timestamptz
)
returns void
language sql
as $fn$
    insert into public.team_members (team_id, user_id, role, joined_at)
    values (p_team_id, p_user_id, p_role, p_joined_at);
$fn$;

-- auth.uid() le o sub do JWT; nos testes ele vem deste GUC de transacao.
create function pg_temp.act_as(p_user_id uuid)
returns void
language sql
as $fn$
    select set_config(
        'request.jwt.claims',
        json_build_object('sub', p_user_id::text, 'role', 'authenticated')::text,
        true
    );
$fn$;

-- ---------------------------------------------------------------------
-- CENARIO 1: usuario sozinho no time -> o time morre junto
-- ---------------------------------------------------------------------
select pg_temp.mk_user('11111111-1111-1111-1111-111111111111', 'solo');
select pg_temp.mk_team('11111111-1111-1111-1111-1111111111f1', 'Time Solo');
select pg_temp.mk_member(
    '11111111-1111-1111-1111-1111111111f1',
    '11111111-1111-1111-1111-111111111111',
    'OWNER',
    '2026-01-01'
);

select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.delete_my_account()$q$,
    'unico membro: exclusao da conta nao levanta erro'
);

insert into pg_temp.tap_out select is_empty(
    $q$select 1 from public.teams
      where id = '11111111-1111-1111-1111-1111111111f1'$q$,
    'unico membro: o time e excluido junto'
);

insert into pg_temp.tap_out select is_empty(
    $q$select 1 from public.team_members
      where user_id = '11111111-1111-1111-1111-111111111111'$q$,
    'unico membro: nao sobra participacao nenhuma'
);

-- ---------------------------------------------------------------------
-- CENARIO 2: membro comum (PLAYER) sai -- time e OWNER intactos
-- ---------------------------------------------------------------------
select pg_temp.mk_user('22222222-2222-2222-2222-222222222222', 'dono2');
select pg_temp.mk_user('22222222-2222-2222-2222-222222222223', 'player2');
select pg_temp.mk_team('22222222-2222-2222-2222-2222222222f1', 'Time Dois');
select pg_temp.mk_member(
    '22222222-2222-2222-2222-2222222222f1',
    '22222222-2222-2222-2222-222222222222',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '22222222-2222-2222-2222-2222222222f1',
    '22222222-2222-2222-2222-222222222223',
    'PLAYER',
    '2026-01-03'
);

select pg_temp.act_as('22222222-2222-2222-2222-222222222223');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.delete_my_account()$q$,
    'PLAYER: exclusao da propria conta nao levanta erro'
);

insert into pg_temp.tap_out select isnt_empty(
    $q$select 1 from public.teams
      where id = '22222222-2222-2222-2222-2222222222f1'$q$,
    'PLAYER sai: o time continua existindo'
);

insert into pg_temp.tap_out select results_eq(
    $q$select user_id from public.team_members
      where team_id = '22222222-2222-2222-2222-2222222222f1' and role = 'OWNER'$q$,
    $q$values ('22222222-2222-2222-2222-222222222222'::uuid)$q$,
    'PLAYER sai: o OWNER nao muda'
);

insert into pg_temp.tap_out select is_empty(
    $q$select 1 from public.team_members
      where team_id = '22222222-2222-2222-2222-2222222222f1'
        and user_id = '22222222-2222-2222-2222-222222222223'$q$,
    'PLAYER sai: a participacao dele e removida'
);

-- ---------------------------------------------------------------------
-- CENARIO 3: OWNER sai com outros no time -> mais antigo assume
-- ---------------------------------------------------------------------
select pg_temp.mk_user('33333333-3333-3333-3333-333333333331', 'dono3');
select pg_temp.mk_user('33333333-3333-3333-3333-333333333332', 'meio3');
select pg_temp.mk_user('33333333-3333-3333-3333-333333333333', 'novo3');
select pg_temp.mk_team('33333333-3333-3333-3333-3333333333f1', 'Time Tres');
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-333333333331',
    'OWNER',
    '2026-01-01'
);
-- Inserido FORA de ordem de proposito: se a sucessao usasse a ordem fisica
-- da tabela em vez de joined_at, este teste passaria por acidente.
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-333333333333',
    'PLAYER',
    '2026-01-08'
);
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-333333333332',
    'PLAYER',
    '2026-01-03'
);

select pg_temp.act_as('33333333-3333-3333-3333-333333333331');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.delete_my_account()$q$,
    'OWNER com outros: exclusao nao levanta erro'
);

insert into pg_temp.tap_out select isnt_empty(
    $q$select 1 from public.teams
      where id = '33333333-3333-3333-3333-3333333333f1'$q$,
    'OWNER com outros: o time NAO e excluido'
);

insert into pg_temp.tap_out select results_eq(
    $q$select user_id from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1' and role = 'OWNER'$q$,
    $q$values ('33333333-3333-3333-3333-333333333332'::uuid)$q$,
    'OWNER com outros: o membro mais antigo restante vira OWNER'
);

insert into pg_temp.tap_out select is_empty(
    $q$select 1 from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1'
        and user_id = '33333333-3333-3333-3333-333333333331'$q$,
    'OWNER com outros: o dono antigo sai do time'
);

insert into pg_temp.tap_out select results_eq(
    $q$select role::text from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1'
        and user_id = '33333333-3333-3333-3333-333333333333'$q$,
    $q$values ('PLAYER'::text)$q$,
    'OWNER com outros: quem entrou depois continua PLAYER'
);

-- ---------------------------------------------------------------------
-- CENARIO 4: empate de joined_at -> desempate deterministico por user_id
-- ---------------------------------------------------------------------
select pg_temp.mk_user('44444444-4444-4444-4444-444444444441', 'dono4');
select pg_temp.mk_user('44444444-4444-4444-4444-444444444442', 'empate4a');
select pg_temp.mk_user('44444444-4444-4444-4444-444444444443', 'empate4b');
select pg_temp.mk_team('44444444-4444-4444-4444-4444444444f1', 'Time Empate');
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-444444444441',
    'OWNER',
    '2026-01-01'
);
-- O maior user_id entra primeiro na tabela; so o criterio de id decide.
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-444444444443',
    'PLAYER',
    '2026-02-02 10:00:00+00'
);
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-444444444442',
    'PLAYER',
    '2026-02-02 10:00:00+00'
);

select pg_temp.act_as('44444444-4444-4444-4444-444444444441');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.delete_my_account()$q$,
    'empate: exclusao nao levanta erro'
);

insert into pg_temp.tap_out select results_eq(
    $q$select user_id from public.team_members
      where team_id = '44444444-4444-4444-4444-4444444444f1' and role = 'OWNER'$q$,
    $q$values ('44444444-4444-4444-4444-444444444442'::uuid)$q$,
    'empate de joined_at: ganha o menor user_id (nunca aleatorio)'
);

-- ---------------------------------------------------------------------
-- CENARIO 5: conta sem time nenhum
-- ---------------------------------------------------------------------
select pg_temp.mk_user('55555555-5555-5555-5555-555555555555', 'semtime');

select pg_temp.act_as('55555555-5555-5555-5555-555555555555');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.delete_my_account()$q$,
    'sem time: a conta e preparada pra exclusao normalmente'
);

-- ---------------------------------------------------------------------
-- CENARIO 6: seguranca -- sem sessao nao ha o que excluir
--
-- Com 1 login = 1 usuario nao existe mais "excluir a conta de outro": a
-- RPC nao recebe id nenhum, so olha auth.uid(). O que sobra pra provar e
-- que sem sessao ela recusa em vez de rodar com uid nulo.
-- ---------------------------------------------------------------------
select set_config('request.jwt.claims', null, true);
insert into pg_temp.tap_out select throws_ok(
    $q$select public.delete_my_account()$q$,
    'FQ003'::text,
    null::text,
    'seguranca: sem sessao a exclusao e recusada'
);

-- ---------------------------------------------------------------------
-- CENARIO 7 e 8: transferencia manual de posse
-- ---------------------------------------------------------------------
select pg_temp.mk_user('77777777-7777-7777-7777-777777777771', 'dono7');
select pg_temp.mk_user('77777777-7777-7777-7777-777777777772', 'alvo7');
select pg_temp.mk_team('77777777-7777-7777-7777-7777777777f1', 'Time Transfer');
select pg_temp.mk_member(
    '77777777-7777-7777-7777-7777777777f1',
    '77777777-7777-7777-7777-777777777771',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '77777777-7777-7777-7777-7777777777f1',
    '77777777-7777-7777-7777-777777777772',
    'PLAYER',
    '2026-01-05'
);

-- Quem nao e dono nao transfere -- checado ANTES da transferencia real,
-- senao o alvo ja seria dono e o teste passaria pelo motivo errado.
select pg_temp.act_as('77777777-7777-7777-7777-777777777772');
insert into pg_temp.tap_out select throws_ok(
    $q$select public.transfer_team_ownership(
        '77777777-7777-7777-7777-7777777777f1',
        '77777777-7777-7777-7777-777777777772'
    )$q$,
    'FQ012'::text,
    null::text,
    'transferencia: quem nao e OWNER recebe permission denied'
);

select pg_temp.act_as('77777777-7777-7777-7777-777777777771');
insert into pg_temp.tap_out select lives_ok(
    $q$select public.transfer_team_ownership(
        '77777777-7777-7777-7777-7777777777f1',
        '77777777-7777-7777-7777-777777777772'
    )$q$,
    'transferencia: o OWNER consegue passar a posse'
);

insert into pg_temp.tap_out select results_eq(
    $q$select user_id from public.team_members
      where team_id = '77777777-7777-7777-7777-7777777777f1' and role = 'OWNER'$q$,
    $q$values ('77777777-7777-7777-7777-777777777772'::uuid)$q$,
    'transferencia: o alvo vira OWNER'
);

insert into pg_temp.tap_out select results_eq(
    $q$select role::text from public.team_members
      where team_id = '77777777-7777-7777-7777-7777777777f1'
        and user_id = '77777777-7777-7777-7777-777777777771'$q$,
    $q$values ('PLAYER'::text)$q$,
    'transferencia: o dono antigo vira PLAYER e continua no time'
);

-- ---------------------------------------------------------------------
-- CENARIO 9: o trigger continua trancado pra escrita direta
--
-- E o ponto que separa "a regra esta no banco" de "a regra esta na UI":
-- as duas RPCs acima destrancam o trigger por um GUC de transacao, entao
-- vale provar que sem elas a porta continua fechada.
-- ---------------------------------------------------------------------
select pg_temp.mk_user('88888888-8888-8888-8888-888888888881', 'dono8');
select pg_temp.mk_user('88888888-8888-8888-8888-888888888882', 'esperto8');
select pg_temp.mk_team('88888888-8888-8888-8888-8888888888f1', 'Time Trigger');
select pg_temp.mk_member(
    '88888888-8888-8888-8888-8888888888f1',
    '88888888-8888-8888-8888-888888888881',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '88888888-8888-8888-8888-8888888888f1',
    '88888888-8888-8888-8888-888888888882',
    'PLAYER',
    '2026-01-05'
);

insert into pg_temp.tap_out select throws_ok(
    $q$update public.team_members set role = 'PLAYER'
      where team_id = '88888888-8888-8888-8888-8888888888f1'
        and user_id = '88888888-8888-8888-8888-888888888881'$q$,
    'FQ005'::text,
    null::text,
    'trigger: rebaixar o OWNER por escrita direta continua bloqueado'
);

insert into pg_temp.tap_out select throws_ok(
    $q$delete from public.team_members
      where team_id = '88888888-8888-8888-8888-8888888888f1'
        and user_id = '88888888-8888-8888-8888-888888888881'$q$,
    'FQ005'::text,
    null::text,
    'trigger: remover o OWNER por escrita direta continua bloqueado'
);

insert into pg_temp.tap_out select * from finish();

select line from pg_temp.tap_out;

rollback;
