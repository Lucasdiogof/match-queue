# Pesquisa de provedores de dados de cartas EA FC 27

Feita na Etapa 11 (2026-09-08), via WebSearch/WebFetch. Objetivo: escolher a
fonte dos dados reais de cartas que substituem as 50 cartas `provider =
'LOCAL'` da Etapa 10 (`docs/handoff_etapa10.md`).

## Regra dura, repetida aqui de propósito

Nunca contornar CAPTCHA, Cloudflare, nem usar cookies/tokens roubados ou
privados. Qualquer fonte que exigisse isso foi descartada, sem exceção,
mesmo que fosse tecnicamente a "melhor" cobertura de campos.

## Quarta rodada (2026-09-08): FUTWIZ, WeFUT, SoFIFA, EA oficial, Kaggle/GitHub FC27, outros squad builders

Pedido do dono do produto: última rodada, exclusivamente fontes
gratuitas/legítimas de FC27, sem bypass de robots.txt/Cloudflare/ToS.
Sete candidatos investigados, nenhum sobrou.

| Candidato | URL | Tipo | FC27? | Base ou carta UT | robots.txt | ToS/licença | Bloqueio técnico | Veredito |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FUTWIZ | futwiz.com | HTML+API interna | Sim (`/fc27/players`) | Carta UT (rarity/versão reais) | **`Disallow: /` explícito para crawlers** | Parceiro EA Community API | N/A — bloqueado por política, nem cheguei a testar tecnicamente | **Descartado** |
| WeFUT | wefut.com | HTML | Sim (20k+ jogadores) | Carta UT | **`Disallow: /` explícito para crawlers** (já achado na rodada anterior) | Não é parceiro EA aprovado | N/A | **Descartado** |
| SoFIFA (base FC27) | sofifa.com | HTML | Sim — shortlists/squads FC27 já existem no site (confirmado por resultado de busca) | Base jogador (histórico da fonte) | **`Disallow: /` explícito para crawlers** (2 vezes no arquivo) + `Disallow: /api/` geral | Sem ToS anti-scraping explícito achado, mas o robots.txt já resolve | N/A | **Descartado** |
| EA oficial (`ea.com/games/ea-sports-fc/ratings`) | ea.com | HTML (primeira parte, marketing) | Sim | Base "ratings reveal" (não é catálogo UT) | Sem disallow específico da página, **mas reserva de direitos explícita no topo do robots.txt**: proíbe "web scraping, machine learning, or any form of text or data mining" de qualquer conteúdo EA sem autorização escrita | Reserva de direitos = ToS de fato | Nenhum (é o robots.txt/reserva que bloqueia, não Cloudflare) | **Descartado** — primeira-parte não significa livre de restrição |
| Kaggle/GitHub — dataset FC27 dedicado | — | dataset | — | — | — | — | — | **Não existe ainda.** Busca dedicada não achou nenhum dataset FC27 (só FC26/FC24/FIFA23 e anteriores) — o jogo é recente demais para a comunidade já ter publicado um equivalente ao dataset FC26 escolhido antes. Reavaliar daqui a algumas semanas/meses. |
| Fut-Api / fifa-FUT-Data (GitHub, comunidade) | github.com/MrNaughtZero/Fut-Api, github.com/kafagy/fifa-FUT-Data | API/scraper self-hosted | Não | Carta UT (quando funcionava) | N/A (código, não site) | Fut-Api sem license (`license: null` na API do GitHub), abandonado desde 2022-11; fifa-FUT-Data é MIT mas abandonado desde 2019-11 e mira exatamente FutHead/FutBin, hoje parceiros protegidos | Alvo do scraper (FutBin) está bloqueado | **Descartados** — nenhum é FC27, nenhum é mantido, e o alvo de um deles já é outro item descartado desta lista |
| fcratings.com | fcratings.com | HTML (WordPress) | Sim | Base "ratings" (WP fan site, não UT) | **Nenhum disallow para crawlers** — o único candidato desta rodada que passa no robots.txt | **ToS proíbe explicitamente**: "Use automated tools (scrapers, bots, crawlers, downloaders) to access or collect data" sem permissão escrita. Site declara "não afiliado a EA/FIFA", é fã-site independente. | Nenhum observado (200 OK, sem Cloudflare challenge) | **Descartado por ToS explícito**, apesar de tecnicamente acessível — é exatamente o caso que a regra dura cobre (nunca automação sem permissão, mesmo sem barreira técnica) |
| recharge.com (blog, "FC 27 Player Ratings Database") | recharge.com/blog/en-gb/fc-27-player-ratings-database | HTML, alega "capturado automaticamente do ratings público da EA" | Sim, 20.689 jogadores alegados | Base "ratings" (empresa de gift cards, não fã-site de FUT) | Sem disallow bloqueando esta página especificamente | Página de Termos retornou 404 nesta pesquisa — não verificável | Nenhum JSON/API/iframe encontrado no HTML estático — o widget "buscável" provavelmente carrega via JS não capturado por uma busca estática simples | **Inconclusivo, não adotado**: mesmo que fosse tecnicamente acessível, é o blog de uma empresa de gift cards revendendo dado de terceiro (a própria EA) sem confirmar direito de redistribuição, e sem nenhuma garantia de manutenção — sustentabilidade ruim como fonte de produto mesmo se o bloqueio de ToS não existisse |

