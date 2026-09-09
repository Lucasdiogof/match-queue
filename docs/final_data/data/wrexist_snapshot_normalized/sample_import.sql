begin;

-- leagues (upsert-by-name, mesma logica de upsertByName no importer)
insert into fc_leagues (provider, name)
select 'WREXIST_EA_FC27_SNAPSHOT', v.name
from (values
  ('1A Pro League'),
  ('Barclays WSL'),
  ('Bundesliga'),
  ('CSL'),
  ('EFL Championship'),
  ('EFL League One'),
  ('EFL League Two'),
  ('Eliteserien'),
  ('Eredivisie'),
  ('GPFBL'),
  ('ISL'),
  ('K League 1'),
  ('Libertadores'),
  ('Liga F Moeve'),
  ('Liga Portugal'),
  ('Ligue 1 McDonald''s'),
  ('NWSL'),
  ('Premier League'),
  ('ROSHN Saudi League'),
  ('Scottish Prem'),
  ('Serie A Enilive'),
  ('Serie BKT'),
  ('Trendyol Süper Lig'),
  ('Ö. Bundesliga'),
  ('Česká Liga')
) as v(name)
where not exists (select 1 from fc_leagues l where l.name = v.name);

-- nations (upsert-by-name)
insert into fc_nations (provider, name)
select 'WREXIST_EA_FC27_SNAPSHOT', v.name
from (values
  ('Austria'),
  ('China PR'),
  ('Denmark'),
  ('Ecuador'),
  ('England'),
  ('France'),
  ('Georgia'),
  ('Germany'),
  ('Ghana'),
  ('Iceland'),
  ('India'),
  ('Italy'),
  ('Ivory Coast'),
  ('Madagascar'),
  ('Morocco'),
  ('Netherlands'),
  ('Nigeria'),
  ('Norway'),
  ('Paraguay'),
  ('Poland'),
  ('Senegal'),
  ('Serbia'),
  ('South Korea'),
  ('USA'),
  ('Wales')
) as v(name)
where not exists (select 1 from fc_nations n where n.name = v.name);

-- clubs (upsert-by-name, league_id resolvido por nome)
insert into fc_clubs (provider, name, league_id)
select 'WREXIST_EA_FC27_SNAPSHOT', v.name, l.id
from (values
  ('AJ Auxerre', 'Ligue 1 McDonald''s'),
  ('Al Fateh', 'ROSHN Saudi League'),
  ('Arouca', 'Liga Portugal'),
  ('Badalona Women', 'Liga F Moeve'),
  ('Birmingham City', 'EFL Championship'),
  ('Brighton', 'Barclays WSL'),
  ('Bristol Rovers', 'EFL League Two'),
  ('Changchun Yatai', 'CSL'),
  ('Club Brugge', '1A Pro League'),
  ('Dundee United', 'Scottish Prem'),
  ('Exeter City', 'EFL League One'),
  ('FC Alverca', 'Liga Portugal'),
  ('FC Anyang', 'K League 1'),
  ('FC Augsburg', 'Bundesliga'),
  ('Fiorentina', 'Serie A Enilive'),
  ('Frankfurt', 'Bundesliga'),
  ('Gillingham', 'EFL League Two'),
  ('Juventus', 'Serie A Enilive'),
  ('Kocaelispor', 'Trendyol Süper Lig'),
  ('Leeds United', 'Premier League'),
  ('Leverkusen', 'Bundesliga'),
  ('Madrid CFF', 'Liga F Moeve'),
  ('NorthEast United', 'ISL'),
  ('OL', 'Ligue 1 McDonald''s'),
  ('Portland Thorns', 'NWSL'),
  ('SC Freiburg', 'Bundesliga'),
  ('SV Oberbank Ried', 'Ö. Bundesliga'),
  ('SV Werder Bremen', 'Bundesliga'),
  ('SV Werder Bremen', 'GPFBL'),
  ('Slavia Praha', 'Česká Liga'),
  ('Standard Liège', '1A Pro League'),
  ('Tianjin JMT FC', 'CSL'),
  ('Torino', 'Serie A Enilive')
) as v(name, league_name)
left join fc_leagues l on l.name = v.league_name
where not exists (select 1 from fc_clubs c where c.name = v.name);

