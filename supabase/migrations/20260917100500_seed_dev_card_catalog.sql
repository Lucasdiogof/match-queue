-- Dados de DESENVOLVIMENTO do catalogo de cartas.
--
-- Nada aqui e uma carta oficial de EA FC: os nomes de jogador e de tecnico
-- sao inventados e existem so para o Squad Builder ter o que renderizar
-- antes da Etapa 11. Por isso todos entram com provider = 'LOCAL' -- a
-- integracao real vai inserir com o provider dela, e limpar isto vira um
-- unico delete where provider = 'LOCAL'.
--
-- Nacoes e ligas sao dados de referencia neutros, tambem substituiveis.

insert into public.fc_nations (provider, provider_nation_id, name) values
    ('LOCAL', 'nation-1', 'Brasil'),
    ('LOCAL', 'nation-2', 'Argentina'),
    ('LOCAL', 'nation-3', 'França'),
    ('LOCAL', 'nation-4', 'Inglaterra'),
    ('LOCAL', 'nation-5', 'Espanha'),
    ('LOCAL', 'nation-6', 'Portugal'),
    ('LOCAL', 'nation-7', 'Alemanha'),
    ('LOCAL', 'nation-8', 'Itália'),
    ('LOCAL', 'nation-9', 'Países Baixos'),
    ('LOCAL', 'nation-10', 'Uruguai');

insert into public.fc_leagues (provider, provider_league_id, name, nation_id)
select 'LOCAL', v.pid, v.lname, n.id from (values
    ('league-1', 'Liga Nacional', 'Brasil'),
    ('league-2', 'Primeira Divisão', 'Portugal'),
    ('league-3', 'Liga Continental', 'Espanha'),
    ('league-4', 'Campeonato Insular', 'Inglaterra'),
    ('league-5', 'Série Principal', 'Itália'),
    ('league-6', 'Liga Federal', 'Alemanha')
) as v(pid, lname, nat)
join public.fc_nations as n on n.name = v.nat and n.provider = 'LOCAL';

