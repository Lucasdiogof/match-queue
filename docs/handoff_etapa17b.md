## 2026-09-09 (sessão de validação técnica) — Wrexist snapshot promovido a fonte de trabalho real

**Mudança de decisão do dono do produto, registrada explicitamente**: até a
sessão anterior o Wrexist snapshot era fixture de teste, nunca produção.
Nesta sessão o dono do produto reverteu isso: como o arquivo real "oficial"
da EA ainda não chegou e pode demorar, decidiu **"vamos trabalhar com esses
dados que temos aí"** — o Wrexist snapshot vira fonte de trabalho real
desta etapa, com expectativa de trocar por algo melhor no futuro. Isso não
é uma decisão desta automação, é execução em cima de uma decisão já tomada.

### Decisão de identidade (arquitetura) — registrada para não ser perdida

`FC27_male_players_reconciled.csv`/`FC27_female_players.csv` são ratings
base da EA (uma linha por jogador, sem item id de carta distinto). O
próprio pacote de dados (`FINAL_HANDOFF.md`) documenta que "a tabela
oficial da EA é a base Gold/Silver/Bronze de lançamento" — ou seja, a fonte
SE APRESENTA como base de carta UT, só sem item id numerado à parte (ao
contrário do dataset FC26/SoFIFA da Etapa 11, que nunca se apresentava como
carta UT nenhuma). Decisão:

- `fc_players.provider_player_id` = coluna `player_id` (confirmado idêntico
  a `source_player_id` em 100% das 17.873 linhas — auditoria abaixo).
- `fc_player_cards.provider_card_id` = `"{player_id}:BASE"` — string
  determinística derivada SÓ do id real do jogador na fonte + marcador
  fixo, nunca de nome/rating/índice. `card_type = 'BASE_LAUNCH'`.
- Isso não é "inventar um id" (proibido pelo importer) — é usar o único id
  real que a fonte fornece para a única versão de carta que ela representa.
  Revisitar quando uma fonte com múltiplas versões (Gold/TOTW/Icon) chegar.
- `provider = 'WREXIST_EA_FC27_SNAPSHOT'` (nunca `EA_FC27_RATINGS` — não
  viemos da EA diretamente, viemos de uma republicação de terceiro MIT do
  mesmo endpoint `ea-drop-api`). `game_version = 'FC27'`.

### Parte 2 — Auditoria do arquivo (antes do import)

Arquivo escolhido: `FC27_male_players_reconciled.csv` (tem `game_club_id`/
`game_club_name`/`game_league_id` de reconciliação com clubes do jogo, que
`FC27_male_players.csv` não tem) **combinado com** `FC27_female_players.csv`
(não existe uma variante "reconciled" para feminino — usada como está,
sem os campos de reconciliação de clube, que ficam nulos para essas
linhas). `FC27_community_pack_input.csv` **não foi usado**: é formato
sofifa legado (99 linhas menos que os outros por excluir registros sem
`potential`) e o reconciled já cobre tudo que ele traria, com mais campos.
Script de auditoria: `docs/final_data/scripts/audit_wrexist_reconciled.py`.

Resultado (rodado nesta sessão, sem rede):

| Métrica | male_players_reconciled | female_players |
| --- | ---: | ---: |
| Total de linhas | 16.228 | 1.645 |
| `player_id` distintos | 16.228 (0 duplicados) | 1.645 (0 duplicados) |
| `player_id` != `source_player_id` | 0 | 0 |
| Linhas sem `overall` ou `position` | 0 | 0 |
| Rating fora de 0-99 | 0 | 0 |
| Posições distintas | 12 (todas conhecidas) | 12 (todas conhecidas) |
| Clubes / ligas / nações distintos | 545 / 45 / 156 | 69 / 12 / 72 |
| `club` nulo (sem clube atual) | 2.276 | 126 |
| `source_url` presente | 16.228/16.228 (100%) | 1.645/1.645 (100%) |
| `scraped_at` | `2026-08-28T09:08:58.508Z` (único valor) | idem |

Overlap de `player_id` entre male/female: **0** (namespaces disjuntos,
combinação segura). Total combinado: **17.873**, batendo exatamente com o
total ao vivo da EA confirmado na pesquisa original (`card_provider_research.md`).