-- fc_players (upsert por provider, game_version, provider_player_id)
insert into fc_players (
  provider, provider_player_id, game_version, name, common_name,
  nation_id, club_id, league_id, primary_position, alternative_positions,
  image_url, height_cm, preferred_foot, weak_foot, skill_moves,
  is_active, last_synced_at
)
select
  'WREXIST_EA_FC27_SNAPSHOT', v.provider_player_id, 'FC27', v.name, v.common_name,
  (select id from fc_nations where name = v.nation_name),
  (select id from fc_clubs where name = v.club_name),
  (select id from fc_leagues where name = v.league_name),
  v.primary_position, v.alt_positions,
  null, v.height_cm, nullif(v.preferred_foot, ''), v.weak_foot, v.skill_moves,
  true, now()
from (values
  ('19541', 'Glenn Morris', NULL, 'England', 'Gillingham', 'EFL League Two', 'GK', '{}'::text[], 183, 'RIGHT', 3, 1),
  ('71427', 'Reilyn Turner', NULL, 'USA', 'Portland Thorns', 'NWSL', 'ST', '{}'::text[], 175, 'RIGHT', 3, 2),
  ('72970', 'Dan Ellison', NULL, 'England', 'Bristol Rovers', 'EFL League Two', 'CB', '{}'::text[], 185, 'RIGHT', 3, 2),
  ('74107', 'Stanley Skipper', NULL, 'England', 'Gillingham', 'EFL League Two', 'CM', '{CAM}'::text[], 181, 'LEFT', 3, 2),
  ('75535', 'Aymen Sliti', NULL, 'Netherlands', NULL, 'Eredivisie', 'LW', '{RW,LM}'::text[], 175, 'LEFT', 3, 3),
  ('77127', 'Mick Schmetgens', NULL, 'Germany', 'SV Werder Bremen', 'Bundesliga', 'CB', '{}'::text[], 190, 'RIGHT', 2, 2),
  ('78786', 'Felix Wimmer', NULL, 'Austria', 'SV Oberbank Ried', 'Ö. Bundesliga', 'GK', '{}'::text[], 183, 'LEFT', 1, 1),
  ('80232', 'George Birch', NULL, 'England', 'Exeter City', 'EFL League One', 'CAM', '{CM}'::text[], 162, 'RIGHT', 3, 3),
  ('193331', 'Karl Darlow', NULL, 'Wales', 'Leeds United', 'Premier League', 'GK', '{}'::text[], 190, 'RIGHT', 2, 1),
  ('203368', 'Eirik Ulland Andersen', NULL, 'Norway', NULL, 'Eliteserien', 'LW', '{CM,RW,LM}'::text[], 182, 'RIGHT', 2, 3),
  ('209846', 'Christian Günter', NULL, 'Germany', 'SC Freiburg', 'Bundesliga', 'LB', '{LM}'::text[], 184, 'LEFT', 2, 3),
  ('214525', 'David Richards', NULL, 'Wales', 'Dundee United', 'Scottish Prem', 'GK', '{}'::text[], 186, 'RIGHT', 2, 1),
  ('220782', 'Marco Ilaimaharitra', NULL, 'Madagascar', 'Standard Liège', '1A Pro League', 'CDM', '{CM}'::text[], 177, 'RIGHT', 3, 3),
  ('224302', 'Mateusz Wieteska', NULL, 'Poland', 'Kocaelispor', 'Trendyol Süper Lig', 'CB', '{}'::text[], 187, 'RIGHT', 3, 2),
  ('227255', 'Fran Kirby', NULL, 'England', 'Brighton', 'Barclays WSL', 'CAM', '{RW,CM}'::text[], 157, 'RIGHT', 4, 4),
  ('230144', 'Assane Dioussé', NULL, 'Senegal', 'AJ Auxerre', 'Ligue 1 McDonald''s', 'CDM', '{CM,CB}'::text[], 175, 'LEFT', 3, 3),
  ('233373', 'Stéphane Diarra', NULL, 'Ivory Coast', 'FC Alverca', 'Liga Portugal', 'RM', '{LM,RW}'::text[], 173, 'LEFT', 2, 4),
  ('235890', 'Marwane Saadane', NULL, 'Morocco', 'Al Fateh', 'ROSHN Saudi League', 'CB', '{}'::text[], 188, 'RIGHT', 3, 2),
  ('238235', 'Hugo Vetlesen', NULL, 'Norway', 'Club Brugge', '1A Pro League', 'CDM', '{RW,RM}'::text[], 174, 'RIGHT', 4, 3),
  ('240679', 'Teun Koopmeiners', NULL, 'Netherlands', 'Juventus', 'Serie A Enilive', 'CAM', '{CM}'::text[], 183, 'LEFT', 2, 3),
  ('242635', 'Igoh Ogbu', NULL, 'Nigeria', 'Slavia Praha', 'Česká Liga', 'CB', '{}'::text[], 187, 'RIGHT', 2, 2),
  ('244464', 'Eryc Castillo', NULL, 'Ecuador', NULL, 'Libertadores', 'LM', '{LW,RM}'::text[], 175, 'RIGHT', 3, 3),
  ('246594', 'Han-Noah Massengo', NULL, 'France', 'FC Augsburg', 'Bundesliga', 'CDM', '{CM}'::text[], 175, 'RIGHT', 3, 3),
  ('248486', 'Lee Joon Suk', 'Lee Joon Suk', 'South Korea', NULL, 'K League 1', 'LW', '{RW,LM}'::text[], 180, 'RIGHT', 5, 3),
  ('252181', 'Huang Jiahui', 'Huang Jiahui', 'China PR', 'Tianjin JMT FC', 'CSL', 'CDM', '{CB,CM}'::text[], 185, 'RIGHT', 3, 2),
  ('254475', 'Sumit Rathi', NULL, 'India', 'NorthEast United', 'ISL', 'CB', '{LB,LM}'::text[], 176, 'LEFT', 3, 2),
  ('256658', 'Jessic Ngankam', NULL, 'Germany', 'Frankfurt', 'Bundesliga', 'ST', '{}'::text[], 184, 'RIGHT', 4, 3),
  ('258687', 'Boris Popović', NULL, 'Serbia', 'Arouca', 'Liga Portugal', 'CB', '{}'::text[], 189, 'RIGHT', 2, 2),
  ('260436', 'Syb van Ottele', NULL, 'Netherlands', NULL, 'Eredivisie', 'CB', '{CDM}'::text[], 185, 'RIGHT', 3, 2),
  ('262335', 'Elayis Tavşan', NULL, 'Netherlands', NULL, 'Serie BKT', 'RW', '{RM,CAM}'::text[], 183, 'LEFT', 3, 3),
  ('263847', 'Wang Yu', 'Wang Yu', 'China PR', 'Changchun Yatai', 'CSL', 'CDM', '{CM}'::text[], 178, 'RIGHT', 3, 2),
  ('265116', 'Lina Hausicke', NULL, 'Germany', 'SV Werder Bremen', 'GPFBL', 'CM', '{}'::text[], 176, 'RIGHT', 3, 3),
  ('266775', 'Park Jong Hyun', 'Park Jong Hyun', 'South Korea', 'FC Anyang', 'K League 1', 'CB', '{CDM}'::text[], 185, 'RIGHT', 3, 2),
  ('268763', 'Ernest Nuamah', NULL, 'Ghana', 'OL', 'Ligue 1 McDonald''s', 'RM', '{RW}'::text[], 178, 'LEFT', 3, 4),
  ('270578', 'Willum Þór Willumsson', NULL, 'Iceland', 'Birmingham City', 'EFL Championship', 'CAM', '{RM,CM}'::text[], 193, 'LEFT', 3, 3),
  ('272046', 'Jessica Martínez', NULL, 'Paraguay', 'Badalona Women', 'Liga F Moeve', 'ST', '{LW,LM}'::text[], 160, 'RIGHT', 3, 3),
  ('273651', 'Jarell Quansah', NULL, 'England', 'Leverkusen', 'Bundesliga', 'CB', '{}'::text[], 190, 'RIGHT', 3, 2),
  ('275325', 'Tommaso Martinelli', NULL, 'Italy', 'Fiorentina', 'Serie A Enilive', 'GK', '{}'::text[], 196, 'RIGHT', 3, 1),
  ('276771', 'Malou Marcetto', NULL, 'Denmark', 'Madrid CFF', 'Liga F Moeve', 'CM', '{CDM,CAM}'::text[], 178, 'RIGHT', 3, 3),
  ('278013', 'Saba Sazonov', NULL, 'Georgia', 'Torino', 'Serie A Enilive', 'CB', '{}'::text[], 194, 'RIGHT', 3, 2)
) as v(
  provider_player_id, name, common_name, nation_name, club_name, league_name,
  primary_position, alt_positions, height_cm, preferred_foot, weak_foot, skill_moves
)
on conflict (provider, game_version, provider_player_id) where provider_player_id is not null
do update set
  name = excluded.name,
  common_name = excluded.common_name,
  nation_id = excluded.nation_id,
  club_id = excluded.club_id,
  league_id = excluded.league_id,
  primary_position = excluded.primary_position,
  alternative_positions = excluded.alternative_positions,
  height_cm = excluded.height_cm,
  preferred_foot = excluded.preferred_foot,
  weak_foot = excluded.weak_foot,
  skill_moves = excluded.skill_moves,
  is_active = true,
  last_synced_at = now(),
  updated_at = now();

