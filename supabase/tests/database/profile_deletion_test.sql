-- Testes de exclusao de Perfil (archive_fc_account) e transferencia de
-- posse (transfer_team_ownership).
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
-- forma de testar "o mais antigo assume". team_members_sync_user_id
-- preenche user_id a partir de fc_account_id mesmo no insert direto, e
-- team_members_protect_owner so guarda UPDATE/DELETE, entao o insert
-- continua passando pelas mesmas regras que a producao usa.

begin;

create extension if not exists pgtap;

-- pgtap pode estar instalada em public ou em extensions dependendo do
-- projeto; sem isto as funcoes de assercao podem nao resolver.
set local search_path = public, extensions, pg_temp;

-- Cada assercao vai pra uma tabela temporaria em vez de virar um result
-- set solto: o SQL Editor do Supabase so exibe o retorno da ULTIMA query,
-- entao sem isto as 22 primeiras ficam invisiveis e um "not ok" passa
-- despercebido.
create temp table tap_out (line text);

insert into pg_temp.tap_out select plan(23);

-- ---------------------------------------------------------------------
-- Helpers de fixture
-- ---------------------------------------------------------------------

-- O trigger on_auth_user_created cria public.profiles sozinho a partir do
-- raw_user_meta_data -- por isso aqui so nasce o auth.users.
create function pg_temp.mk_user(p_id uuid, p_name text)
returns void
language sql
as $$
    insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
    values (
        p_id,
        p_name || '@example.test',
        jsonb_build_object('display_name', p_name),
        now(),
        now()
    );
$$;

create function pg_temp.mk_profile(p_id uuid, p_user_id uuid, p_name text)
returns void
language sql
as $$
    insert into public.user_fc_accounts (id, user_id, name, is_active)
    values (p_id, p_user_id, p_name, true);
$$;

create function pg_temp.mk_team(p_id uuid, p_name text)
returns void
language sql
as $$
    insert into public.teams (id, name) values (p_id, p_name);
$$;

create function pg_temp.mk_member(
    p_team_id uuid,
    p_profile_id uuid,
    p_role public.team_role,
    p_joined_at timestamptz
)
returns void
language sql
as $$
    insert into public.team_members (team_id, fc_account_id, role, joined_at)
    values (p_team_id, p_profile_id, p_role, p_joined_at);
$$;

-- auth.uid() le o sub do JWT; nos testes ele vem deste GUC de transacao.
create function pg_temp.act_as(p_user_id uuid)
returns void
language sql
as $$
    select set_config(
        'request.jwt.claims',
        json_build_object('sub', p_user_id::text, 'role', 'authenticated')::text,
        true
    );
$$;

-- ---------------------------------------------------------------------
-- CENARIO 1: Perfil sozinho no time -> o time morre junto
-- ---------------------------------------------------------------------
select pg_temp.mk_user('11111111-1111-1111-1111-111111111111', 'solo');
select pg_temp.mk_profile(
    '11111111-1111-1111-1111-1111111111a1',
    '11111111-1111-1111-1111-111111111111',
    'Solo'
);
select pg_temp.mk_team('11111111-1111-1111-1111-1111111111f1', 'Time Solo');
select pg_temp.mk_member(
    '11111111-1111-1111-1111-1111111111f1',
    '11111111-1111-1111-1111-1111111111a1',
    'OWNER',
    '2026-01-01'
);

select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
insert into pg_temp.tap_out select lives_ok(
    $$select public.archive_fc_account('11111111-1111-1111-1111-1111111111a1')$$,
    'unico membro: exclusao do Perfil nao levanta erro'
);

insert into pg_temp.tap_out select is_empty(
    $$select 1 from public.teams
      where id = '11111111-1111-1111-1111-1111111111f1'$$,
    'unico membro: o time e excluido junto'
);

insert into pg_temp.tap_out select results_eq(
    $$select is_active from public.user_fc_accounts
      where id = '11111111-1111-1111-1111-1111111111a1'$$,
    $$values (false)$$,
    'unico membro: o Perfil fica arquivado'
);

