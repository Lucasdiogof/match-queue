-- Checkup geral encontrou dois padroes de duplicata no catalogo, nenhum
-- ligado a Conta/usuario -- ambos sobras de sincronizacoes anteriores do
-- catalogo (fc_players/fc_player_cards/fc_clubs/fc_managers), nao dado de
-- ninguem.
--
-- fc_clubs: 31 pares com o MESMO nome na MESMA liga (diferente do caso
-- valido "mesmo nome em ligas diferentes" que o importador ja trata como
-- clubes distintos). Em todo par, uma das duas linhas e uma orfa vazia:
-- provider_club_id nulo e zero fc_players/fc_player_cards apontando pra
-- ela -- nunca precisou reatribuir nada, so apagar a orfa. Verificado
-- antes: todas as 31 linhas "reais" (com provider_club_id) tem jogadores e
-- cartas de verdade; todas as 31 orfas tem zero.
delete from public.fc_clubs as c
where c.provider_club_id is null
  and not exists (select 1 from public.fc_players where club_id = c.id)
  and not exists (select 1 from public.fc_player_cards where club_id = c.id)
  and exists (
    select 1 from public.fc_clubs as c2
    where c2.id <> c.id
      and lower(c2.name) = lower(c.name)
      and c2.league_id is not distinct from c.league_id
      and c2.provider_club_id is not null
  );

-- fc_managers: 2 pares (Luka Elsner, Mitja Mörec), sem provider_manager_id
-- em NENHUM dos dois lados e zero fc_squads apontando pra qualquer um --
-- mantem so a linha de id menor de cada par (escolha arbitraria, tanto faz
-- qual sobrevive ja que nenhuma esta em uso).
delete from public.fc_managers as m
where m.provider_manager_id is null
  and not exists (select 1 from public.fc_squads where manager_id = m.id)
  and m.id in (
    select id from (
      select id, row_number() over (partition by lower(name) order by id) as rn
      from public.fc_managers
      where lower(name) in (
          select lower(name) from public.fc_managers
          group by lower(name) having count(*) > 1
      )
    ) as ranked
    where rn > 1
  );

-- Funcoes de diagnostico temporarias do checkup: nunca deveriam sobreviver
-- no schema definitivo.
drop function if exists public._data_checkup();
drop function if exists public._data_checkup_dupe_usage();