### Conclusão da quarta rodada

**Nenhum candidato desta rodada é utilizável.** Três (FUTWIZ, WeFUT, SoFIFA)
bloqueiam a automação por nome no `robots.txt` — não é uma barreira
técnica a contornar, é a própria política do site dizendo "não". A fonte
oficial da EA tem reserva de direitos textual contra qualquer scraping/
mineração de dados. `fcratings.com` passa no `robots.txt` mas o próprio
ToS proíbe a mesma coisa em texto simples. `recharge.com` fica inconclusivo
tecnicamente e é uma fonte de baixa sustentabilidade mesmo sem o bloqueio.
Nenhum dataset FC27 dedicado existe ainda em Kaggle/GitHub — o jogo é
recente demais. **Nenhuma prova de conceito foi construída nesta rodada**,
porque nenhum candidato passou pelo primeiro filtro (robots.txt permitir +
ToS não proibir automação).

## Checagem técnica direta em FUT.GG e FUTBIN (2026-09-08, terceira rodada)

O dono do produto pediu para reabrir especificamente FUT.GG e FUTBIN como
possíveis fontes de FC27 UT real, já que ambos expõem publicamente listas
de jogadores FC27 no navegador. Investigação técnica direta (sem bypass,
só observando o que uma requisição comum recebe), nesta ordem:

### FUT.GG

- `robots.txt` (`fut.gg/robots.txt`) **desautoriza explicitamente
  `Disallow: /api/*`** para `User-agent: *`. Qualquer endpoint JSON
  público que a página use por baixo dos panos está, pelo próprio
  `robots.txt` do site, marcado como "não rastreie isto".
- `https://www.fut.gg/players/` responde `HTTP 200` (atrás de Cloudflare,
  mas sem desafio ativo para uma requisição simples) — título confirma
  "EA SPORTS FC 26 Players" (a rota default é FC26, precisaria achar o
  parâmetro/rota certa pra FC27, não investigado a fundo por já esbarrar
  no ponto seguinte).
- O HTML retornado é só o shell de uma aplicação **TanStack Start**
  (React) — confirmado pelo atributo `id="$tsr-stream-barrier"` no
  script de hidratação. **Nenhum jogador, nenhum link de jogador,
  nenhum payload JSON de dado real está no HTML inicial** — a lista
  completa é buscada depois, client-side, via chamadas JavaScript que
  batem exatamente nos caminhos `/api/*` que o `robots.txt` acabou de
  desautorizar. Ou seja: o único jeito de ver o dado real é executar o
  JS da página (navegador de verdade) e capturar chamadas para uma rota
  que o próprio site pede pra não automatizar.
- **Classificação: client-rendered, dado real servido por endpoint que o
  robots.txt marca `Disallow`.** Não há caminho de "HTML público
  simples" nem "payload JSON exposto sem precisar tocar `/api/*`".

### FUTBIN

- `robots.txt` (`futbin.com/robots.txt`) não desautoriza `/players`
  diretamente, mas desautoriza qualquer URL com query string
  (`Disallow: /*?*`, `/players/*?*`) — o que cobre busca/filtro/paginação
  por parâmetro, exatamente o que qualquer picker real precisaria.