-- ---------------------------------------------------------------------
-- CENARIO 2: Perfil comum (PLAYER) sai -- time e OWNER intactos
-- ---------------------------------------------------------------------
select pg_temp.mk_user('22222222-2222-2222-2222-222222222222', 'dono2');
select pg_temp.mk_user('22222222-2222-2222-2222-222222222223', 'player2');
select pg_temp.mk_profile(
    '22222222-2222-2222-2222-2222222222a1',
    '22222222-2222-2222-2222-222222222222',
    'Dono'
);
select pg_temp.mk_profile(
    '22222222-2222-2222-2222-2222222222a2',
    '22222222-2222-2222-2222-222222222223',
    'Player'
);
select pg_temp.mk_team('22222222-2222-2222-2222-2222222222f1', 'Time Dois');
select pg_temp.mk_member(
    '22222222-2222-2222-2222-2222222222f1',
    '22222222-2222-2222-2222-2222222222a1',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '22222222-2222-2222-2222-2222222222f1',
    '22222222-2222-2222-2222-2222222222a2',
    'PLAYER',
    '2026-01-03'
);

select pg_temp.act_as('22222222-2222-2222-2222-222222222223');
insert into pg_temp.tap_out select lives_ok(
    $$select public.archive_fc_account('22222222-2222-2222-2222-2222222222a2')$$,
    'PLAYER: exclusao do proprio Perfil nao levanta erro'
);

insert into pg_temp.tap_out select isnt_empty(
    $$select 1 from public.teams
      where id = '22222222-2222-2222-2222-2222222222f1'$$,
    'PLAYER sai: o time continua existindo'
);

insert into pg_temp.tap_out select results_eq(
    $$select fc_account_id from public.team_members
      where team_id = '22222222-2222-2222-2222-2222222222f1' and role = 'OWNER'$$,
    $$values ('22222222-2222-2222-2222-2222222222a1'::uuid)$$,
    'PLAYER sai: o OWNER nao muda'
);

insert into pg_temp.tap_out select is_empty(
    $$select 1 from public.team_members
      where team_id = '22222222-2222-2222-2222-2222222222f1'
        and fc_account_id = '22222222-2222-2222-2222-2222222222a2'$$,
    'PLAYER sai: a participacao dele e removida'
);

-- ---------------------------------------------------------------------
-- CENARIO 3: OWNER sai com outros no time -> mais antigo assume
-- ---------------------------------------------------------------------
select pg_temp.mk_user('33333333-3333-3333-3333-333333333331', 'dono3');
select pg_temp.mk_user('33333333-3333-3333-3333-333333333332', 'meio3');
select pg_temp.mk_user('33333333-3333-3333-3333-333333333333', 'novo3');
select pg_temp.mk_profile(
    '33333333-3333-3333-3333-3333333333a1',
    '33333333-3333-3333-3333-333333333331',
    'Dono'
);
select pg_temp.mk_profile(
    '33333333-3333-3333-3333-3333333333a2',
    '33333333-3333-3333-3333-333333333332',
    'Meio'
);
select pg_temp.mk_profile(
    '33333333-3333-3333-3333-3333333333a3',
    '33333333-3333-3333-3333-333333333333',
    'Novo'
);
select pg_temp.mk_team('33333333-3333-3333-3333-3333333333f1', 'Time Tres');
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-3333333333a1',
    'OWNER',
    '2026-01-01'
);
-- Inserido FORA de ordem de proposito: se a sucessao usasse a ordem fisica
-- da tabela em vez de joined_at, este teste passaria por acidente.
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-3333333333a3',
    'PLAYER',
    '2026-01-08'
);
select pg_temp.mk_member(
    '33333333-3333-3333-3333-3333333333f1',
    '33333333-3333-3333-3333-3333333333a2',
    'PLAYER',
    '2026-01-03'
);

select pg_temp.act_as('33333333-3333-3333-3333-333333333331');
insert into pg_temp.tap_out select lives_ok(
    $$select public.archive_fc_account('33333333-3333-3333-3333-3333333333a1')$$,
    'OWNER com outros: exclusao nao levanta erro'
);

insert into pg_temp.tap_out select isnt_empty(
    $$select 1 from public.teams
      where id = '33333333-3333-3333-3333-3333333333f1'$$,
    'OWNER com outros: o time NAO e excluido'
);

insert into pg_temp.tap_out select results_eq(
    $$select fc_account_id from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1' and role = 'OWNER'$$,
    $$values ('33333333-3333-3333-3333-3333333333a2'::uuid)$$,
    'OWNER com outros: o membro mais antigo restante vira OWNER'
);

insert into pg_temp.tap_out select is_empty(
    $$select 1 from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1'
        and fc_account_id = '33333333-3333-3333-3333-3333333333a1'$$,
    'OWNER com outros: o dono antigo sai do time'
);

