-- Upload de logo do time falhava com "Algo deu errado no servidor".
--
-- uploadTeamLogo usa upsert: true, que o Storage executa como
-- INSERT ... ON CONFLICT DO UPDATE. O Postgres exige policy de SELECT na
-- tabela pra esse comando, mesmo com o bucket publico (bucket publico so
-- dispensa RLS na leitura pela URL, nao no SQL). A migration
-- 20261013101800 assumia que nenhum SELECT era necessario -- valia so pra
-- INSERT puro. Leitura ja e publica, entao liberar SELECT nao expoe nada.
drop policy if exists team_logos_select_public on storage.objects;

create policy team_logos_select_public
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'team-logos');
