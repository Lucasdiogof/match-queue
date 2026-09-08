# Handoff — Separação Jogador/Carta (fc_players vs fc_player_cards)

Status em 2026-09-08: **banco e Flutter escritos, commitados e pushados em
`origin/main`**. A migration nova foi aplicada no Supabase remoto de
primeira via `npx supabase db push` (sem erro de SQL) e `supabase migration
list` confirma 56 migrations locais = 56 remotas.

## Escopo desta sessão

Esta etapa é **100% arquitetura interna**: modelagem de banco, domínio
Flutter e importer, para que o catálogo de cartas passe a distinguir
"atleta base" (Mbappé) de "carta/item específico" (Mbappé Gold, Mbappé
TOTW, Mbappé TOTS...). **Nenhum coletor/scraper contra WeFUT, FUT.GG,
FUTBIN, FUTWIZ ou qualquer site externo foi criado** — a decisão de não
usar WeFUT (robots.txt desautoriza crawlers automatizados) já tinha sido
tomada e comunicada na Etapa 11 e não foi reaberta. O importer continua
lendo só arquivo local (CSV, e agora também JSON), nunca rede.

## Banco

Migration nova: `supabase/migrations/20260920100000_fc_players_split.sql`
(nenhuma migration antiga foi editada).

### Tabela `fc_players`

Atleta base, provider-agnostic (mesmo padrão de `fc_nations`/`fc_leagues`/
`fc_clubs`/`fc_managers`):

- PK `id uuid`. Origem em `(provider, provider_player_id)`, nunca a PK.
- `provider_player_id` **nullable** com índice único parcial
  `(provider, game_version, provider_player_id) where provider_player_id is
  not null` — mesmo padrão dos outros catálogos: uma linha manual/LOCAL sem
  id externo não precisa de identidade externa nenhuma.
- `nation_id`/`club_id`/`league_id` referenciam as tabelas já existentes
  (`on delete set null`).
- `primary_position`/`alternative_positions`/`image_url`/`height_cm`/
  `preferred_foot`/`weak_foot`/`skill_moves`/`raw_metadata` — mesmo
  vocabulário de `fc_player_cards`, sem duplicar os campos que são
  exclusivamente de carta (rating, stats PAC/SHO/..., card_type, rarity,
  playstyles, player_roles, imagens de carta).
- Constraints de `weak_foot`/`skill_moves`/`preferred_foot` espelham as que
  já existiam em `fc_player_cards` (Etapa 11).
- RLS habilitada: `select` para `authenticated`, sem policy de
  insert/update/delete (escrita só pelo importer com a secret key, que
  ignora RLS — mesmo padrão do resto do catálogo). `revoke all from anon`.

### `fc_player_cards` ganha `fc_player_id`

- Coluna nova `fc_player_id uuid references fc_players(id) on delete set
  null`, **nullable**. Índice parcial `where fc_player_id is not null`.
- `_fc_card_json` (mesma assinatura, só o corpo mudou via `create or
  replace`) ganha dois campos aditivos: `fc_player_id` e um objeto aninhado
  `fc_player` (`id`, `name`, `common_name`, `primary_position`,
  `image_url`, `nation_name`, `club_name`, `league_name`), `null` quando a
  carta não tem player vinculado. Nenhum campo existente mudou de nome ou
  tipo — quem já lê o JSON da carta continua funcionando sem alteração.