**Campo inesperado/ausente mais relevante**: nenhuma das 4 variantes do
snapshot tem coluna de imagem/foto do jogador (`player_face_url` ou
equivalente) — ao contrário do dataset FC26/SoFIFA da Etapa 11, que tinha
`player_face_url`. `player_image_url`/`card_image_url` ficam `NULL` para
todo este import, honesto com a origem (achado de auditoria, não bug).

**Diferença vs. fixtures anteriores (WEFUT/Hall of FUT)**: WEFUT já vinha
com `provider_card_id` próprio (280 cards reais); este snapshot nunca
declara isso — precisou da derivação `{player_id}:BASE` descrita acima.
Hall of FUT não declarava `provider_player_id` nem `provider_card_id`
nenhum (por isso 21/21 inválido no dry-run da Etapa 17B original) — este
snapshot sempre declara `player_id` real.

### Parte 3/4 — Normalização e dry-run completo

Pipeline: `docs/final_data/scripts/build_wrexist_fc27_cards.py` lê os dois
CSVs, deriva `provider_card_id`/`card_type` por linha, escreve
`docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_normalized.csv`
(17.873 linhas, caminho rastreado pelo git — ver nota abaixo sobre
`docs/final_data/output/`). Novo mapeamento de campos:
`docs/final_data/schema/wrexist_ea_cards_map.json` (overrides para as
colunas que diferem do default sofifa do importer: `player_id`, `name`,
`position`/`alternative_positions` já separadas, `physical`, `gk_*`,
`playstyles`, `height`, `club`, `league`, `nationality`).

**Ajuste no importer** (`tool/sync_fc_cards.dart`): adicionado suporte a
`source_url` por linha (antes só existia `--source-url` global via CLI).
A fonte Wrexist traz uma URL real por jogador
(`ea.com/.../ratings?playerId=...`) — sem esse ajuste, perderíamos essa
granularidade real de auditoria por carta. Mudança de 1 linha
(`sourceUrl: col('source_url') ?? options.sourceUrl`) + atualização do
comentário de campos canônicos. `dart analyze tool lib` limpo depois.

Dry-run completo (17.873 linhas, `--provider=WREXIST_EA_FC27_SNAPSHOT
--game-version=FC27 --map=docs/final_data/schema/wrexist_ea_cards_map.json`):

```
lidos: 17873, validos: 17873, invalidos: 0
players (fc_players) distintos: 17873
cards reais (fc_player_cards): 17873
player-only: 0
linhas com posicoes alternativas: 11493
cards -- inseridos: 17873, atualizados: 0, falhas: 0
nations: 157, leagues: 57, clubs: 572
```

Zero inválido, zero JSON malformado, zero aviso de metadata-sem-id — sinal
limpo para prosseguir à amostra.

### Parte 5 — Amostra determinística (ESCRITA EM PRODUÇÃO CONCLUÍDA)

Critério documentado ANTES de rodar: ordenar as 17.873 linhas por
`player_id` numérico ascendente, amostragem sistemática com passo fixo
`stride = 17873 // 40 = 446` (nunca `random()`) — reprodutível, sempre
escolhe os mesmos 40 jogadores contra o mesmo arquivo de entrada. Script:
`docs/final_data/scripts/select_wrexist_sample.py`, saída
`docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_sample40.csv`.

Cobertura da amostra: 11/12 posições (falta só RB), 25 ligas distintas, 25
nações distintas, rating 50-83. Lista completa dos 40 `player_id`
registrada no log da sessão (reproduzível rodando o script). Dry-run da
amostra isolada: 40 lidas, 40 válidas, 0 inválidas, 0 falhas — consistente
com o dry-run do arquivo completo.

**Bloqueador de ambiente (mesmo de sempre) resolvido via caminho
alternativo, com autorização do dono do produto**: este ambiente não tem
`SUPABASE_SECRET_KEY`, então `tool/sync_fc_cards.dart` recusa rodar em modo
de escrita (por design, correto). O dono do produto optou pelo SQL
equivalente ao contrato exato do importer, gerado por
`docs/final_data/scripts/generate_sample_import_sql.py` e aplicado via
`npx supabase db query --linked -f sample_import.sql` (autenticação do
login do CLI, nunca a secret key). **Isso testa o schema/contrato/
idempotência, mas não o código HTTP do `tool/sync_fc_cards.dart` em si**
— quando a secret key existir num ambiente, rodar a ferramenta de verdade
contra o mesmo arquivo normalizado é o próximo passo pra fechar essa
lacuna específica.

