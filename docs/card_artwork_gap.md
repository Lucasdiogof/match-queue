# Arte das cartas — auditoria e blocker

Pergunta: dá para exibir a carta real do jogador (arte com foto, overall,
posição, país, clube, liga) em vez de uma carta redesenhada?

**Resposta: não hoje. Não existe nenhum asset visual no catálogo.** O gap não
é de renderização nem de persistência — é da própria fonte.

## 1. O que foi verificado

### Banco (produção, 2026-09-10)

Sete colunas capazes de guardar imagem existem. **Todas vazias.**

| Tabela | Coluna | Preenchidas |
| --- | --- | --- |
| `fc_player_cards` | `card_image_url` | **0** de 17.923 |
| `fc_player_cards` | `player_image_url` | **0** de 17.923 |
| `fc_players` | `image_url` | **0** de 17.873 |
| `fc_clubs` | `logo_image_url` | **0** de 646 |
| `fc_leagues` | `logo_image_url` | **0** de 63 |
| `fc_nations` | `flag_image_url` | **0** de 165 |

A única coluna de URL preenchida é `fc_player_cards.source_url` (17.873), e
ela **não é imagem**: aponta para a página de ratings da EA, no formato
`https://www.ea.com/games/ea-sports-fc/ratings?playerId=NNNNNN`.

### Importador (`tool/sync_fc_cards.dart`)

O pipeline **já está inteiro ligado**. Não descartou nada de imagem:

- declara `player_image_url` e `card_image_url` entre as colunas suportadas;
- grava `player_image_url` em `fc_players.image_url` **e** em
  `fc_player_cards.player_image_url`;
- tem fallback `card_image_url ?? player_image_url`;
- tem até alias `player_face_url` → ambas, para fontes com nome diferente.

Ou seja: se a fonte tivesse a coluna, a imagem teria entrado sozinha.

### Fonte (pacote FC27 / snapshot Wrexist)

Varridos todos os arquivos — `FC27_male_players.csv`,
`FC27_female_players.csv`, `FC27_male_players_reconciled.csv`,
`FC27_community_pack_input.csv` e `fc27_cards_normalized.csv`.

**Nenhum tem coluna de imagem.** A única coluna com URL é `source_url`. O
único acerto numa busca por `head` é `heading_accuracy`, que é atributo.

## 2. Onde exatamente está o gap

```
fonte (sem coluna de imagem)   <-- AQUI
   -> importador (pronto, aceita e mapeia)
      -> banco (colunas existem, vazias)
         -> app (renderiza arte quando houver)
```

Não falta importação, não falta persistência, não falta renderização. Falta
**o asset na origem**.

## 3. Por que não basta "ir buscar"

Todas as fontes com arte de carta de Ultimate Team já foram avaliadas e
descartadas por política, não por dificuldade técnica — ver
`card_provider_research.md`:

- **FUTWIZ, WeFUT, FUTBIN, FUT.GG, SoFIFA**: `robots.txt` com `Disallow: /`
  explícito e/ou ToS que proíbe.
- **`drop-api.ea.com`**: `ea.com/robots.txt` tem reserva de direitos explícita
  contra mineração automatizada. O `source_url` que temos aponta justamente
  para lá, então raspar a partir dele cai na mesma proibição.

Além disso a arte de carta é asset de marca da EA. Reproduzi-la seria
exatamente o oposto do disclaimer de não afiliação que o app já carrega.

## 4. O que destrava

O caminho legítimo é o dono do produto obter os assets (download manual,
pacote licenciado, ou arte própria) e fornecer um dataset com **uma coluna a
mais**: `card_image_url` (ou `player_image_url`, ou `player_face_url`).

A partir daí é **re-importação, zero código**. O app já renderiza a arte
assim que a URL existir, tanto na listagem quanto no detalhe.

## 5. Como a UI ficou enquanto isso

A carta redesenhada com gradiente dourado e iniciais gigantes foi
**abandonada**. Ela tinha dois problemas: imitava a identidade visual de
outra marca, e o monograma enorme no meio só anunciava a imagem que faltava.

O componente agora tem dois modos e escolhe sozinho:

- **Com arte** (`cardImageUrl ?? playerImageUrl`): a imagem **é** a carta,
  em `BoxFit.contain`, sem moldura desenhada por cima — a arte já traz
  overall, posição, clube e nação, e sobrepor isso seria duplicar.
- **Sem arte**: deixa de fingir ser um retrato e vira uma ficha — rating,
  posição, faixa fina por tier, nome, clube/nação e os seis atributos. O
  espaço vai para o que existe.

O detalhe segue a mesma regra: com arte, ela lidera o topo; sem arte, os
dados sobem direto, sem moldura vazia.

Quando as URLs chegarem, a listagem e o detalhe viram galeria de cartas reais
sem nenhuma mudança de código.
