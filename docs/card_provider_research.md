# Pesquisa de provedores de dados de cartas EA FC 27

Feita na Etapa 11 (2026-09-08), via WebSearch/WebFetch. Objetivo: escolher a
fonte dos dados reais de cartas que substituem as 50 cartas `provider =
'LOCAL'` da Etapa 10 (`docs/handoff_etapa10.md`).

## Regra dura, repetida aqui de propósito

Nunca contornar CAPTCHA, Cloudflare, nem usar cookies/tokens roubados ou
privados. Qualquer fonte que exigisse isso foi descartada, sem exceção,
mesmo que fosse tecnicamente a "melhor" cobertura de campos.

## Achado que muda o cenário: EA lançou uma Community API oficial

Em julho de 2026 a EA anunciou uma **Community API** oficial para o EA
SPORTS FC, concedendo acesso aprovado a dados de conta/Ultimate Team para
parceiros selecionados — FUT.GG, FUTBIN e FUTWIZ estão entre os primeiros
aprovados. Isso significa duas coisas:

1. Os três sites do pedido original (fut.gg, futbin, futwiz) hoje têm um
   canal **oficial e legítimo** de acesso a dados — mas esse canal é deles
   como parceiros aprovados pela EA, não um endpoint público que o FIFA
   Queue possa simplesmente consumir sem virar parceiro EA também.
2. Sem ser parceiro aprovado, o único jeito de tirar dados desses três
   sites hoje é scraping do HTML/JSON interno deles — o que esbarra direto
   na regra dura: os três já reforçaram proteção (Cloudflare/ToS) depois
   de virarem parceiros oficiais, exatamente para não vazar a integração
   nova.

## Comparativo

| Fonte | Tipo de acesso | Cobertura de campos | Estabilidade / risco | ToS |
| --- | --- | --- | --- | --- |
| **fut.gg** | Antes: paginação JSON não-documentada em `/players/`. Hoje: parceiro da EA Community API (acesso oficial, mas exige ser aprovado como parceiro EA — não é um endpoint público). Tentativa de acesso direto sem parceria caiu em 404/Cloudflare nesta pesquisa. | Historicamente completa (rating, posições, GK, playstyles, skill moves, pé fraco, altura, papéis) quando acessível. | Alto risco: por trás de Cloudflare, layout/API interna muda sem aviso, e agora tem incentivo extra da EA para fechar acesso não-parceiro. | Descartado — exigiria contornar proteção anti-bot. |
| **futbin.com** | ToS (`futbin.com/tos`) proíbe explicitamente "unauthorized access to the Website... or any server, computer, or database connected". Tem endpoints de terceiros (Apify, Parse.bot) fazendo scraping por fora, o que não muda o ToS do site em si. Também virou parceiro da EA Community API. | Rating, posições, preço de mercado, SBCs, playstyles — boa cobertura, mas parte fica atrás de assinatura premium no próprio site. | Alto risco/descartado: ToS proíbe explicitamente, e contornar isso seria a exata prática que a regra dura veta. | **Descartado por ToS explícito.** |
| **futwiz.com** | Não foi encontrado endpoint público documentado; mesmo padrão dos outros dois (site com proteção anti-bot, dados via scraping não-oficial). | Provavelmente comparável a fut.gg/futbin (não verificado a fundo, descartado antes por causa do padrão de acesso). | Alto risco — mesmo raciocínio dos outros dois. | Descartado pelo mesmo motivo estrutural. |
| **Datasets comunitários (GitHub/Kaggle)** — ex. `EAFC26-DataHub` (Kaggle "FC 26 Player Data", ~18k jogadores, 110+ atributos), `sofifa-web-scraper` (scrape do SoFIFA, ~18k jogadores), `FC25-Players-ETL` | Download direto de arquivo CSV/JSON versionado — **sem scraping ao vivo, sem bot, sem CAPTCHA**. Atualização é manual (baixar o CSV mais novo), não um endpoint. | Ampla (rating, posições, stats, nação, liga, clube, altura, pé) — GK stats e playstyles variam por dataset, precisam de validação campo a campo antes do import. | Baixo risco operacional (arquivo estático, licença geralmente aberta/CC), mas **não é tempo real** — cada atualização de patch da EA exige baixar um CSV novo manualmente. | Depende da licença específica do dataset (verificar antes de redistribuir imagens). |
| **SoFIFA.com** | HTML público, tabelas simples, sem login, historicamente tolerante a scraping pontual e de baixo volume (não confirma ToS explícito nesta pesquisa). | Rating, posições, stats completos, nação, liga, clube, altura, pé — GK stats e playstyles mais limitados que fut.gg/futbin. | Risco médio: é scraping de HTML de um site de terceiros (frágil a mudança de layout), mas sem Cloudflare/CAPTCHA hoje. | Sem ToS anti-scraping explícito encontrado, mas convém manter volume baixo e cache local. |