**Dois bugs reais encontrados e corrigidos no gerador SQL antes da escrita
ter sucesso** (nenhum dos dois é do importer real, só do script auxiliar):

1. **Clube duplicado por nome em ligas diferentes**: a amostra incluía
   `SV Werder Bremen` em `Bundesliga` E em `GPFBL` (times masculino/
   feminino homônimos) — como `fc_clubs` resolve por nome sozinho, isso
   gerava duas linhas com o mesmo nome e a subquery de resolução de
   `club_id` falhava com `more than one row returned by a subquery used
   as an expression`. Corrigido deduplicando por nome de clube antes de
   gerar o `INSERT`, mantendo a liga alfabeticamente primeira —
   determinístico, documentado, não tenta adivinhar qual liga é "a certa".
2. **`gk_speed` sempre `NULL` sem cast**: nenhuma variante do Wrexist tem
   o stat SPD de goleiro (só diving/handling/kicking/reflexes/
   positioning). Como a coluna inteira da amostra ficava `NULL` em todas
   as 40 linhas, o Postgres não tinha nenhum literal não-nulo pra ancorar
   o tipo da coluna no `VALUES()` e inferia `text`, quebrando contra a
   coluna `integer` real (`column "gk_speed" is of type integer but
   expression is of type text`). Corrigido trocando o literal por
   `NULL::integer` explícito.

**Escrita real confirmada, com verificação direta no banco**:

```
players: 40, cards: 40, active_cards: 40, cards_without_player: 0,
clubs: 32, leagues: 25, nations: 25
```

Amostra de linha (Fran Kirby, maior rating da amostra): `provider_card_id
= "227255:BASE"`, `card_type = "BASE_LAUNCH"`, `club_name = "Brighton"`,
`league_name = "Barclays WSL"`, `nation_name = "England"`, `source_url =
"https://www.ea.com/games/ea-sports-fc/ratings?playerId=227255"` (URL
real, por jogador) — todos os campos conferidos batendo com o CSV de
origem.

### Parte 8 — Idempotência (CONFIRMADA)

Rodei o MESMO `sample_import.sql` uma segunda vez sem nenhuma mudança.
Contagens depois: **idênticas** (`players: 40, cards: 40, active_cards:
40, cards_without_player: 0, clubs: 32, leagues: 25, nations: 25`) — zero
duplicata em `fc_players`/`fc_player_cards`/`fc_clubs`/`fc_leagues`/
`fc_nations`. O `on conflict` do gerador usa exatamente os mesmos índices
únicos reais (`fc_players_provider_idx` e `fc_player_cards` por
`provider,provider_card_id`), então roda seguro repetidamente.

### Parte 6 — Validação do picker via REST (autenticado de verdade)

Não tive Flutter rodando nesta sessão, então validei o caminho que o app
realmente usa: criei 2 usuários de QA reais via `POST /auth/v1/signup`
(nunca inserção direta no banco), peguei o `access_token` de cada um, e
chamei `search_fc_player_cards` via `POST /rest/v1/rpc/...` com esse
token — o mesmo caminho HTTP que o Flutter usa. Confirmado:

- Chamada sem filtro: retorna as 40 cartas reais, cada uma com o objeto
  `fc_player` aninhado (nome, posição, clube, liga, nação), stats
  completos, `playstyles`, `card_type`. **Nenhuma carta `provider=LOCAL`
  aparece** (`providers vistos: {'WREXIST_EA_FC27_SNAPSHOT'}` numa busca
  de até 100 itens).
- Filtro `p_position='CAM'`: retorna só CAMs, com `has_more: true`
  (confirma paginação funcionando).
- Filtro `p_league_name='Bundesliga'`: 5 itens.
- Filtro `p_min_rating=80`: 2 itens (83 e 81) — filtro de rating correto.
- Chamada sem token/anônima continua bloqueada (`FQ003`, já esperado —
  a RPC exige `auth.uid()`).

