-- Disponibilidade de arte oficial por carta.
--
-- Sem esta coluna, card_image_url NULL e ambiguo: "nunca testei" e "testei e
-- nao existe" ficam identicos. A diferenca importa porque a ausencia de arte
-- NAO e previsivel por faixa de id -- medido: 23 de 108 cartas nao tem arte,
-- espalhadas nos dois generos e nos tres tiers, com as faixas de id que
-- falham e que passam se sobrepondo por inteiro. Ou seja, cada carta precisa
-- ser testada individualmente, e o resultado negativo precisa ficar gravado,
-- senao toda reexecucao re-sonda o catalogo inteiro.
--
-- Leitura das duas colunas juntas:
--
--   url preenchida                -> arte disponivel, confirmada
--   url NULL + checked_at NULL    -> ainda nao testada
--   url NULL + checked_at <> NULL -> testada, arte ausente na origem
--
-- Nada aqui toca rating, posicao, stats, PlayStyles, clube, liga ou nacao.

alter table public.fc_player_cards
    add column if not exists card_image_checked_at timestamptz;

comment on column public.fc_player_cards.card_image_checked_at is
    'Quando a disponibilidade da arte foi verificada pela ultima vez. NULL = nunca testada. Com card_image_url NULL, indica ausencia confirmada na origem.';

-- Indice parcial para a fila do probe: so as nao testadas. Como a coluna
-- deixa de ser NULL assim que a carta e verificada, o indice encolhe ate
-- sumir na pratica -- e nao pesa nos writes normais do catalogo.
create index if not exists fc_player_cards_artwork_pending_idx
    on public.fc_player_cards (id)
    where card_image_checked_at is null and is_active;

-- ---------------------------------------------------------------------
-- Aplicacao do resultado do probe, em lote.
--
-- Existe para que "o probe nao altera rating/stats/clube/liga/nacao" seja
-- uma propriedade ESTRUTURAL e nao uma promessa sobre o codigo do cliente:
-- esta funcao so consegue escrever card_image_url e card_image_checked_at.
-- Qualquer outra coluna esta fora do alcance dela.
--
-- Generica de proposito -- as URLs chegam prontas do chamador, entao nenhum
-- fornecedor fica gravado no schema.
--
-- is_active filtra as cartas inativas (as 50 do provider LOCAL), que nunca
-- entram na fila e tambem nao podem ser tocadas por um id passado a mao.
-- ---------------------------------------------------------------------
create or replace function public.apply_card_artwork_probe(
    p_found_ids uuid[] default '{}',
    p_found_urls text[] default '{}',
    p_missing_ids uuid[] default '{}'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_found integer := 0;
    v_missing integer := 0;
begin
    if coalesce(array_length(p_found_ids, 1), 0)
       <> coalesce(array_length(p_found_urls, 1), 0) then
        raise exception 'found ids and urls must have the same length'
            using errcode = 'FQ047';
    end if;

    with input as (
        select unnest(p_found_ids) as id, unnest(p_found_urls) as url
    )
    update public.fc_player_cards as c
       set card_image_url = i.url,
           card_image_checked_at = now()
      from input as i
     where c.id = i.id
       and c.is_active;
    get diagnostics v_found = row_count;

    update public.fc_player_cards as c
       set card_image_url = null,
           card_image_checked_at = now()
     where c.id = any(p_missing_ids)
       and c.is_active;
    get diagnostics v_missing = row_count;

    return jsonb_build_object('found', v_found, 'missing', v_missing);
end;
$$;

comment on function public.apply_card_artwork_probe(uuid[], text[], uuid[]) is
    'Grava o resultado do probe de artwork. Alcanca SOMENTE card_image_url e card_image_checked_at.';

-- Manutencao server-side apenas: nem o app nem um usuario logado chamam isto.
revoke execute on function public.apply_card_artwork_probe(uuid[], text[], uuid[])
    from public, anon, authenticated;
