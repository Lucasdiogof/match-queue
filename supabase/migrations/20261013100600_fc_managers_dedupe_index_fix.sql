-- A REST API do PostgREST resolve on_conflict=col1,col2,col3 batendo num
-- indice UNIQUE sobre essas colunas EXATAS -- um indice de expressao
-- (coalesce(nation_id::text, '')) nunca bate com esse formato, entao o
-- upsert em lote do importador nunca teria como usar aquele indice.
-- Trocado por colunas simples: todo candidato real tem nation_id resolvido
-- (fc27_managers_candidates.json so inclui quem bateu com public.fc_nations),
-- entao a unicidade sobre a coluna de verdade e suficiente -- NULL nunca
-- colide com outro NULL em Postgres, o que so importaria se um dia
-- importassemos um candidato sem nacao resolvida (hoje o importer pula
-- esse caso em vez de inventar).
drop index public.fc_managers_candidate_dedupe_idx;

create unique index fc_managers_candidate_dedupe_idx
    on public.fc_managers (provider, name_key, nation_id)
    where provider = 'FC27_UT_CANDIDATE';