- `search_fc_player_cards` **não mudou de assinatura** — ela chama
  `_fc_card_json` internamente, então o campo novo já sai de graça sem
  precisar de `drop`/`create` (o cuidado da Etapa 11 com "`create or
  replace` trocando nome de parâmetro" não se aplica aqui: nenhum parâmetro
  de nenhuma função mudou nesta migration).

## Compatibilidade — nada quebrou

- **As 50 cartas `provider = 'LOCAL'` (Etapa 10, já `is_active = false`
  desde a Etapa 11) ficam com `fc_player_id = null`.** Decisão consciente
  (opção "a" das duas que o pedido oferecia): são dado de desenvolvimento,
  já fora de qualquer busca em produção — criar 50 `fc_players`
  correspondentes só adicionaria linhas sem uso real. Documentado também em
  `comment on column` na própria migration.
- **`fc_squad_slots`**: a FK para `fc_player_cards.player_card_id` não
  mudou — `fc_player_cards.id` continua a mesma PK de sempre. Squads
  existentes continuam funcionando sem nenhuma migração de dado.
- **`game_matches.squad_snapshot`**: imutável, como sempre — esta migration
  não toca em nenhuma linha de `game_matches`, nenhuma função que gera ou lê
  snapshot foi alterada (`_fc_squad_snapshot` continua igual). Partidas
  antigas continuam legíveis exatamente como estavam.
- **`game_match_player_stats`/`upsert_game_match_player_stats`/
  `get_game_match_details`` (Etapa 12)**: nenhuma delas foi tocada. Elas já
  validam contra `squad_snapshot` congelado, nunca contra o catálogo vivo —
  exatamente o desenho que a Etapa 12 documentou como resiliente a mudança
  de catálogo. Conferido lendo `20260919100000_game_match_player_stats.sql`
  antes de começar: nenhuma referência direta a `fc_player_cards` fora do
  snapshot.

## Domain Flutter

- `FcPlayer` novo em
  `lib/features/fc_squads/domain/entities/fc_player.dart` — entidade
  separada, carrega só os campos que a RPC devolve embutidos (`id`, `name`,
  `commonName`, `primaryPosition`, `imageUrl`, `nationName`, `clubName`,
  `leagueName`). `displayName` segue a mesma convenção de `PlayerCard`
  (`commonName ?? name`).
- `PlayerCard` (`lib/features/fc_squads/domain/entities/player_card.dart`)
  ganhou `fcPlayerId` (`String?`) e `player` (`FcPlayer?`), ambos opcionais
  — nenhum campo existente mudou. O picker continua 100% card-centric
  visualmente; isto é metadata adicional que nenhuma tela ainda consome.
- `FcSquadModel.cardFromJson`
  (`lib/features/fc_squads/data/models/fc_squad_model.dart`) parseia os
  dois campos novos (`fc_player_id`, `fc_player`) via um `_playerFromJson`
  novo, mesmo padrão de `clubFromJson`/`leagueFromJson`.
- `flutter analyze` limpo (rodei escopado em `fc_squads` e depois no
  projeto inteiro).

## Importer (`tool/sync_fc_cards.dart` + `tool/fc_import_contract.dart`)

### Contrato de normalização

`tool/fc_import_contract.dart` (novo, só usado pelo importer — nunca
importado pelo app Flutter) declara:

- `ExternalFcPlayer` — atleta base normalizado (`provider`,
  `providerPlayerId`, `gameVersion`, `name`, `commonName`, refs de
  nação/clube/liga por nome, posição, imagem, altura, pé, etc.) com
  `toFcPlayersRow(...)` que produz a linha pronta pra upsert em
  `fc_players` (recebe os ids já resolvidos de nação/clube/liga — a classe
  nunca fala com o banco).
- `ExternalFcCard` — carta normalizada, com `providerPlayerId` nullable
  linkando de volta ao jogador e `toFcPlayerCardsRow(...)` (mesma ideia).

**Correção de semântica, em duas rodadas (revisão do dono do produto,
depois da primeira versão desta etapa)**:

1. A primeira versão ainda criava uma linha em `fc_player_cards` com
   `card_type = 'BASE_DATASET'` para todo item sem sinal de carta real —
   "compatibilidade com o picker" que deixou de ser necessária justamente
   porque `fc_players` passou a existir. **Removido.**
2. A segunda versão passou a considerar `card_type`/`rarity` sozinhos
   como "sinal de carta real" (mesmo sem `provider_card_id`) — **endurecido
   de novo**: `card_type`/`rarity` são ATRIBUTOS da carta, não identidade.
   Sem uma chave externa (`provider_card_id`) não existe forma idempotente
   de upsertar, então **regra final: `fc_player_cards` exige
   `provider_card_id` explícito e não-vazio; `card_type`/`rarity` sozinhos
   NÃO criam carta.** Um item com `card_type` mas sem `provider_card_id`
   vira `player-only` (só `fc_players`), com um aviso de diagnóstico no
   resumo do `--dry-run` ("card metadata sem identidade") — não é erro,
   só um sinal de que a fonte parece descrever cartas sem dar id pra elas.
   Nunca inventamos um `provider_card_id` sintético (a partir de player
   id, nome, rating ou índice de linha) para contornar isso.

Regra definitiva: uma linha só vira `fc_player_cards` quando o input
declara `provider_card_id` próprio — sem isso, o importer faz upsert
**somente** em `fc_players` e nunca cria (nem inventa) uma carta.
`isBaseDatasetOnly()` foi removido de `ExternalFcCard`; a decisão "isto é
carta ou só jogador" agora é tomada em `sync_fc_cards.dart` **antes** de
`ExternalFcCard` ser sequer construído. `toFcPlayerCardsRow()` também não
tem mais o fallback `cardType ?? 'BASE_DATASET'` — `card_type` fica `null`
quando a fonte não declarou, ponto.

Efeito prático: o dataset FC26/SoFIFA já pesquisado (`sofifa_id` identifica
o ATLETA, não uma versão de carta — nunca teve `provider_card_id` de
verdade) agora importa **somente** para `fc_players`, zero linhas novas em
`fc_player_cards`. Corrigido também o mapeamento default de CSV, que
antes apontava `sofifa_id` para `provider_card_id` (errado — é identidade
de jogador) e agora aponta para `provider_player_id`.

Nenhuma lógica de provider específico (nomes de coluna do FC26-DataHub,
convenções do WeFUT, etc.) vaza para essas duas classes nem para o banco —
fica isolada no passo de mapeamento de campos do importer.

### Fluxo

`payload externo (CSV ou JSON local) → col()/colInt()/colList() aplicam o
mapeamento de campos → ExternalFcPlayer/ExternalFcCard → (se
provider_player_id presente) upsert fc_players, pega o id → upsert
fc_player_cards com fc_player_id resolvido (nulo se não havia
provider_player_id)`.

### Formato de input

- `--file=<path>` é a forma genérica nova — formato inferido pela extensão
  (`.json` → JSON, qualquer outra coisa → CSV), com `--format=csv|json`
  para forçar.
- `--csv=<path>` continua aceito (forma antiga, equivalente a
  `--file=<path> --format=csv`) — nada quebrou para quem já tinha essa
  sintaxe na cabeça.
- CSV: mapeamento default no estilo FC26-DataHub/SoFIFA, igual a Etapa 11
  (o único dataset já pesquisado). JSON: mapeamento default **identidade**
  — um arquivo JSON já deveria usar os nomes canônicos direto (é o formato
  pensado para "qualquer fonte futura", sem assumir convenção de coluna
  nenhuma). `--map=<path.json>` sobrescreve em ambos os formatos.
- Campo novo mapeável: `provider_player_id`. Sem override e sem default (o
  dataset FC26-DataHub/SoFIFA já pesquisado não distingue jogador de carta,
  então CSV não ganhou default pra isso), cai no nome literal
  `provider_player_id` — ou seja, um CSV com essa coluna funciona sem
  `--map`, e um CSV sem ela preserva o comportamento antigo inteiro
  (`fc_player_id` sempre `null`).
- Comando genérico final:
  `dart run tool/sync_fc_cards.dart --file=<path> --provider=<nome>
  [--game-version=...] [--format=csv|json] [--map=...] [--dry-run]` — o
  importer nunca sabe nem se importa se a origem foi um dataset comunitário,
  um export manual ou qualquer outra coisa.

### Preservado sem mudança de comportamento

- `--dry-run` continua credential-free de verdade (não instancia
  `_SupabaseAdmin`, não toca Supabase).
- `SUPABASE_SECRET_KEY` principal, `SUPABASE_SERVICE_ROLE_KEY` como
  fallback legado — nunca logado, nunca hardcoded.
- Nunca deleta: `deactivateMissing` continua só marcando
  `is_active = false` (generalizei o helper para aceitar qualquer
  `idColumn`, já que agora existe `fetchExistingProviderIds`/
  `deactivateMissing` genéricos em vez de hardcoded para
  `provider_card_id` — usados hoje só para cartas, mas prontos para
  `fc_players` se um dia precisar do mesmo tratamento).
- Contadores refeitos para a distinção player/card: `lidos`, `válidos`,
  `inválidos`, `players (fc_players) distintos` (deduplicados por chave
  `provider:game_version:provider_player_id`, contados uma vez mesmo que
  o mesmo atleta apareça em N linhas/cartas), `cards reais
  (fc_player_cards)`, `player-only (só fc_players)`, um aviso de
  diagnóstico opcional (`card metadata sem identidade`, quando
  `card_type`/`rarity` aparece sem `provider_card_id` — não é erro, só
  mostra que a fonte parece descrever cartas sem dar id pra elas), e
  `inseridos/atualizados/falhas` (esses três só contam cards, já que
  linha player-only nunca toca `fc_player_cards`).
- **Regra final, endurecida na segunda revisão**: `fc_player_cards`
  requires an explicit `provider_card_id`; `card_type`/`rarity` alone do
  not create a card. Validado com três testes manuais via `--dry-run`
  (nunca tocou o Supabase): (1) CSV sofifa-style puro → `players: 1, cards
  reais: 0, player-only: 1`; (2) JSON com `card_type` presente mas SEM
  `provider_card_id` → `players: 1, cards reais: 0, player-only: 1` + o
  aviso de diagnóstico contando 1; (3) JSON com `provider_card_id`
  presente (sem `card_type`) → `players: 1, cards reais: 1, player-only:
  0`. Os três batem exatamente com a regra: só `provider_card_id` cria
  carta, `card_type`/`rarity` sozinhos nunca bastam.
- `dart analyze tool` limpo, `dart format tool` aplicado.

## Segurança

- `fc_players`: `select` para `authenticated`, `revoke all from anon`, sem
  policy de escrita — igual todo o resto do catálogo.
- Nenhum grant de insert/update para `authenticated` em nenhuma tabela
  tocada nesta migration. Escrita só via importer com a secret key
  server-side.

## Git

Commits desta sessão (mais recente primeiro), todos em `origin/main`:

```
ecf9653 Let the card importer resolve a base player from any local file
b27f863 Add FcPlayer as a separate entity from PlayerCard
c3f1693 Split player identity from card version in the FC catalog schema
```

`git status` limpo além de `.agents/`/`skills-lock.json` (tooling, nunca
commitado). `flutter analyze` e `dart analyze tool` limpos. `dart format
lib`/`dart format tool` aplicados. A migration desta sessão está aplicada no
Supabase remoto — `supabase migration list` confirma 56 locais = 56
remotas.

## Pendências conscientes / fora de escopo

- Nenhum dataset real foi importado nesta sessão — a pendência de "catálogo
  real de cartas FC27/FC26 vazio" segue exatamente como a Etapa 11 fechou
  (situação B, externa, documentada em `docs/card_provider_research.md`).
  Esta etapa só prepara a modelagem/importer para aceitar
  `provider_player_id` quando uma fonte futura o declarar.
- Nenhuma tela nova consome `PlayerCard.player`/`fcPlayerId` ainda — por
  desenho explícito do pedido ("não mude a UX visual do picker agora").
  Fica pronto para quando existir necessidade real (ex.: agrupar cartas do
  mesmo jogador, mostrar "outras versões deste jogador").
- Consolidação de identidade entre providers diferentes para o mesmo atleta
  (ex. o mesmo Mbappé vindo de dois datasets distintos) não é modelada —
  cada `(provider, game_version, provider_player_id)` é uma linha própria
  em `fc_players`, igual ao resto do catálogo já fazia para nação/liga/
  clube.
- Nenhum coletor externo foi implementado ou pesquisado nesta sessão —
  fora de escopo por instrução explícita.

## Pronto para a próxima etapa?

Sim: migration aplicada no remoto sem erro, `flutter analyze` limpo,
`dart analyze tool` limpo, squads/snapshots/stats da Etapa 12 confirmados
intactos por leitura de código antes de qualquer mudança. Não avancei para
nenhum coletor de dados nem reabri pesquisa de provider, conforme
instruído.