- **Requisição simples e não-autenticada a `https://www.futbin.com/players`
  voltou `HTTP 403 Forbidden`, servido pelo Cloudflare** (`Server:
  cloudflare`, sem corpo de página, só a página de bloqueio padrão) — ou
  seja, proteção anti-bot ativa bloqueando uma requisição comum de
  verdade, não hipotética. Passar disso exigiria resolver o desafio do
  Cloudflare — exatamente o bypass que a regra dura proíbe.
- Some-se a isso o achado já registrado antes nesta pesquisa: o ToS do
  próprio FUTBIN proíbe explicitamente acesso não autorizado ao site ou a
  qualquer servidor/banco de dados conectado a ele.
- **Classificação: protegido/autenticado na prática (403 ativo) + ToS
  proíbe explicitamente.** Nenhuma prova de conceito é possível aqui sem
  violar as duas coisas ao mesmo tempo.

### Conclusão desta rodada

**Nenhuma prova de conceito foi construída contra FUT.GG ou FUTBIN.**
Não por falta de tentativa de investigação técnica (feita, documentada
acima), mas porque os dois já bloqueiam ou desautorizam exatamente o
caminho que uma extração real precisaria usar, checável de forma
concreta e reprodutível (não é achismo): `curl` simples contra FUTBIN
recebe `403` do Cloudflare agora mesmo; o `robots.txt` do FUT.GG
desautoriza `/api/*`, que é onde o dado de verdade mora. Isso reforça
(agora com evidência técnica direta, não só o anúncio da EA) a conclusão
já registrada na seção "Pendência explícita" abaixo: os dois são
parceiros aprovados da EA Community API precisamente porque o acesso
direto e não-autorizado a eles é, por design, bloqueado ou proibido.

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

**Nome do provider planejado para quando este import rodar**:
`KAGGLE_ROVNEZ_FC26` — nunca `FUTGG`/`FUTBIN`/`FUTWIZ` (o dado não vem de
lá) nem `LOCAL` (esse continua reservado para as 50 cartas dev inventadas
da Etapa 10). **Nota (ver "Estado real do catálogo" mais abaixo): este
import nunca chegou a rodar** — o dono do produto interrompeu o fluxo
antes da escrita no Supabase para focar a pesquisa em FC27 real primeiro.
O nome fica documentado aqui para quando (se) o import for retomado.

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

**Situação B confirmada: não existe, hoje, fonte gratuita adequada de
cartas Ultimate Team FC27 reais que não exija contornar proteção ou virar
parceiro aprovado da EA.** Pesquisa dedicada rodada em 2026-09-08:

- **EA FC Community API está fechada para novos parceiros.** Confirmado no
  próprio comunicado oficial da EA
  (`ea.com/games/ea-sports-fc/fc-26/news/pitch-notes-fc26-community-api-update`):
  "these are the only three approved websites at this time" e "we are not
  accepting requests at this time" — FUT.GG, FUTBIN e FUTWIZ são os únicos
  parceiros, sem processo de inscrição aberto e sem prazo anunciado para
  abrir. Não há caminho legítimo para o FIFA Queue virar parceiro hoje.
- **`MrNaughtZero/Fut-Api`** (GitHub): API JSON com dados de UT (clubes,
  jogadores, ligas, card types). **Descartado**: sem license (GitHub API
  confirma `license: null`, ou seja copyright padrão, sem permissão de uso
  concedida), e último commit em 2022-11-21 — abandonado, não cobre FC27.
- **`kafagy/fifa-FUT-Data`** (GitHub): scraper de FutHead/FutBin para CSV.
  License MIT (permissiva), mas último commit em 2019-11-26 — abandonado, e
  o alvo do scraping (FutHead/FutBin) é exatamente um dos três parceiros
  hoje protegidos por Cloudflare/ToS reforçado. Rodar isso hoje contra
  FutBin cairia na mesma proteção que a regra dura proíbe contornar.
  **Descartado**.
- **WeFUT.com**: base de dados FC27 UT (20k+ jogadores) publicamente
  visível. **Descartado por dois motivos**: (1) não está na lista de
  parceiros aprovados da EA Community API (só FUT.GG/FUTBIN/FUTWIZ estão);
  (2) `robots.txt` do próprio site declara explicitamente
  `Disallow: /` para crawlers sob Cloudflare — um sinal direto e
  inequívoco de que a automação não deve acessar o conteúdo dele, então
  nem tentamos além de ler o `robots.txt` público.
