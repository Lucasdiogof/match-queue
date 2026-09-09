# Handoff — Etapa 17B (importação real do catálogo FC27)

Status em 2026-09-08: **segurança corrigida e aplicada, importer adaptado e
testado contra fixtures de teste; catálogo real de produção ainda NÃO
importado** — falta o arquivo, que precisa ser baixado manualmente (ver
seção 3). Não avançar para as etapas de Privacy/Termos/CI-CD ainda; esta
etapa para aqui até o arquivo real chegar.

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