insert into public.fc_player_cards
    (provider, provider_card_id, player_name, rating, primary_position,
     alternative_positions, pace, shooting, passing, dribbling, defending,
     physical, nation_name, card_type) values
    ('LOCAL', 'dev-card-1', 'Otávio Quaresma', 90, 'GK', '{}'::text[], 61, 73, 75, 78, 60, 66, 'Espanha', 'Base'),
    ('LOCAL', 'dev-card-2', 'Xavier Matos', 73, 'GK', '{}'::text[], 76, 75, 70, 62, 67, 90, 'Brasil', 'Destaque'),
    ('LOCAL', 'dev-card-3', 'Vinícius Íbis', 76, 'GK', '{}'::text[], 79, 71, 72, 73, 69, 86, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-4', 'Heitor Pontes', 81, 'GK', '{}'::text[], 81, 71, 64, 74, 84, 87, 'Uruguai', 'Destaque'),
    ('LOCAL', 'dev-card-5', 'Rafael Matos', 73, 'CB', '{}'::text[], 92, 55, 70, 63, 67, 74, 'Inglaterra', 'Base'),
    ('LOCAL', 'dev-card-6', 'Quirino Faria', 89, 'CB', '{}'::text[], 83, 82, 85, 59, 92, 75, 'Inglaterra', 'Destaque'),
    ('LOCAL', 'dev-card-7', 'Rafael Cordeiro', 79, 'CB', '{}'::text[], 57, 57, 86, 74, 93, 59, 'França', 'Destaque'),
    ('LOCAL', 'dev-card-8', 'Fábio Guedes', 90, 'CB', '{}'::text[], 78, 93, 64, 62, 61, 83, 'Portugal', 'Destaque'),
    ('LOCAL', 'dev-card-9', 'Fábio Dias', 85, 'CB', '{}'::text[], 83, 70, 72, 64, 94, 88, 'Espanha', 'Destaque'),
    ('LOCAL', 'dev-card-10', 'Nuno Horta', 81, 'CB', '{}'::text[], 65, 66, 66, 85, 77, 75, 'Brasil', 'Elite'),
    ('LOCAL', 'dev-card-11', 'Murilo Teles', 73, 'LB', array['LWB']::text[], 76, 75, 70, 60, 71, 83, 'França', 'Destaque'),
    ('LOCAL', 'dev-card-12', 'Prisco Cordeiro', 87, 'LB', array['LWB']::text[], 70, 88, 72, 88, 85, 93, 'França', 'Destaque'),
    ('LOCAL', 'dev-card-13', 'Rafael Neves', 86, 'LB', array['LWB']::text[], 80, 63, 81, 89, 92, 77, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-14', 'Bento Matos', 89, 'RB', array['RWB']::text[], 83, 61, 81, 57, 55, 83, 'Argentina', 'Base'),
    ('LOCAL', 'dev-card-15', 'Yuri Rangel', 75, 'RB', array['RWB']::text[], 93, 84, 86, 63, 84, 82, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-16', 'Xavier Horta', 80, 'RB', array['RWB']::text[], 84, 82, 76, 88, 88, 64, 'Portugal', 'Elite'),
    ('LOCAL', 'dev-card-17', 'Zeca Dias', 73, 'CDM', array['CM']::text[], 67, 92, 91, 95, 85, 56, 'Espanha', 'Destaque'),
    ('LOCAL', 'dev-card-18', 'Jonas Faria', 79, 'CDM', array['CM']::text[], 73, 60, 57, 93, 90, 61, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-19', 'Sílvio Guedes', 83, 'CDM', array['CM']::text[], 93, 80, 67, 77, 66, 60, 'Alemanha', 'Base'),
    ('LOCAL', 'dev-card-20', 'Gil Íbis', 75, 'CDM', array['CM']::text[], 74, 84, 88, 82, 83, 90, 'Uruguai', 'Base'),
    ('LOCAL', 'dev-card-21', 'Nuno Neves', 75, 'CM', array['CDM','CAM']::text[], 95, 95, 55, 68, 82, 94, 'Inglaterra', 'Base'),
    ('LOCAL', 'dev-card-22', 'Nuno Guedes', 85, 'CM', array['CDM','CAM']::text[], 60, 58, 77, 71, 78, 84, 'Espanha', 'Destaque'),
    ('LOCAL', 'dev-card-23', 'Ubiratã Lemos', 81, 'CM', array['CDM','CAM']::text[], 87, 86, 87, 71, 80, 83, 'Portugal', 'Base'),
    ('LOCAL', 'dev-card-24', 'Zeca Neves', 87, 'CM', array['CDM','CAM']::text[], 83, 85, 92, 85, 60, 89, 'França', 'Elite'),
    ('LOCAL', 'dev-card-25', 'Kléber Lemos', 85, 'CM', array['CDM','CAM']::text[], 91, 59, 93, 74, 56, 92, 'Argentina', 'Destaque'),
    ('LOCAL', 'dev-card-26', 'Jonas Dias', 91, 'CAM', array['CM']::text[], 78, 73, 93, 66, 70, 65, 'Países Baixos', 'Base'),
    ('LOCAL', 'dev-card-27', 'Otávio Teles', 79, 'CAM', array['CM']::text[], 91, 59, 81, 67, 91, 91, 'Brasil', 'Destaque'),
    ('LOCAL', 'dev-card-28', 'Bento Teles', 78, 'CAM', array['CM']::text[], 76, 91, 67, 88, 91, 75, 'Brasil', 'Base'),
    ('LOCAL', 'dev-card-29', 'Yuri Faria', 90, 'CAM', array['CM']::text[], 78, 80, 75, 93, 95, 65, 'Argentina', 'Elite'),
    ('LOCAL', 'dev-card-30', 'Murilo Pontes', 83, 'LM', array['LW']::text[], 65, 56, 89, 87, 77, 60, 'Uruguai', 'Base'),
    ('LOCAL', 'dev-card-31', 'Tadeu Faria', 73, 'LM', array['LW']::text[], 64, 83, 85, 94, 83, 83, 'Portugal', 'Destaque'),
    ('LOCAL', 'dev-card-32', 'Nuno Esteves', 82, 'LM', array['LW']::text[], 90, 87, 84, 79, 67, 61, 'Brasil', 'Base'),
    ('LOCAL', 'dev-card-33', 'Tadeu Barros', 78, 'RM', array['RW']::text[], 91, 82, 78, 90, 79, 58, 'França', 'Base'),
    ('LOCAL', 'dev-card-34', 'Lauro Faria', 79, 'RM', array['RW']::text[], 58, 92, 66, 61, 95, 91, 'Espanha', 'Base'),
    ('LOCAL', 'dev-card-35', 'Fábio Faria', 84, 'RM', array['RW']::text[], 93, 82, 59, 77, 67, 86, 'Alemanha', 'Destaque'),
    ('LOCAL', 'dev-card-36', 'Quirino Neves', 82, 'LW', array['LM','ST']::text[], 57, 66, 66, 92, 81, 64, 'Argentina', 'Destaque'),
    ('LOCAL', 'dev-card-37', 'Rafael Dias', 75, 'LW', array['LM','ST']::text[], 70, 61, 82, 95, 74, 73, 'Portugal', 'Elite'),
    ('LOCAL', 'dev-card-38', 'Vinícius Faria', 91, 'LW', array['LM','ST']::text[], 85, 93, 70, 89, 73, 55, 'Alemanha', 'Base'),
    ('LOCAL', 'dev-card-39', 'Jonas Matos', 75, 'RW', array['RM','ST']::text[], 87, 95, 85, 61, 91, 80, 'Argentina', 'Base'),
    ('LOCAL', 'dev-card-40', 'Aurélio Oliveira', 91, 'RW', array['RM','ST']::text[], 90, 88, 56, 59, 80, 57, 'Portugal', 'Base'),
    ('LOCAL', 'dev-card-41', 'Gil Esteves', 73, 'RW', array['RM','ST']::text[], 77, 75, 95, 85, 65, 56, 'Espanha', 'Base'),
    ('LOCAL', 'dev-card-42', 'Nuno Sampaio', 79, 'CF', array['ST','CAM']::text[], 70, 79, 94, 89, 92, 93, 'Brasil', 'Base'),
    ('LOCAL', 'dev-card-43', 'Caio Almeida', 72, 'CF', array['ST','CAM']::text[], 62, 56, 58, 66, 62, 79, 'Alemanha', 'Base'),
    ('LOCAL', 'dev-card-44', 'Sílvio Pontes', 91, 'CF', array['ST','CAM']::text[], 81, 58, 90, 65, 58, 79, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-45', 'Vinícius Cordeiro', 77, 'ST', array['CF']::text[], 57, 80, 95, 84, 86, 78, 'França', 'Base'),
    ('LOCAL', 'dev-card-46', 'Caio Rangel', 80, 'ST', array['CF']::text[], 66, 60, 84, 55, 64, 72, 'Espanha', 'Base'),
    ('LOCAL', 'dev-card-47', 'Sílvio Íbis', 75, 'ST', array['CF']::text[], 89, 62, 73, 94, 76, 55, 'Países Baixos', 'Destaque'),
    ('LOCAL', 'dev-card-48', 'Ubiratã Guedes', 88, 'ST', array['CF']::text[], 64, 58, 95, 58, 93, 58, 'Países Baixos', 'Base'),
    ('LOCAL', 'dev-card-49', 'Quirino Dias', 78, 'ST', array['CF']::text[], 64, 74, 81, 64, 56, 78, 'Itália', 'Base'),
    ('LOCAL', 'dev-card-50', 'Tadeu Esteves', 86, 'ST', array['CF']::text[], 84, 66, 95, 64, 56, 80, 'Itália', 'Base');

insert into public.fc_managers (provider, provider_manager_id, name, nation_id)
select 'LOCAL', v.pid, v.mname, n.id from (values
    ('man-1', 'Kléber Rangel', 'Itália'),
    ('man-2', 'Elias Barros', 'Itália'),
    ('man-3', 'Sílvio Neves', 'França'),
    ('man-4', 'Prisco Íbis', 'Inglaterra'),
    ('man-5', 'Prisco Rangel', 'Portugal'),
    ('man-6', 'Ubiratã Teles', 'Países Baixos'),
    ('man-7', 'Murilo Esteves', 'Portugal'),
    ('man-8', 'Xavier Lemos', 'França'),
    ('man-9', 'Bento Pontes', 'Brasil'),
    ('man-10', 'Vinícius Lemos', 'Países Baixos'),
    ('man-11', 'Quirino Barros', 'Alemanha'),
    ('man-12', 'Tadeu Cordeiro', 'Brasil'),
    ('man-13', 'Aurélio Matos', 'Alemanha'),
    ('man-14', 'Heitor Quaresma', 'Uruguai'),
    ('man-15', 'Dante Cordeiro', 'Portugal'),
    ('man-16', 'Zeca Pontes', 'Alemanha'),
    ('man-17', 'Xavier Esteves', 'Alemanha'),
    ('man-18', 'Rafael Sampaio', 'Inglaterra'),
    ('man-19', 'Vinícius Horta', 'França'),
    ('man-20', 'Murilo Guedes', 'Países Baixos'),
    ('man-21', 'Tadeu Quaresma', 'Alemanha'),
    ('man-22', 'Zeca Guedes', 'Argentina'),
    ('man-23', 'Rafael Esteves', 'Uruguai'),
    ('man-24', 'Sílvio Sampaio', 'França')
) as v(pid, mname, nat)
join public.fc_nations as n on n.name = v.nat and n.provider = 'LOCAL';