## Decisão — dataset concreto, não "tipo X ou equivalente"

Pesquisa complementar em 2026-09-08 (segunda sessão desta etapa) trocou o
placeholder genérico abaixo por uma escolha concreta e verificada.

**Provider primário: "FC 26 (FIFA 26) Player Data"**

| Campo | Valor |
| --- | --- |
| Nome exato | FC 26 (FIFA 26) Player Data |
| URL | https://www.kaggle.com/datasets/rovnez/fc-26-fifa-26-player-data |
| Mantenedor | `rovnez` (perfil Kaggle, sem afiliação declarada com EA/parceiros) |
| Licença | **CC BY 4.0** (Attribution 4.0 International) — uso comercial permitido, exige atribuição. Confirmado via metadado `schema.org/Dataset` embutido na página (`"license":{"name":"Attribution 4.0 International (CC BY 4.0)"}`), não por leitura visual da página (Kaggle é SPA, texto renderizado por JS não é lido pelo WebFetch). |
| FC26/FC27 cobertos | FC 26 explicitamente (nome do dataset e descrição). Não há confirmação de dados FC 27 — é o mais recente disponível nesta pesquisa; `game_version` grava `FC27` no nosso schema mas o dado de origem real é rotulado FC26 pelo autor. **Anotar isso é importante**: `game_version` no import deve refletir o rótulo real do dado (`FC26`), não forçar `FC27` só porque é o padrão do importer — ajustar `--game-version=FC26` no comando de sync. |
| Data/frequência de atualização | Versão 3, `dateModified` 2025-09-22T18:19:44Z. Sem cron/API — atualização é manual pelo autor subindo nova versão; nós replicamos isso baixando a versão mais nova manualmente quando quisermos atualizar, não há como automatizar sem credencial Kaggle configurada. |
| Quantidade aproximada | Descrição cita "18,000+" como padrão da família de datasets sofifa-scrape; este dataset específico não expõe row count na metadata pública, mas o arquivo é 3.184.169 bytes (zip) — compatível com a mesma ordem de grandeza (~18k linhas, dezenas de colunas). |
| Posições alternativas | Sim — coluna única `player_positions` (ex. `"ST, LW, CF"`), primeira é a primária, resto são alternativas. Não vem em colunas separadas. |
| Stats | Sim, nomenclatura sofifa clássica: `pace/shooting/passing/dribbling/defending/physic` (nota: `physic`, não `physical`) para linha; `goalkeeping_diving/handling/kicking/reflexes/speed/positioning` para goleiro — nunca os dois preenchidos na mesma linha. |
| Clubes/Ligas/Nações | Sim — `club_name`, `league_name`, `nationality_name` como texto (não IDs), resolvidos para as tabelas `fc_clubs`/`fc_leagues`/`fc_nations` pelo importer via upsert-por-nome. |
| Managers/técnicos | **Não.** Datasets sofifa-scrape são focados em jogador, nunca tiveram campo de técnico/staff em nenhuma versão conhecida (FIFA 15 a FC 26). Fica como limitação estrutural da fonte, não uma omissão do import — ver "Managers" abaixo. |
| Imagens | Coluna `player_face_url` (retrato do jogador). Não há imagem de "carta" no estilo Ultimate Team (rating/posição sobrepostos) — só a foto do jogador. `card_image_url` é preenchido com o mesmo valor de `player_face_url` como aproximação; card art de verdade não existe nesta fonte. |
| Formato dos arquivos | ZIP contendo CSV (confirmado por `encodingFormat`/`fileFormat: "zip"` na metadata; o conteúdo interno de datasets desta família é sempre um único CSV). |
| Estabilidade dos IDs | Coluna `sofifa_id` é o id estável entre versões do mesmo jogador no ecossistema sofifa (usado como `provider_card_id`) — jogadores mantêm o mesmo `sofifa_id` ano a ano, o que torna o upsert idempotente confiável mesmo quando o dataset for atualizado para uma versão nova. |
| Limitações conhecidas | (1) Requer conta Kaggle logada para clicar em "Download" — não há endpoint anônimo; (2) sem técnicos/managers; (3) sem card art estilo UT, só foto de jogador; (4) `game_version` real é FC26, não FC27; (5) atualização é manual, sem API/cron. |
| Por que este e não FUT.GG/FUTBIN/FUTWIZ | Ver seção "Achado que muda o cenário" acima — os três viraram parceiros aprovados da EA Community API, então acessá-los sem ser parceiro exigiria contornar Cloudflare/ToS, proibido pela regra dura desta etapa. Este dataset é scraping histórico já feito e publicado sob licença aberta (CC BY 4.0) por terceiro, sem exigir bypass de proteção nenhuma da nossa parte — só um clique de download numa conta gratuita. |