- **FifaRosters.com / recharge.com / outros agregadores de squad builder**:
  mesma categoria estrutural dos três parceiros — sites comerciais com
  banco de dados UT, sem indicação de licença aberta para os dados, todos
  atrás de proteção anti-bot padrão da indústria. Não investigados a fundo
  individualmente porque o padrão (site comercial de squad builder = dado
  protegido/parceiro EA) já se repetiu em todos os candidatos anteriores.
  A quarta rodada (seção acima) foi além disso e confirmou o mesmo padrão
  também para bases (não só cartas UT): FUTWIZ/WeFUT/SoFIFA bloqueiam
  crawlers por nome no `robots.txt`, o site oficial da EA reserva
  direitos contra scraping/mineração de dados, `fcratings.com` proíbe
  automação no próprio ToS, e `recharge.com` é tecnicamente inconclusivo
  além de ter baixa sustentabilidade como fonte de produto.

**Conclusão final, após quatro rodadas de pesquisa**: não existe hoje
nenhuma fonte gratuita de FC27 — nem carta UT real (`card_type`/rarity),
nem sequer uma base "ratings" alternativa ao dataset FC26 já escolhido —
que passe simultaneamente por robots.txt permissivo, ToS sem proibição de
automação, e sem proteção técnica ativa (Cloudflare challenge). Todo
candidato investigado caiu em pelo menos um desses três filtros. Reavaliar
quando: (a) a EA reabrir o programa de parceiros da Community API; (b)
surgir um dataset estático versionado equivalente ao FC26 escolhido, mas
para FC27 (ainda não existe — o jogo é recente demais); ou (c) um site
novo publicar dados FC27 com robots.txt/ToS que não proíbam automação.

## Estado real do catálogo nesta etapa (correção importante)

**O dataset FC26 (`KAGGLE_ROVNEZ_FC26`) foi pesquisado, documentado e o
importer foi escrito/corrigido para ele — mas o import foi
INTERROMPIDO por decisão consciente do dono do produto antes de escrever
qualquer linha no Supabase.** Nenhum dry-run chegou a rodar contra o CSV
real (o arquivo nunca chegou a existir em `tool/data/` antes da mudança de
direção). O catálogo real de cartas em produção **continua vazio**; as 50
cartas `provider = 'LOCAL'` da Etapa 10 seguem como único conteúdo em
`fc_player_cards`, já com `is_active = false` (aplicado pela migration
`20260918100200_extend_fc_card_catalog.sql`, que já rodou no Supabase
remoto) — ou seja, o picker em produção hoje não retorna nenhuma carta,
por design (nunca mostra `LOCAL` fora de dev), até que uma fonte real seja
importada.

**A Etapa 11 fecha em situação B**, exatamente como definido pelo dono do
produto:

- Arquitetura Conta/Times/Squad corrigida — pronta.
- Schema do catálogo (`fc_clubs`, GK stats, playstyles, `is_active`,
  `game_version`, `card_type`, etc.) — pronto, migrado no Supabase remoto.
- Importer (`tool/sync_fc_cards.dart`) — pronto, com dry-run
  credential-free e mapeamento já ajustado para o schema do dataset FC26
  escolhido (fica como fallback/tooling, não descartado).
- Pesquisa exaustiva de fontes FC27 — documentada nesta rodada e nas três
  anteriores, sete candidatos novos + três anteriores, todos descartados
  com motivo técnico concreto (nunca achismo).
- FUT.GG inviável hoje (robots.txt desautoriza `/api/*`, dado real só via
  client-side JS nessa rota).
- FUTBIN inviável hoje (`HTTP 403` ativo do Cloudflare + ToS explícito).
- FUTWIZ/WeFUT/SoFIFA/EA-oficial/fcratings/recharge — todos verificados e
  descartados nesta rodada, motivo por candidato na tabela acima.
- FC27 UT real: **ainda sem fonte pública adequada** — pendência aberta,
  não forçada.
- FC26 **não foi importado** — decisão consciente do dono do produto, não
  esquecimento nem limitação técnica.
- As 50 cartas `LOCAL` continuam só dev/fallback (`is_active = false` já
  aplicado em produção).
- Etapa 11 está **tecnicamente preparada** (schema + importer + UX
  Conta/Times/Squad + matchmaking multi-time, tudo aplicado e funcionando)
  **mas sem catálogo real FC27** povoado — essa é a limitação externa
  documentada, não um item de trabalho pendente do lado do FIFA Queue.