-- fc_player_cards (upsert por provider, provider_card_id)
insert into fc_player_cards (
  provider_card_id, provider, fc_player_id, player_name, common_name, rating,
  primary_position, alternative_positions,
  pace, shooting, passing, dribbling, defending, physical,
  gk_diving, gk_handling, gk_kicking, gk_reflexes, gk_speed, gk_positioning,
  skill_moves, weak_foot, playstyles, playstyles_plus,
  height_cm, preferred_foot, club_name, league_name, nation_name,
  card_type, source_url, club_id, league_id, nation_id,
  game_version, is_active, last_synced_at
)
select
  v.provider_card_id, 'WREXIST_EA_FC27_SNAPSHOT',
  (select id from fc_players where provider = 'WREXIST_EA_FC27_SNAPSHOT' and game_version = 'FC27' and provider_player_id = v.provider_player_id),
  v.player_name, v.common_name, v.rating, v.primary_position, v.alt_positions,
  v.pace, v.shooting, v.passing, v.dribbling, v.defending, v.physical,
  v.gk_diving, v.gk_handling, v.gk_kicking, v.gk_reflexes, v.gk_speed, v.gk_positioning,
  v.skill_moves, v.weak_foot, v.playstyles, v.playstyles_plus,
  v.height_cm, nullif(v.preferred_foot, ''), v.club_name, v.league_name, v.nation_name,
  v.card_type, v.source_url,
  (select id from fc_clubs where name = v.club_name),
  (select id from fc_leagues where name = v.league_name),
  (select id from fc_nations where name = v.nation_name),
  'FC27', true, now()
