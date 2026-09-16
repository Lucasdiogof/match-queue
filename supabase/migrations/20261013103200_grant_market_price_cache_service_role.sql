-- market_price_cache foi criada so com RLS habilitada e revoke de
-- anon/authenticated -- sem grant nenhum pra service_role, que e quem de
-- fato le/escreve (fetch-market-price-futbin). service_role tem BYPASSRLS,
-- mas isso so pula a checagem de POLICY -- o grant de tabela em si e uma
-- camada separada do Postgres e continua exigido. Sem isto, toda leitura/
-- escrita do cache falhava com "permission denied", e a function tratava
-- (sem querer) todo acesso como cache-miss, gastando credito do Parse.bot
-- em toda chamada em vez de so a cada 30min.
grant select, insert, update on table public.market_price_cache to service_role;