insert into pg_temp.tap_out select results_eq(
    $$select role::text from public.team_members
      where team_id = '33333333-3333-3333-3333-3333333333f1'
        and fc_account_id = '33333333-3333-3333-3333-3333333333a3'$$,
    $$values ('PLAYER'::text)$$,
    'OWNER com outros: quem entrou depois continua PLAYER'
);

-- ---------------------------------------------------------------------
-- CENARIO 4: empate de joined_at -> desempate deterministico por id
-- ---------------------------------------------------------------------
select pg_temp.mk_user('44444444-4444-4444-4444-444444444441', 'dono4');
select pg_temp.mk_user('44444444-4444-4444-4444-444444444442', 'empate4a');
select pg_temp.mk_user('44444444-4444-4444-4444-444444444443', 'empate4b');
select pg_temp.mk_profile(
    '44444444-4444-4444-4444-4444444444a0',
    '44444444-4444-4444-4444-444444444441',
    'Dono'
);
select pg_temp.mk_profile(
    '44444444-4444-4444-4444-4444444444a1',
    '44444444-4444-4444-4444-444444444442',
    'Empate A'
);
select pg_temp.mk_profile(
    '44444444-4444-4444-4444-4444444444a2',
    '44444444-4444-4444-4444-444444444443',
    'Empate B'
);
select pg_temp.mk_team('44444444-4444-4444-4444-4444444444f1', 'Time Empate');
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-4444444444a0',
    'OWNER',
    '2026-01-01'
);
-- O mais alto entra primeiro na tabela; so o criterio de id decide.
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-4444444444a2',
    'PLAYER',
    '2026-02-02 10:00:00+00'
);
select pg_temp.mk_member(
    '44444444-4444-4444-4444-4444444444f1',
    '44444444-4444-4444-4444-4444444444a1',
    'PLAYER',
    '2026-02-02 10:00:00+00'
);

select pg_temp.act_as('44444444-4444-4444-4444-444444444441');
insert into pg_temp.tap_out select lives_ok(
    $$select public.archive_fc_account('44444444-4444-4444-4444-4444444444a0')$$,
    'empate: exclusao nao levanta erro'
);

insert into pg_temp.tap_out select results_eq(
    $$select fc_account_id from public.team_members
      where team_id = '44444444-4444-4444-4444-4444444444f1' and role = 'OWNER'$$,
    $$values ('44444444-4444-4444-4444-4444444444a1'::uuid)$$,
    'empate de joined_at: ganha o menor fc_account_id (nunca aleatorio)'
);

-- ---------------------------------------------------------------------
-- CENARIO 5: Perfil sem time nenhum
-- ---------------------------------------------------------------------
select pg_temp.mk_user('55555555-5555-5555-5555-555555555555', 'semtime');
select pg_temp.mk_profile(
    '55555555-5555-5555-5555-5555555555a1',
    '55555555-5555-5555-5555-555555555555',
    'Sem Time'
);

select pg_temp.act_as('55555555-5555-5555-5555-555555555555');
insert into pg_temp.tap_out select lives_ok(
    $$select public.archive_fc_account('55555555-5555-5555-5555-5555555555a1')$$,
    'sem time: o Perfil e excluido normalmente'
);

-- ---------------------------------------------------------------------
-- CENARIO 6: seguranca -- nao da pra excluir Perfil de outra Conta
-- ---------------------------------------------------------------------
select pg_temp.mk_user('66666666-6666-6666-6666-666666666661', 'dono6');
select pg_temp.mk_user('66666666-6666-6666-6666-666666666662', 'intruso6');
select pg_temp.mk_profile(
    '66666666-6666-6666-6666-6666666666a1',
    '66666666-6666-6666-6666-666666666661',
    'Alheio'
);

select pg_temp.act_as('66666666-6666-6666-6666-666666666662');
insert into pg_temp.tap_out select throws_ok(
    $$select public.archive_fc_account('66666666-6666-6666-6666-6666666666a1')$$,
    'FQ025'::text,
    null::text,
    'seguranca: excluir Perfil de outra Conta e recusado'
);

insert into pg_temp.tap_out select results_eq(
    $$select is_active from public.user_fc_accounts
      where id = '66666666-6666-6666-6666-6666666666a1'$$,
    $$values (true)$$,
    'seguranca: o Perfil alheio continua ativo'
);

