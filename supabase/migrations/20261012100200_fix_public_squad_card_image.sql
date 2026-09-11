-- O avatar do perfil publico volta a aceitar SO rosto.
--
-- _public_squad_card_json devolvia coalesce(card_image_url, player_image_url).
-- Isso ficou inerte enquanto as duas colunas estavam vazias, mas passou a ser
-- um bug real assim que a arte oficial foi gravada em card_image_url: o
-- consumidor (squad_share_card.dart) recorta esse campo num ClipOval de 40px
-- com BoxFit.cover, ou seja, esperava um ROSTO. A carta inteira e 440x548 com
-- moldura, nome e atributos desenhados -- cortada num circulo de 40px vira um
-- pedaco de torso sobre fundo dourado, e justamente na tela de compartilhar.
--
-- A separacao passa a ser explicita e sem fallback cruzado:
--   card_image_url   -> componentes de CARTA (a arte inteira)
--   player_image_url -> rosto/avatar
--
-- Enquanto player_image_url estiver vazia, o campo vem null e o cliente cai
-- nas iniciais, que e o comportamento correto -- e o mesmo de antes de existir
-- artwork. Preferir um buraco honesto a uma imagem errada.
--
-- Mesma assinatura de proposito: "create or replace" com lista de parametros
-- diferente criaria uma SOBRECARGA em vez de substituir.

create or replace function public._public_squad_card_json(
    p_card public.fc_player_cards,
    p_chemistry integer
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
    select jsonb_build_object(
        'player_name', coalesce(p_card.common_name, p_card.player_name),
        'rating', p_card.rating,
        'position', p_card.primary_position,
        'image_url', p_card.player_image_url,
        'card_type', p_card.card_type,
        'chemistry', p_chemistry
    );
$$;

comment on function public._public_squad_card_json(public.fc_player_cards, integer) is
    'Carta enxuta do perfil publico. image_url e SO rosto: a arte inteira nunca vai para avatar circular.';

revoke execute on function public._public_squad_card_json(public.fc_player_cards, integer)
    from public, anon, authenticated;
