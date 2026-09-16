-- Corrige duplicidade de nacoes: 8 pares (nome em portugues + nome em
-- ingles) pro mesmo pais, sobra de um seed anterior -- o catalogo real usa
-- nome em ingles pra todas as 157 outras nacoes (mesmo padrao ja
-- documentado em playstyle_catalog.dart: nomes oficiais da EA nao mudam de
-- idioma). Reportado como "Brasil" e "Brazil" aparecendo juntos na lista de
-- selecao de pais do tecnico dentro do Squad Builder.
--
-- Reaponta fc_managers/fc_leagues/fc_players/fc_player_cards ANTES de
-- apagar o duplicado em portugues -- conferido antes de escrever esta
-- migration que fc_managers (20 linhas) e fc_leagues (5 linhas) de fato
-- usavam o id errado; fc_players e fc_player_cards nao tinham nenhuma,
-- mas o update roda de qualquer jeito (idempotente, 0 linhas se nao houver
-- match) em vez de assumir que vai continuar assim.
do $$
declare
    v_pt_id uuid;
    v_en_id uuid;
    v_pair record;
begin
    for v_pair in
        select * from (values
            ('Alemanha', 'Germany'),
            ('Brasil', 'Brazil'),
            ('Espanha', 'Spain'),
            ('França', 'France'),
            ('Inglaterra', 'England'),
            ('Itália', 'Italy'),
            ('Países Baixos', 'Netherlands'),
            ('Uruguai', 'Uruguay')
        ) as pairs(pt_name, en_name)
    loop
        select id into v_pt_id from public.fc_nations where name = v_pair.pt_name;
        select id into v_en_id from public.fc_nations where name = v_pair.en_name;

        if v_pt_id is null or v_en_id is null then
            raise exception 'expected both % and % to exist in fc_nations', v_pair.pt_name, v_pair.en_name;
        end if;

        update public.fc_managers set nation_id = v_en_id where nation_id = v_pt_id;
        update public.fc_leagues set nation_id = v_en_id where nation_id = v_pt_id;
        update public.fc_players set nation_id = v_en_id where nation_id = v_pt_id;
        update public.fc_player_cards set nation_id = v_en_id where nation_id = v_pt_id;

        delete from public.fc_nations where id = v_pt_id;
    end loop;
end;
$$;