-- ---------------------------------------------------------------------
-- CENARIO 7 e 8: transferencia manual de posse
-- ---------------------------------------------------------------------
select pg_temp.mk_user('77777777-7777-7777-7777-777777777771', 'dono7');
select pg_temp.mk_user('77777777-7777-7777-7777-777777777772', 'alvo7');
select pg_temp.mk_profile(
    '77777777-7777-7777-7777-7777777777a1',
    '77777777-7777-7777-7777-777777777771',
    'Dono'
);
select pg_temp.mk_profile(
    '77777777-7777-7777-7777-7777777777a2',
    '77777777-7777-7777-7777-777777777772',
    'Alvo'
);
select pg_temp.mk_team('77777777-7777-7777-7777-7777777777f1', 'Time Transfer');
select pg_temp.mk_member(
    '77777777-7777-7777-7777-7777777777f1',
    '77777777-7777-7777-7777-7777777777a1',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '77777777-7777-7777-7777-7777777777f1',
    '77777777-7777-7777-7777-7777777777a2',
    'PLAYER',
    '2026-01-05'
);

-- Quem nao e dono nao transfere -- checado ANTES da transferencia real,
-- senao o alvo ja seria dono e o teste passaria pelo motivo errado.
select pg_temp.act_as('77777777-7777-7777-7777-777777777772');
insert into pg_temp.tap_out select throws_ok(
    $$select public.transfer_team_ownership(
        '77777777-7777-7777-7777-7777777777f1',
        '77777777-7777-7777-7777-7777777777a2'
    )$$,
    'FQ012'::text,
    null::text,
    'transferencia: quem nao e OWNER recebe permission denied'
);

select pg_temp.act_as('77777777-7777-7777-7777-777777777771');
insert into pg_temp.tap_out select lives_ok(
    $$select public.transfer_team_ownership(
        '77777777-7777-7777-7777-7777777777f1',
        '77777777-7777-7777-7777-7777777777a2'
    )$$,
    'transferencia: o OWNER consegue passar a posse'
);

insert into pg_temp.tap_out select results_eq(
    $$select fc_account_id from public.team_members
      where team_id = '77777777-7777-7777-7777-7777777777f1' and role = 'OWNER'$$,
    $$values ('77777777-7777-7777-7777-7777777777a2'::uuid)$$,
    'transferencia: o alvo vira OWNER'
);

insert into pg_temp.tap_out select results_eq(
    $$select role::text from public.team_members
      where team_id = '77777777-7777-7777-7777-7777777777f1'
        and fc_account_id = '77777777-7777-7777-7777-7777777777a1'$$,
    $$values ('PLAYER'::text)$$,
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
select pg_temp.mk_profile(
    '88888888-8888-8888-8888-8888888888a1',
    '88888888-8888-8888-8888-888888888881',
    'Dono'
);
select pg_temp.mk_profile(
    '88888888-8888-8888-8888-8888888888a2',
    '88888888-8888-8888-8888-888888888882',
    'Esperto'
);
select pg_temp.mk_team('88888888-8888-8888-8888-8888888888f1', 'Time Trigger');
select pg_temp.mk_member(
    '88888888-8888-8888-8888-8888888888f1',
    '88888888-8888-8888-8888-8888888888a1',
    'OWNER',
    '2026-01-01'
);
select pg_temp.mk_member(
    '88888888-8888-8888-8888-8888888888f1',
    '88888888-8888-8888-8888-8888888888a2',
    'PLAYER',
    '2026-01-05'
);

insert into pg_temp.tap_out select throws_ok(
    $$update public.team_members set role = 'PLAYER'
      where team_id = '88888888-8888-8888-8888-8888888888f1'
        and fc_account_id = '88888888-8888-8888-8888-8888888888a1'$$,
    'FQ005'::text,
    null::text,
    'trigger: rebaixar o OWNER por escrita direta continua bloqueado'
);

insert into pg_temp.tap_out select throws_ok(
    $$delete from public.team_members
      where team_id = '88888888-8888-8888-8888-8888888888f1'
        and fc_account_id = '88888888-8888-8888-8888-8888888888a1'$$,
    'FQ005'::text,
    null::text,
    'trigger: remover o OWNER por escrita direta continua bloqueado'
);

insert into pg_temp.tap_out select * from finish();

select line from pg_temp.tap_out;

rollback;
