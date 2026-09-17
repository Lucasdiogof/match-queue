-- =====================================================================
-- DUMP: definicao completa de tudo que precisa ser recriado apos o
-- rename public.profiles -> public.users.
--
-- So LE (pg_get_functiondef / pg_get_indexdef / pg_get_constraintdef /
-- pg_get_triggerdef / pg_get_expr). Nao altera nada.
--
-- Um unico result set (UNION ALL) de proposito: o SQL Editor do Supabase
-- so devolve o resultado do ultimo statement quando sao varios `select`
-- separados por `;` -- foi isso que cortou os blocos 1-5 da primeira
-- tentativa. Rode este arquivo inteiro de uma vez.
-- =====================================================================

with tudo as (

    -- 1. Corpo completo das 22 funcoes que citam public.profiles --------
    select
        1 as bloco,
        p.oid::regprocedure::text as objeto,
        pg_get_functiondef(p.oid) as definicao
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and regexp_replace(p.prosrc, '--.*', '', 'gn') ~ '\mprofiles\M'

    union all

    -- 2. Definicao das constraints proprias de profiles (check/pk/fk) ---
    select
        2,
        c.conname,
        pg_get_constraintdef(c.oid)
    from pg_constraint c
    where c.conrelid = 'public.profiles'::regclass

    union all

    -- 3. Definicao dos indices proprios de profiles ----------------------
    select 3, indexname, indexdef
    from pg_indexes
    where schemaname = 'public' and tablename = 'profiles'

    union all

    -- 4. Definicao das policies em profiles (roles, cmd, using, with check)
    select
        4,
        pol.polname,
        'CREATE POLICY ' || pol.polname || ' ON public.profiles AS ' ||
        case pol.polpermissive when true then 'PERMISSIVE' else 'RESTRICTIVE' end ||
        ' FOR ' ||
        case pol.polcmd
            when 'r' then 'SELECT' when 'a' then 'INSERT'
            when 'w' then 'UPDATE' when 'd' then 'DELETE' else 'ALL'
        end ||
        ' TO ' || (
            select string_agg(quote_ident(rolname), ', ')
            from unnest(pol.polroles) r join pg_roles on pg_roles.oid = r
        ) ||
        coalesce(' USING (' || pg_get_expr(pol.polqual, pol.polrelid) || ')', '') ||
        coalesce(' WITH CHECK (' || pg_get_expr(pol.polwithcheck, pol.polrelid) || ')', '')
    from pg_policy pol
    where pol.polrelid = 'public.profiles'::regclass

    union all

    -- 5. Definicao do trigger proprio de profiles -------------------------
    select 5, tgname, pg_get_triggerdef(oid)
    from pg_trigger
    where tgrelid = 'public.profiles'::regclass and not tgisinternal

    union all

    -- 6. FKs de outras tabelas que apontam pra profiles (documentacao;
    --    o RENAME resolve o vinculo sozinho) ------------------------------
    select
        6,
        c.conrelid::regclass::text || '.' || c.conname,
        pg_get_constraintdef(c.oid)
    from pg_constraint c
    where c.contype = 'f'
      and c.confrelid = 'public.profiles'::regclass

)
select * from tudo
order by bloco, objeto;
