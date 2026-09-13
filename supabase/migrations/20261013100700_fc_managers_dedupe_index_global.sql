-- PostgREST monta ON CONFLICT (col1, col2, col3) a partir de
-- on_conflict=col1,col2,col3 -- nunca inclui uma clausula WHERE, entao
-- nunca consegue casar com um indice UNIQUE parcial (Postgres exige que o
-- alvo do ON CONFLICT bata exatamente com a definicao do indice, predicado
-- incluido). Descoberto ao vivo rodando o importer: 42P10 "there is no
-- unique or exclusion constraint matching the ON CONFLICT specification".
--
-- Trocado por um indice sem WHERE, valido pra tabela inteira. Seguro porque
-- provider ja participa da chave: LOCAL e FC27_UT_CANDIDATE nunca colidem
-- entre si (auditado antes desta migration -- nao havia nenhuma colisao de
-- (provider, name_key, nation_id) na tabela).
drop index public.fc_managers_candidate_dedupe_idx;

create unique index fc_managers_candidate_dedupe_idx
    on public.fc_managers (provider, name_key, nation_id);