Justificativa geral (mantida do texto original desta seção):

- É o único caminho que não depende de scraping ao vivo nem de contornar
  proteção alguma — cumpre a regra dura com folga, não no limite dela.
- A importação já era desenhada para ser um processo manual/periódico
  (`npm run sync:fc-cards` rodado à mão), então "não ser tempo real" não é
  uma desvantagem real para este produto — ele já não pretendia sincronizar
  a cada patch da EA automaticamente.
- O schema (`provider`, `provider_card_id`, `last_synced_at`, `source_url`)
  foi desenhado para aceitar qualquer fonte compatível depois, incluindo
  fut.gg/futbin/futwiz no dia em que o FIFA Queue eventualmente vire parceiro
  aprovado da EA Community API — essa é a linha oficial e correta pra esse
  caminho, não scraping por fora.

**Fallback: SoFIFA**, só para preencher campos que o dataset comunitário não
tiver (ex.: imagem de clube específica) — scraping pontual, baixo volume,
nunca automatizado num cron, sempre revisado manualmente antes de upsert.

**Nunca**: fut.gg, futbin, futwiz por scraping direto. Ficam registrados
aqui como "vire parceiro oficial da EA Community API primeiro", não como
"tente contornar a proteção deles".

## O que isso significa para o importer desta etapa

O importer (`tool/sync_fc_cards.dart`, descrito no handoff) foi escrito para
ler um arquivo CSV local já baixado pelo usuário (dataset comunitário) e
fazer upsert idempotente — nunca para baixar nada da internet sozinho.
Baixar o CSV de fato (Kaggle exige conta/click manual, então nem daria pra
automatizar sem credenciais) e rodar o importer contra o Supabase remoto
ficou como **pendência consciente**, documentada no handoff — esta sessão
não tinha o arquivo de dados real disponível nem permissão prévia para
baixar um arquivo de terceiro sem confirmação explícita do usuário no chat
(regra do ambiente: download de arquivo é ação que exige permissão
explícita, e esta sessão roda sem supervisão síncrona).

## Correção de status crítica (revisão do dono do produto, 2026-09-08)

O dataset escolhido acima **NÃO é uma fonte de dados final** para o
catálogo de cartas Ultimate Team. É uma fonte **provisória**, usada para
validar o pipeline inteiro (importer, schema, busca, filtros, picker) com
dado real e não-trivial em vez de continuar rodando só contra as 50 cartas
`LOCAL` inventadas na Etapa 10. Registrando aqui os quatro pontos que o
dono do produto pediu para nunca ficarem implícitos:

1. **É FC26, não FC27.** O produto tem FC27 como alvo declarado; este
   dataset nunca alega ser FC27. `game_version` gravado no banco para
   essas linhas é `FC26`, honesto com a origem — nunca `FC27` só porque é
   o default do importer.