from (values
  ('19541:BASE', '19541', 'Glenn Morris', NULL, 61, 'GK', '{}'::text[], NULL, NULL, NULL, NULL, NULL, NULL, 60, 59, 57, 62, NULL, 63, 1, 3, '{Footwork,Cross Claimer}'::text[], '{}'::text[], 183, 'RIGHT', 'Gillingham', 'EFL League Two', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=19541'),
  ('71427:BASE', '71427', 'Reilyn Turner', NULL, 68, 'ST', '{}'::text[], 69, 66, 55, 68, 43, 64, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Precision Header}'::text[], '{}'::text[], 175, 'RIGHT', 'Portland Thorns', 'NWSL', 'USA', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=71427'),
  ('72970:BASE', '72970', 'Dan Ellison', NULL, 53, 'CB', '{}'::text[], 61, 27, 41, 44, 51, 59, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 185, 'RIGHT', 'Bristol Rovers', 'EFL League Two', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=72970'),
  ('74107:BASE', '74107', 'Stanley Skipper', NULL, 50, 'CM', '{CAM}'::text[], 66, 43, 50, 54, 40, 53, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 181, 'LEFT', 'Gillingham', 'EFL League Two', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=74107'),
  ('75535:BASE', '75535', 'Aymen Sliti', NULL, 64, 'LW', '{RW,LM}'::text[], 78, 57, 57, 68, 27, 46, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{}'::text[], '{}'::text[], 175, 'LEFT', NULL, 'Eredivisie', 'Netherlands', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=75535'),
  ('77127:BASE', '77127', 'Mick Schmetgens', NULL, 56, 'CB', '{}'::text[], 54, 33, 35, 36, 57, 58, NULL, NULL, NULL, NULL, NULL, NULL, 2, 2, '{}'::text[], '{}'::text[], 190, 'RIGHT', 'SV Werder Bremen', 'Bundesliga', 'Germany', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=77127'),
  ('78786:BASE', '78786', 'Felix Wimmer', NULL, 60, 'GK', '{}'::text[], NULL, NULL, NULL, NULL, NULL, NULL, 58, 57, 61, 61, NULL, 62, 1, 1, '{}'::text[], '{}'::text[], 183, 'LEFT', 'SV Oberbank Ried', 'Ö. Bundesliga', 'Austria', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=78786'),
  ('80232:BASE', '80232', 'George Birch', NULL, 52, 'CAM', '{CM}'::text[], 72, 45, 49, 56, 38, 38, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{}'::text[], '{}'::text[], 162, 'RIGHT', 'Exeter City', 'EFL League One', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=80232'),
  ('193331:BASE', '193331', 'Karl Darlow', NULL, 72, 'GK', '{}'::text[], NULL, NULL, NULL, NULL, NULL, NULL, 73, 70, 66, 75, NULL, 72, 1, 2, '{Far Throw}'::text[], '{}'::text[], 190, 'RIGHT', 'Leeds United', 'Premier League', 'Wales', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=193331'),
  ('203368:BASE', '203368', 'Eirik Ulland Andersen', NULL, 65, 'LW', '{CM,RW,LM}'::text[], 60, 66, 66, 65, 34, 53, NULL, NULL, NULL, NULL, NULL, NULL, 3, 2, '{Dead Ball}'::text[], '{}'::text[], 182, 'RIGHT', NULL, 'Eliteserien', 'Norway', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=203368'),
  ('209846:BASE', '209846', 'Christian Günter', NULL, 77, 'LB', '{LM}'::text[], 83, 60, 69, 71, 73, 82, NULL, NULL, NULL, NULL, NULL, NULL, 3, 2, '{Whipped Pass,Slide Tackle,Rapid,Relentless}'::text[], '{}'::text[], 184, 'LEFT', 'SC Freiburg', 'Bundesliga', 'Germany', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=209846'),
  ('214525:BASE', '214525', 'David Richards', NULL, 58, 'GK', '{}'::text[], NULL, NULL, NULL, NULL, NULL, NULL, 57, 57, 56, 60, NULL, 55, 1, 2, '{}'::text[], '{}'::text[], 186, 'RIGHT', 'Dundee United', 'Scottish Prem', 'Wales', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=214525'),
  ('220782:BASE', '220782', 'Marco Ilaimaharitra', NULL, 71, 'CDM', '{CM}'::text[], 54, 62, 67, 67, 70, 74, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{}'::text[], '{}'::text[], 177, 'RIGHT', 'Standard Liège', '1A Pro League', 'Madagascar', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=220782'),
  ('224302:BASE', '224302', 'Mateusz Wieteska', NULL, 72, 'CB', '{}'::text[], 57, 38, 51, 61, 72, 72, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Block}'::text[], '{}'::text[], 187, 'RIGHT', 'Kocaelispor', 'Trendyol Süper Lig', 'Poland', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=224302'),
  ('227255:BASE', '227255', 'Fran Kirby', NULL, 83, 'CAM', '{RW,CM}'::text[], 84, 82, 77, 86, 42, 60, NULL, NULL, NULL, NULL, NULL, NULL, 4, 4, '{Finesse Shot,Technical}'::text[], '{}'::text[], 157, 'RIGHT', 'Brighton', 'Barclays WSL', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=227255'),
  ('230144:BASE', '230144', 'Assane Dioussé', NULL, 69, 'CDM', '{CM,CB}'::text[], 57, 47, 64, 72, 66, 64, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{}'::text[], '{}'::text[], 175, 'LEFT', 'AJ Auxerre', 'Ligue 1 McDonald''s', 'Senegal', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=230144'),
  ('233373:BASE', '233373', 'Stéphane Diarra', NULL, 68, 'RM', '{LM,RW}'::text[], 76, 58, 64, 72, 41, 45, NULL, NULL, NULL, NULL, NULL, NULL, 4, 2, '{Technical}'::text[], '{}'::text[], 173, 'LEFT', 'FC Alverca', 'Liga Portugal', 'Ivory Coast', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=233373'),
  ('235890:BASE', '235890', 'Marwane Saadane', NULL, 72, 'CB', '{}'::text[], 54, 51, 61, 62, 70, 85, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Long Ball Pass,Jockey,Intercept,Anticipate,Aerial Fortress}'::text[], '{}'::text[], 188, 'RIGHT', 'Al Fateh', 'ROSHN Saudi League', 'Morocco', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=235890'),
  ('238235:BASE', '238235', 'Hugo Vetlesen', NULL, 72, 'CDM', '{RW,RM}'::text[], 81, 68, 70, 77, 67, 72, NULL, NULL, NULL, NULL, NULL, NULL, 3, 4, '{}'::text[], '{}'::text[], 174, 'RIGHT', 'Club Brugge', '1A Pro League', 'Norway', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=238235'),
  ('240679:BASE', '240679', 'Teun Koopmeiners', NULL, 81, 'CAM', '{CM}'::text[], 70, 79, 83, 78, 75, 75, NULL, NULL, NULL, NULL, NULL, NULL, 3, 2, '{Dead Ball}'::text[], '{}'::text[], 183, 'LEFT', 'Juventus', 'Serie A Enilive', 'Netherlands', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=240679'),
  ('242635:BASE', '242635', 'Igoh Ogbu', NULL, 75, 'CB', '{}'::text[], 76, 39, 55, 60, 73, 82, NULL, NULL, NULL, NULL, NULL, NULL, 2, 2, '{Bruiser}'::text[], '{}'::text[], 187, 'RIGHT', 'Slavia Praha', 'Česká Liga', 'Nigeria', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=242635'),
  ('244464:BASE', '244464', 'Eryc Castillo', NULL, 69, 'LM', '{LW,RM}'::text[], 85, 61, 58, 71, 33, 79, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Rapid}'::text[], '{}'::text[], 175, 'RIGHT', NULL, 'Libertadores', 'Ecuador', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=244464'),
  ('246594:BASE', '246594', 'Han-Noah Massengo', NULL, 72, 'CDM', '{CM}'::text[], 68, 48, 66, 74, 70, 72, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Technical}'::text[], '{}'::text[], 175, 'RIGHT', 'FC Augsburg', 'Bundesliga', 'France', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=246594'),
  ('248486:BASE', '248486', 'Lee Joon Suk', 'Lee Joon Suk', 60, 'LW', '{RW,LM}'::text[], 75, 51, 55, 62, 52, 61, NULL, NULL, NULL, NULL, NULL, NULL, 3, 5, '{}'::text[], '{}'::text[], 180, 'RIGHT', NULL, 'K League 1', 'South Korea', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=248486'),
  ('252181:BASE', '252181', 'Huang Jiahui', 'Huang Jiahui', 60, 'CDM', '{CB,CM}'::text[], 71, 35, 48, 58, 58, 64, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Long Ball Pass}'::text[], '{}'::text[], 185, 'RIGHT', 'Tianjin JMT FC', 'CSL', 'China PR', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=252181'),
  ('254475:BASE', '254475', 'Sumit Rathi', NULL, 54, 'CB', '{LB,LM}'::text[], 66, 33, 42, 49, 50, 66, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 176, 'LEFT', 'NorthEast United', 'ISL', 'India', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=254475'),
  ('256658:BASE', '256658', 'Jessic Ngankam', NULL, 69, 'ST', '{}'::text[], 80, 68, 59, 70, 27, 73, NULL, NULL, NULL, NULL, NULL, NULL, 3, 4, '{Acrobatic,Rapid}'::text[], '{}'::text[], 184, 'RIGHT', 'Frankfurt', 'Bundesliga', 'Germany', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=256658'),
  ('258687:BASE', '258687', 'Boris Popović', NULL, 67, 'CB', '{}'::text[], 54, 33, 51, 51, 66, 72, NULL, NULL, NULL, NULL, NULL, NULL, 2, 2, '{Precision Header,Aerial Fortress}'::text[], '{}'::text[], 189, 'RIGHT', 'Arouca', 'Liga Portugal', 'Serbia', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=258687'),
  ('260436:BASE', '260436', 'Syb van Ottele', NULL, 67, 'CB', '{CDM}'::text[], 61, 55, 50, 49, 68, 73, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Power Shot,Long Ball Pass}'::text[], '{}'::text[], 185, 'RIGHT', NULL, 'Eredivisie', 'Netherlands', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=260436'),
  ('262335:BASE', '262335', 'Elayis Tavşan', NULL, 68, 'RW', '{RM,CAM}'::text[], 80, 64, 62, 71, 24, 56, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Quick Step}'::text[], '{}'::text[], 183, 'LEFT', NULL, 'Serie BKT', 'Netherlands', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=262335'),
  ('263847:BASE', '263847', 'Wang Yu', 'Wang Yu', 56, 'CDM', '{CM}'::text[], 57, 38, 49, 55, 50, 60, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 178, 'RIGHT', 'Changchun Yatai', 'CSL', 'China PR', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=263847'),
  ('265116:BASE', '265116', 'Lina Hausicke', NULL, 72, 'CM', '{}'::text[], 66, 67, 72, 70, 70, 68, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Intercept,Aerial Fortress,Technical}'::text[], '{}'::text[], 176, 'RIGHT', 'SV Werder Bremen', 'GPFBL', 'Germany', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=265116'),
  ('266775:BASE', '266775', 'Park Jong Hyun', 'Park Jong Hyun', 60, 'CB', '{CDM}'::text[], 56, 24, 42, 47, 59, 69, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 185, 'RIGHT', 'FC Anyang', 'K League 1', 'South Korea', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=266775'),
  ('268763:BASE', '268763', 'Ernest Nuamah', NULL, 75, 'RM', '{RW}'::text[], 82, 70, 69, 78, 24, 58, NULL, NULL, NULL, NULL, NULL, NULL, 4, 3, '{Gamechanger,Rapid,Quick Step}'::text[], '{}'::text[], 178, 'LEFT', 'OL', 'Ligue 1 McDonald''s', 'Ghana', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=268763'),
  ('270578:BASE', '270578', 'Willum Þór Willumsson', NULL, 70, 'CAM', '{RM,CM}'::text[], 55, 69, 71, 71, 53, 76, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Relentless}'::text[], '{}'::text[], 193, 'LEFT', 'Birmingham City', 'EFL Championship', 'Iceland', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=270578'),
  ('272046:BASE', '272046', 'Jessica Martínez', NULL, 71, 'ST', '{LW,LM}'::text[], 63, 76, 69, 70, 46, 72, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{Dead Ball}'::text[], '{}'::text[], 160, 'RIGHT', 'Badalona Women', 'Liga F Moeve', 'Paraguay', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=272046'),
  ('273651:BASE', '273651', 'Jarell Quansah', NULL, 75, 'CB', '{}'::text[], 70, 34, 59, 68, 74, 75, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{Slide Tackle}'::text[], '{}'::text[], 190, 'RIGHT', 'Leverkusen', 'Bundesliga', 'England', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=273651'),
  ('275325:BASE', '275325', 'Tommaso Martinelli', NULL, 68, 'GK', '{}'::text[], NULL, NULL, NULL, NULL, NULL, NULL, 69, 67, 64, 70, NULL, 69, 1, 3, '{}'::text[], '{}'::text[], 196, 'RIGHT', 'Fiorentina', 'Serie A Enilive', 'Italy', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=275325'),
  ('276771:BASE', '276771', 'Malou Marcetto', NULL, 73, 'CM', '{CDM,CAM}'::text[], 71, 69, 71, 72, 69, 70, NULL, NULL, NULL, NULL, NULL, NULL, 3, 3, '{}'::text[], '{}'::text[], 178, 'RIGHT', 'Madrid CFF', 'Liga F Moeve', 'Denmark', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=276771'),
  ('278013:BASE', '278013', 'Saba Sazonov', NULL, 73, 'CB', '{}'::text[], 60, 40, 58, 61, 73, 70, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, '{}'::text[], '{}'::text[], 194, 'RIGHT', 'Torino', 'Serie A Enilive', 'Georgia', 'BASE_LAUNCH', 'https://www.ea.com/games/ea-sports-fc/ratings?playerId=278013')
) as v(
  provider_card_id, provider_player_id, player_name, common_name, rating, primary_position,
  alt_positions, pace, shooting, passing, dribbling, defending, physical,
  gk_diving, gk_handling, gk_kicking, gk_reflexes, gk_speed, gk_positioning,
  skill_moves, weak_foot, playstyles, playstyles_plus,
  height_cm, preferred_foot, club_name, league_name, nation_name,
  card_type, source_url
)
on conflict (provider, provider_card_id) where provider_card_id is not null
do update set
  fc_player_id = excluded.fc_player_id,
  player_name = excluded.player_name,
  common_name = excluded.common_name,
  rating = excluded.rating,
  primary_position = excluded.primary_position,
  alternative_positions = excluded.alternative_positions,
  pace = excluded.pace, shooting = excluded.shooting, passing = excluded.passing,
  dribbling = excluded.dribbling, defending = excluded.defending, physical = excluded.physical,
  gk_diving = excluded.gk_diving, gk_handling = excluded.gk_handling,
  gk_kicking = excluded.gk_kicking, gk_reflexes = excluded.gk_reflexes,
  gk_speed = excluded.gk_speed, gk_positioning = excluded.gk_positioning,
  skill_moves = excluded.skill_moves, weak_foot = excluded.weak_foot,
  playstyles = excluded.playstyles, playstyles_plus = excluded.playstyles_plus,
  height_cm = excluded.height_cm, preferred_foot = excluded.preferred_foot,
  club_name = excluded.club_name, league_name = excluded.league_name,
  nation_name = excluded.nation_name, card_type = excluded.card_type,
  source_url = excluded.source_url,
  club_id = excluded.club_id, league_id = excluded.league_id, nation_id = excluded.nation_id,
  is_active = true,
  last_synced_at = now(),
  updated_at = now();

commit;
