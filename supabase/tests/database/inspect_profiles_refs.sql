-- =====================================================================
-- INSPECAO: tudo que depende de public.profiles hoje, no banco REAL.
--
-- So LE. Nao altera nada.
--
-- Serve pra montar a migration de rename profiles -> users sem adivinhar:
-- `alter table ... rename` conserta FK, indice, policy e trigger sozinho,
-- mas NAO reescreve corpo de funcao plpgsql -- quem diz `public.profiles`
-- continua dizendo, e so estoura em runtime. O bloco 1 e a lista de
-- funcoes que precisam ser recriadas na mao.
-- =====================================================================

-- 1. FUNCOES cujo corpo cita profiles (as que precisam ser reescritas) ---
select
    1 as bloco,
    'funcao' as tipo,
    p.oid::regprocedure::text as objeto,
    (
        select count(*)
        from regexp_matches(p.prosrc, 'public\.profiles', 'g')
    )::text || ' ocorrencia(s) de public.profiles' as detalhe
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and regexp_replace(p.prosrc, '--.*', '', 'gn') ~ '\mprofiles\M'

union all

-- 2. Funcoes fora do schema public que citam profiles (triggers de auth) --
select
    2,
    'funcao (outro schema)',
    n.nspname || '.' || p.oid::regprocedure::text,
    'cita profiles'
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('public', 'pg_catalog', 'information_schema')
  and regexp_replace(p.prosrc, '--.*', '', 'gn') ~ '\mprofiles\M'

union all

-- 3. FKs que apontam para profiles (o rename ajusta, mas o NOME da
--    constraint continua dizendo "profiles") -----------------------------
select
    3,
    'foreign key',
    c.conrelid::regclass::text || '.' || c.conname,
    'referencia ' || c.confrelid::regclass::text
from pg_constraint c
where c.contype = 'f'
  and c.confrelid = 'public.profiles'::regclass

union all

-- 4. Constraints da propria profiles (nomes carregam o prefixo antigo) ---
select
    4,
    'constraint propria',
    c.conname,
    case c.contype
        when 'p' then 'primary key'
        when 'u' then 'unique'
        when 'c' then 'check'
        when 'f' then 'foreign key'
        else c.contype::text
    end
from pg_constraint c
where c.conrelid = 'public.profiles'::regclass

union all

-- 5. Indices da propria profiles ----------------------------------------
select 5, 'indice', indexname, 'em public.profiles'
from pg_indexes
where schemaname = 'public' and tablename = 'profiles'

union all

-- 6. Policies NA profiles ------------------------------------------------
select
    6,
    'policy (em profiles)',
    polname,
    case polcmd
        when 'r' then 'select' when 'a' then 'insert'
        when 'w' then 'update' when 'd' then 'delete'
        else 'all'
    end
from pg_policy
where polrelid = 'public.profiles'::regclass

union all

-- 7. Policies de OUTRAS tabelas que mencionam profiles na expressao ------
select
    7,
    'policy (em outra tabela)',
    c.relname || ' :: ' || pol.polname,
    'expressao cita profiles'
from pg_policy pol
join pg_class c on c.oid = pol.polrelid
where pol.polrelid <> 'public.profiles'::regclass
  and (
      coalesce(pg_get_expr(pol.polqual, pol.polrelid), '') ~ '\mprofiles\M'
      or coalesce(pg_get_expr(pol.polwithcheck, pol.polrelid), '') ~ '\mprofiles\M'
  )

union all

-- 8. Triggers na profiles ------------------------------------------------
select 8, 'trigger', tgname, 'em public.profiles'
from pg_trigger
where tgrelid = 'public.profiles'::regclass and not tgisinternal

union all

-- 9. Views / matviews que leem profiles ----------------------------------
select
    9,
    'view',
    n.nspname || '.' || c.relname,
    case c.relkind when 'm' then 'materialized' else 'view' end
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where c.relkind in ('v', 'm')
  and pg_get_viewdef(c.oid) ~ '\mprofiles\M'

union all

-- 10. Publicacoes de Realtime que incluem profiles ----------------------
select 10, 'realtime', pubname, 'publica public.profiles'
from pg_publication_tables
where schemaname = 'public' and tablename = 'profiles'

order by bloco, objeto;