2. **É player database, não carta Ultimate Team.** O dataset (schema
   sofifa-scrape clássico) tem **uma linha por jogador**, sem `card_type`/
   `rarity` reais, sem múltiplas versões do mesmo jogador (sem "Mbappé
   TOTS" vs "Mbappé Gold Rare" como linhas separadas), e sem rating
   variando por versão de carta — é o rating "base" daquele jogador na
   base sofifa, não um rating específico de carta especial. Nenhuma linha
   deste provider deve ser chamada de "carta UT real" em nenhum lugar do
   produto (UI, docs, commit message). O importer grava
   `card_type = 'BASE_DATASET'` para toda linha desta fonte (nunca
   inventa `'Special Card'`/`'Rare'`/etc. quando o CSV não declara isso).
3. **Serve como fallback/bootstrap.** Prova que schema (`fc_clubs`,
   `fc_nations`, `fc_leagues`, GK stats corretos, playstyles, etc.),
   importer (upsert idempotente, `is_active`, contagem de
   inserido/atualizado/ignorado/falha) e o lado Flutter (busca, filtros,
   picker, imagens) funcionam ponta a ponta contra dado real — sem
   depender de achar a fonte "definitiva" primeiro.
4. **FC27/UT real ainda precisa de fonte própria.** Continua em aberto —
   ver seção "Pendência explícita: FC27 UT catalog source" mais abaixo,
   escrita depois de uma segunda rodada de pesquisa dedicada a isso.
   Cartas especiais Ultimate Team (TOTS, Icons, versões in-form etc.) quase
   certamente vão exigir um provider diferente deste, mesmo que uma fonte
   FC27 "base" apareça.

**Nome do provider no banco**: `KAGGLE_ROVNEZ_FC26` — nunca `FUTGG`/
`FUTBIN`/`FUTWIZ` (o dado não vem de lá) nem `LOCAL` (esse continua
reservado para as 50 cartas dev inventadas da Etapa 10). O nome é
explícito sobre fonte (Kaggle), autor (rovnez) e versão do jogo (FC26) —
qualquer pessoa lendo uma linha do banco sabe de onde ela veio sem
precisar abrir este documento.

### Schema: por que `fc_player_cards` mesmo sem ser carta UT de verdade

Avaliado introduzir uma tabela `fc_players` separada (jogador/identidade
base) e reservar `fc_player_cards` só para versões UT de verdade. Decisão:
**não fazer essa migration agora** — usar `fc_player_cards.card_type =
'BASE_DATASET'` como marcador explícito, exatamente como o dono do produto
ofereceu como alternativa aceitável. Motivos:

- O contrato Flutter (`PlayerCardCatalogRepository`, Etapa 10) já é
  provider-agnostic e não assume nada sobre "uma linha = uma carta única
  de verdade" — ele so pede busca/paginação/filtro por um objeto com
  rating+posição+stats, que uma linha de player database preenche sem
  forçar nada.
- Quando (se) uma fonte FC27 UT real aparecer, ela entra como outro
  `provider` na mesma tabela, com `card_type` de verdade (`'Gold Rare'`,
  `'TOTS'`, etc.) — nenhuma migration de separação é bloqueante para isso.
- **Isto é explicitamente provisório, não a solução final.** Se o produto
  crescer a ponto de precisar modelar "um jogador, N cartas dele" como
  relação de primeira classe (ex.: comparar duas versões do mesmo jogador
  lado a lado), a separação `fc_players`/`fc_player_cards` vira a
  migration certa — só não agora, sem uso real que justifique o custo.

## Pendência explícita: FC27 UT catalog source

**Ainda não resolvida.** Pesquisa dedicada rodada em 2026-09-08 (mesma
sessão) não encontrou uma fonte gratuita de cartas Ultimate Team FC27 reais
(com `card_type`/rarity, múltiplas versões por jogador, rating por versão)
que não exija contornar proteção ou virar parceiro aprovado da EA. Ver
seção dedicada mais abaixo para o detalhamento completo dessa segunda
rodada — **a Etapa 11 não fecha 100% enquanto este item não virar A
(fonte encontrada) ou B (confirmado documentadamente que não existe fonte
adequada ainda)**, conforme pedido do dono do produto.