Os 2 usuários de QA foram deletados ao final
(`delete from auth.users where email like 'qa-fc27-picker%'`) —
confirmado 0 residual. **Não testei a UI do Flutter em si** (seleção de
carta no picker, entrada no squad, overall/chemistry recalculando,
salvar/reabrir squad) — isso continua pendente de uma sessão com o app
rodando de verdade; o que foi validado é que os dados que o Flutter
consome via essa RPC estão corretos e completos.

### Veredito desta rodada (amostra de 40 cartas)

**A — READY FOR SAMPLE-SCALE IMPORT, confirmado.** Auditoria, normalização,
dry-run completo (17.873/17.873), escrita real da amostra, idempotência
(2ª execução idêntica) e picker via REST autenticado — todos passaram.

**Ainda NÃO é veredito para o full import dos ~17.873 registros** — falta
especificamente: (a) rodar `tool/sync_fc_cards.dart` de verdade (não só o
SQL equivalente) quando uma `SUPABASE_SECRET_KEY` estiver disponível num
ambiente, já que o real caminho de produção é essa ferramenta, não o
script gerador de SQL; (b) medir performance a 1 request/linha contra
volume real antes de rodar as ~17.873 linhas inteiras (o gerador de SQL
não tem esse problema por ser um único `INSERT` em lote, mas o importer
real sim); (c) validação de UI Flutter de ponta a ponta (só o dado que a
UI consome foi validado, não a UI em si). **Full import continua exigindo
autorização explícita separada do dono do produto**, como sempre.

### Achado de repositório: `docs/final_data/output/` está no `.gitignore`

O pedido original sugeria `docs/final_data/output/` ou `docs/final_data/data/`
como destinos aceitáveis para os artefatos intermediários. Conferido:
`docs/final_data/output/` está listado no `.gitignore` (linha adicionada
junto com `ea_raw/`), então qualquer arquivo lá NÃO seria versionado.
Usado `docs/final_data/data/wrexist_snapshot_normalized/` em vez disso —
caminho já rastreado pelo git (mesmo padrão de `wrexist_snapshot/`).

---

# Handoff — Etapa 17B (importação real do catálogo FC27)

Status em 2026-09-09: **ainda EM ANDAMENTO, bloqueada exclusivamente pela
ausência do arquivo real da EA.** Segurança corrigida e aplicada (Etapa
17B original + reconfirmada na Fase A), importer adaptado e testado contra
fixtures de teste, HEAD/`origin/main` em `a542d58`, 74/74 migrations. Nesta
sessão: procurei `docs/final_data/data/` inteiro por um arquivo real de
catálogo — **não existe nenhum ainda**, só as fixtures já conhecidas
(`hall_of_fut_21.csv`, `wrexist_snapshot/`) e documentos de instrução
(`FINAL_HANDOFF.md`, `DATA_HANDOFF.md`, `STATUS_2026-09-08.md`).
Nenhuma escrita em produção foi feita, nenhum dry-run novo rodou (não há
dado real pra rodar contra). Fase A (bloqueadores de lançamento) e Privacy/
Termos/CI-CD **já foram feitos em paralelo por outra etapa**, não estão
mais bloqueados por esta.

## 2026-09-09 — achados desta sessão (sem arquivo real disponível)

1. **`FINAL_HANDOFF.md`/`DATA_HANDOFF.md` trazem instruções mais
   específicas que a v1 deste handoff** (escritas por quem preparou o
   pacote de dados, não por automação): total oficial da EA hoje é
   **20.689** (não mais 17.873 — a EA parece ter expandido a tabela entre
   a Etapa 17B original e agora), provider sugerido `EA_FC27_RATINGS`,
   `card_type='BASE_LAUNCH'` pro item base, Hall of FUT como
   `card_type='HALL_OF_FUT'` em provider/item **separado** (nunca fundido
   ao player base), refresh obrigatório após 2026-09-10 (a EA anunciou
   atualização de PlayStyles nessa data) antes de considerar qualquer
   snapshot anterior "release candidate". `card_type` é campo de texto
   livre no schema (sem `CHECK`/enum) — `'BASE_LAUNCH'`/`'HALL_OF_FUT'`
   já passam sem nenhuma migration nova.
2. **Ambiguidade genuína documentada, não resolvida** (por instrução
   explícita: não forçar decisão sem o dado real): `schema/
   supabase_mapping.json` sugere que, pra ratings base da EA sem item id
   próprio, `provider_item_id` (→ `provider_card_id`) **pode igualar**
   `provider_player_id`. Isso esbarra na regra já endurecida do importer
   ("nunca inventar `provider_card_id` a partir de player id/nome/rating/
   índice"). A diferença é sutil: se o endpoint real da EA de fato só
   devolve um id por jogador (sem id de item distinto), usar esse mesmo id
   como identidade da carta não é "inventar" — é o único id externo real
   que existe pra aquele registro. Mas isso só pode ser confirmado
   olhando o payload real; **decisão fica pendente até o arquivo chegar**,
   documentada aqui pra não ser esquecida nem decidida às pressas.
3. **Achado de repositório — RESOLVIDO por decisão explícita do dono do
   produto (2026-09-09)**: as fixtures WEFUT (`legacy_samples/`) já
   estavam commitadas desde uma sessão anterior; o Wrexist snapshot
   (~19MB de CSV) estava gitignorado. O dono do produto decidiu
   explicitamente que **todo dado deste projeto pode ser commitado e
   versionado por inteiro** — é um projeto de resenha, sem pretensão
   comercial, e não há razão pra manter esses arquivos fora do histórico.
   `.gitignore` atualizado (commit `ad058e4`): removidas as exclusões de
   `docs/final_data/data/*.json` e `.../wrexist_snapshot/`; o snapshot
   inteiro foi commitado e pushado. **Único dado que continua fora do
   git, deliberadamente**: um eventual dump bruto vindo direto da EA em
   `docs/final_data/data/ea_raw/` — é a única fonte com reserva de
   direitos explícita contra mineração automatizada de dados no robots.txt
   dela, então mantém tratamento à parte independente da liberação geral
   acima (não é uma questão de "dado de resenha", é o `ea.com` proibindo
   isso especificamente). Se/quando esse arquivo chegar, resolver então.
4. `docs/final_data/data/ea_raw/` continua corretamente gitignorado (ver
   `.gitignore`) — nada novo precisou ser adicionado, `git status` sem
   saída (árvore limpa).

## 1. Dataset fornecido

O que o usuário entregou não é o catálogo completo (ele mesmo corrigiu essa
ambiguidade no meio da etapa) — é pesquisa/pipeline prontos mais duas
fixtures pequenas, tudo em `docs/final_data/` (commits `1014677`,
`aeffe7c`, `33efee9`):

- `sources/source_manifest.json` + `source_matrix.csv` — mapeamento de
  fontes (EA oficial tier-1, FUT Forge/FCData tier-2, Wrexist snapshot
  tier-3), com o total oficial da EA em 2026-09-08 (20.689 itens
  Gold/Silver/Bronze, masculino+feminino) e a atualização de PlayStyles
  anunciada pela própria EA para 2026-09-10.
- `schema/fc27_normalized_schema.json` + `supabase_mapping.json` — contrato
  de campos EA → `fc_players`/`fc_player_cards`.
- `scripts/fetch_ea_fc27.py`, `normalize_ea_fc27.py`, `validate_fc27.py`,
  `build_supabase_payloads.py`, `refresh_after_sep10.{sh,ps1}` — pipeline
  Python completo, nunca executado em massa (ver seção 3).
- `legacy_samples/fc27_players_45_legacy.csv` (45 linhas) e
  `fc27_cards_280_legacy.csv` (280 linhas) — **`source_provider = WEFUT`**,
  explicitamente rotuladas pelo próprio pacote como amostra/legado, nunca
  como dataset completo.
- `data/hall_of_fut_21.csv` (21 linhas) — **`source_provider = FCDATA`**,
  cartas especiais curadas, com uma discrepância de rating documentada
  (Giovani dos Santos: 84 no artigo de reveal vs. 80 na listagem ao vivo,
  preservada sem resolver).

**Decisão explícita do usuário sobre as duas fixtures**: nenhuma das duas
entra como catálogo de produção. `WEFUT_PRODUCTION_IMPORT = NO`,
`HALL_OF_FUT_PRODUCTION_IMPORT = NO`, ambas ficam só como fixture de teste
de pipeline (`is_active = false` se algum dia forem escritas no banco, o
que não aconteceu nesta etapa — tudo foi `--dry-run`).

## 2. Segurança (item 0) — CORRIGIDO E APLICADO

Confirmado direto no schema remoto (via `pg_policies` e
`information_schema.role_table_grants`, não só nas migrations locais):
`fc_players` e `fc_player_cards` tinham `select using (true)` para
`authenticated`, sem filtrar `is_active` — mesmo a RPC
`search_fc_player_cards` já filtrando desde a Etapa 11. Qualquer client
autenticado lia carta/jogador inativo direto via PostgREST.

Corrigido na migration `20260926100000_fc_catalog_active_only_select.sql`
(commit `a70011b`, aplicada e verificada no remoto): as duas policies
viraram `using (is_active = true)`. Optei por essa correção (não por
revogar o grant e forçar tudo por RPC) porque
`SupabasePlayerCardCatalogRepository.getCard` (features/fc_squads) lê
`fc_player_cards` direto por id via `.from()` — é um read model legítimo
que continua funcionando sem nenhuma mudança no Flutter.

Achado extra, documentado mas não corrigido (provavelmente inofensivo):
`authenticated` também tem grants de `REFERENCES`/`TRIGGER`/`TRUNCATE`
nas duas tabelas — padrão de default privileges do Supabase aplicado a
toda tabela nova em `public`, não algo que a migration pediu. Não é
explorável via PostgREST/RPC (o único caminho que o app usa).

## 3. A fonte EA — por que não foi buscada automaticamente

Testei manualmente (chamadas mínimas, nada persistido) e o endpoint que
funciona de verdade é:

```
https://drop-api.ea.com/rating/ea-sports-fc?locale=en&limit=100&offset=0
```

(o slug `ea-sports-fc-27` do pacote está desatualizado, devolve 204 vazio).
`totalItems` reportado em 2026-09-08: **17.873**. Resposta real confirmada
(Salah, overall 91, `campaignOverview` diz "FC 27 Ratings | FUT").

Antes de baixar em massa, `robots.txt` de `ea.com` foi conferido e tem uma
reserva de direitos explícita:

> "Any use of such content for the development, training, programming,
> improvement and/or enhancement of artificial intelligence... web
> scraping... or any form of text or data mining, is prohibited, unless
> specifically and explicitly authorized in writing by Electronic Arts."

Isso já tinha sido encontrado e documentado na pesquisa original da Etapa
11 (`docs/card_provider_research.md`, linha da tabela sobre `ea.com`) —
esta etapa só reconfirmou ao vivo antes de agir. Consistente com a decisão
permanente já tomada sobre WeFUT/SoFIFA (recusa por robots.txt, não
reaberta por pedido do usuário — é sobre o que a automação deve acessar),
o fetch em massa não foi executado por automação.

**Acordado com o usuário**: ele baixa manualmente (navegador com DevTools,
ou rodando o comando abaixo NO TERMINAL DELE, nunca por automação) e
entrega o resultado em `docs/final_data/data/` (ignorado pelo git — ver
`.gitignore`):

```bash
python3 docs/final_data/scripts/fetch_ea_fc27.py \
  --base https://drop-api.ea.com/rating/ea-sports-fc \
  --out docs/final_data/data/ea_raw
```

## 4. Importer (`tool/sync_fc_cards.dart`) — adaptado e testado

Auditado (não reescrito). Três correções reais, motivadas pelos dados de
verdade das fixtures, não hipotéticas:

1. **Posições em colunas separadas**: o importer só sabia derivar
   `primary_position`/`alternative_positions` de uma lista combinada num
   único campo (estilo sofifa, "ST, LW, CF"). WEFUT (e o payload da EA,
   confirmado na sondagem da seção 3: `position.shortLabel` +
   `alternatePositions[].shortLabel`) já vêm com as duas em colunas
   distintas. Agora detecta automaticamente qual caso é (mesma coluna
   resolvida = combinado; coluna de alternativas ausente no arquivo =
   também cai pro combinado, nunca quebra silenciosamente) e lê cada uma
   corretamente. Verificado contra dado real: 5/280 cards da fixture têm
   posição alternativa, e o dry-run agora reporta exatamente 5.
2. **`detailed_stats`/`playstyles_plus`/`raw_metadata`**: a fixture real
   trouxe subatributos aninhados (`{"pace":{"acceleration":73,...}}`) e
   `raw_provider_data` como JSON serializado por célula — nada no schema
   tinha onde guardar isso. Migration aditiva
   `20260926100100_fc_card_detailed_stats.sql` (commit `aeffe7c`, aplicada)
   adicionou `detailed_stats jsonb`, `playstyles_plus text[]`,
   `accelerate_rate text` a `fc_player_cards` (`raw_metadata` já existia
   desde a Etapa 11, só nunca populado). `_fc_card_json` foi atualizado
   (CREATE OR REPLACE) para expor os três primeiros — `raw_metadata`
   fica de propósito fora do payload do cliente, é campo de debug/backend.
3. **`--full-catalog`**: antes, qualquer sync sem `--dry-run` desativava
   automaticamente toda carta daquele provider ausente da rodada — um
   arquivo parcial apagaria o resto do catálogo por engano. Agora
   `deactivateMissing` só roda com `--full-catalog` explícito; default é
   não desativar nada.

Commit `33efee9` (código) + `aeffe7c` (migration), ambos em `origin/main`.
`dart analyze tool/` — **No issues found** depois das três mudanças.

## 5. Dry-run contra as fixtures (nunca produção)

Mapeamentos de campo em `docs/final_data/schema/{wefut_players,wefut_cards,
hall_of_fut}_map.json`.

**Players WEFUT** (45 linhas): 45 válidas, 45 `fc_players` distintos, 0
cards (arquivo é só identidade base, sem `provider_card_id` — correto).

**Cards WEFUT** (280 linhas): 280 válidas, 280 cards reais, 45 players
distintos (bate exatamente com o arquivo de players — 100% de vínculo
`provider_player_id` resolvido, confirmado também via auditoria Python
cruzada). 5 linhas com posição alternativa. 0 avisos de JSON malformado, 0
metadata-sem-id. Zero linha FC26 (100% `game_version=FC27`). Zero rating
fora de 0-99. Zero `provider_item_id` duplicado. 12 posições distintas, **
todas conhecidas** (nenhuma posição desconhecida pra reportar). 29 cards de
GK, corretamente sem stats de linha na própria fonte (e o importer força
isso de qualquer forma, por código, independente do dado de entrada).
**0 players com 2+ cards** nesta amostra específica — a arquitetura suporta
(schema + `fc_player_id` já provados noutras etapas), mas esta fixture não
contém nenhum exemplo real de Mbappé-com-3-cartas; reportado com
honestidade em vez de forçar um exemplo.

**Hall of FUT** (21 linhas): **0 válidas, 21 inválidas** — o arquivo não
declara `provider_card_id`/`provider_item_id` nem `provider_player_id`
nenhum, só nome+ratings. Pelo contrato do importer (nunca sintetizar id a
partir de nome/rating/índice), isso é o comportamento CORRETO, não um bug:
sem identidade externa real, não há upsert idempotente possível. Fica
registrado como achado de auditoria, não como algo a "consertar" — consertar
exigiria inventar um id, que é exatamente o que a regra proíbe.

**Condições de abort (item 33) — nenhuma disparada** nas fixtures WEFUT:
perda de `provider_card_id` 0% (limite era 1%), `game_version` nunca
misturada, parsing produziu 45 players (não zero), rating/posição não
vazios em massa, relação player/card 100% coerente, GK sem contaminação de
stats de linha.

## 5b. Segunda fixture, escala real (Wrexist/dynasty-manager, GitHub)

O usuário depois trouxe 4 CSVs de `github.com/Wrexist/dynasty-manager`
(commit `0fa46443...`, MIT, sem `robots.txt` restritivo — baixados
por automação sem problema, ao contrário de EA/WeFUT): 16.228 players
masculinos + 1.645 femininos + 16.129 (`community_pack_input`, formato
sofifa) + a versão "reconciled" dos masculinos. Todos os 4 baixados e
validados byte-a-byte contra o manifesto (`git_blob_sha1` batendo 4/4) —
`docs/final_data/data/wrexist_snapshot/` (gitignored, nunca commitado).

**Auditoria revelou proveniência real**: toda linha declara
`source=ea-drop-api`, `source_url=ea.com/.../ratings?playerId=...` e
`scraped_at=2026-08-28` — é uma republicação de terceiro do mesmo endpoint
da EA identificado na seção 3, feita 11 dias atrás por quem mantém o
repositório, não pela EA nem por automação. Total masculino+feminino
(17.873) bate exatamente com o total ao vivo da EA hoje. `potential` é
`FC26_20250921-carryover` em 16.129/16.228 linhas — rotulado
honestamente, nunca fabricado, mas nosso schema não tem coluna
`potential` mesmo, então isso não entra em lugar nenhum.

**Decisão do usuário, consistente com a de WEFUT**: tratar como fixture de
teste também, não como catálogo de produção — mesmo risco de proveniência
(dado reservado da EA, redistribuído sem autorização explícita dela).

Mapeamentos novos: `docs/final_data/schema/wrexist_ea_players_map.json`
(masculino/feminino/reconciled) e `wrexist_community_pack_map.json`
(`community_pack_input`, formato sofifa — só precisou de 1 override,
`provider_player_id -> player_id`, o resto já batia com o default do
importer). Dry-run em escala real, primeira vez testando > 100 linhas:

| Arquivo | Linhas | Válidas | Alt. positions | Nations/Leagues/Clubs |
| --- | ---: | ---: | ---: | --- |
| male_players | 16.228 | 16.228 | 10.485 | 156 / 45 / 545 |
| female_players | 1.645 | 1.645 | 1.008 | 72 / 12 / 69 |
| community_pack_input | 16.129 | 16.129 | 10.422 | 156 / 45 / 545 |

Parse de 16k linhas em ~1.5s (dry-run, sem chamada de rede). Zero posição
desconhecida, zero `player_id` duplicado. GK do arquivo bruto às vezes traz
`pace`/`shooting` preenchidos junto com `gk_diving`/`gk_handling` — o
importer já neutraliza isso por código (`isGoalkeeper ? null : ...`),
independente da higiene da fonte.

## 6. O que NÃO foi feito nesta etapa (limite deliberado)

- **Nenhuma escrita real no Supabase** a partir das fixtures — só
  `--dry-run`. Itens 34-44 do pedido original (sample import real, picker,
  card detail, chemistry, squad builder contra dado real) ficam pendentes
  até o arquivo real da EA chegar, porque escrever as fixtures WEFUT/Hall
  of FUT no banco de produção contradiria a decisão explícita do usuário.
- **Performance/batch (itens 49-53)**: o importer segue fazendo 1 request
  HTTP por linha (mais 1 por clube/liga/nação novo visto). Para 280 linhas
  isso é trivial; para os ~17.873 itens reais da EA, vale revisar antes do
  full import — não foi feito agora porque não havia arquivo real pra medir
  contra, e otimizar sem medir é prematuro. Fica como próximo passo
  explícito quando o arquivo chegar.
- **Clubs/leagues/nations upsert-by-name** (itens 9-11): a lógica já existe
  no importer (`upsertByName`) e não foi tocada, mas só é exercida em modo
  não-dry-run (precisa de credencial) — não testada nesta etapa pelo mesmo
  motivo do item anterior.

## 7. Próximo passo

1. Usuário baixa o catálogo real (seção 3) e coloca em
   `docs/final_data/data/ea_raw/` (gitignored).
2. Rodar `python3 docs/final_data/scripts/normalize_ea_fc27.py` e
   `validate_fc27.py` sobre o resultado (ou adaptar o mapeamento direto
   pro `tool/sync_fc_cards.dart` se o formato já vier compatível — auditar
   na hora).
3. `dart run tool/sync_fc_cards.dart --file=... --provider=EA_FC27_RATINGS
   --game-version=FC27 --map=... --dry-run` contra o arquivo real completo.
4. Se os números baterem com os ~17.873-20.689 esperados, rodar sample
   (100-200 linhas representativas) sem `--dry-run`, validar no Supabase
   (picker, card detail, chemistry, squad), depois rodar o resto sem
   `--full-catalog` na primeira vez (nunca desativar nada às cegas), e só
   usar `--full-catalog` quando tiver certeza de que o arquivo representa
   o catálogo completo daquela rodada.
5. Reavaliar performance/batch se o import de ~18-20k linhas demorar
   demais linha-a-linha.
6. Atualizar `docs/handoff.md` e fechar a Etapa 17B de verdade.
