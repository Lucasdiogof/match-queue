# Handoff — Etapa 11 (Conta/Times/Jogar redesenhados + catálogo de cartas real)

Status em 2026-09-08: **backend e Flutter escritos e commitados/pushados em
`origin/main`** (`flutter analyze` limpo em todo o lote). **As 3 migrations
desta etapa foram aplicadas no Supabase remoto** (via `npx supabase db
push`, numa sessão seguinte que tinha o CLI disponível por `npx`) —
`supabase migration list` confirma as 55 migrations locais batendo com as
55 remotas. Duas correções de SQL precisaram entrar no meio do caminho (ver
"Correções de SQL encontradas ao aplicar" abaixo) — nenhum dado foi
perdido, o CLI reverte sozinho a migration que falha. **O catálogo real de
cartas ainda não está populado** — ver "Pendências" no final.

## Correção conceitual (Elenco → Conta, Conta → Times, Conta → Squad)

- Todo texto visível ao usuário que dizia "Elenco"/"Elencos" agora diz
  "Conta"/"Contas" (pt), "Account/Accounts" (en, já estava certo), "Cuenta/
  Cuentas" (es) — nomes de classe (`FcAccount`), tabela (`user_fc_accounts`)
  e chaves de l10n (`fcAccountXxx`, `pendingMatchElencoLabel`,
  `historyElencoLabel`) ficaram **intocados** de propósito: são
  identificadores internos, não texto de usuário, e renomeá-los seria
  migração cara sem ganho.
- Concordância de gênero em pt/es foi revisada linha a linha depois do
  replace automático ("um conta" → "uma conta", etc.) — `git diff
  67913f1^..67913f1` mostra o antes/depois se precisar conferir.
- Conta → Times já era N:N (`fc_account_teams`, desde a Etapa 9) — item 2 do
  pedido já estava satisfeito, nenhuma migration nova foi necessária aqui.
- Conta → Squad principal (`is_default`) também já existia inteiro desde a
  Etapa 10 (`fc_squads.is_default`, RPC `set_default_squad`, UI already
  showing "Squad: Principal · 4-3-3" com "Alterar" secundário) — Parte D
  item 8 estava, na prática, pronta antes desta etapa começar.

## Matchmaking multi-time (Parte A, item 4 — a parte de maior risco)

**Migration**: `20260918100000_matchmaking_multi_team.sql`.

Auditei toda a cadeia de matchmaking antes de tocar nela: `match_search_
sessions`/`match_search_queue` (Etapa 5), a integração com elenco (Etapa 9,
`20260916100200`) e com squad (Etapa 10, `20260917100400`). Até aqui, uma
sessão/entrada de fila pertencia a UM `team_id` — reflexo direto da tela
Jogar sempre exigir escolher um time antes de buscar.

**Decisão**: como a tela Jogar deixa de ter seletor de time (item 3), buscar
passa a ocupar TODOS os times vinculados à Conta usada na busca, com uma
ÚNICA sessão real (nunca N sessões duplicadas). Solução:

- Tabelas novas `match_search_session_teams` / `match_search_queue_teams`
  (join, uma linha por time vinculado à conta no momento da busca).
  `match_search_sessions.team_id`/`match_search_queue.team_id` viram o
  "time primário" (o menor `team_id` do conjunto, escolha determinística) —
  continuam not-null, então FKs e `game_matches.team_id` não mudam de
  formato.
- Todo read model que comparava `team_id` direto passou a fazer join nessas
  tabelas: `_build_matchmaking_state`, `get_team_player_statuses`,
  `get_team_match_search_history`, `get_team_matchmaking_stats`,
  `_expire_team_search_if_needed`.
- `request_match_search` **perde o parâmetro `team_id`** — assinatura vira
  `(p_fc_account_id, p_fc_squad_id, p_game_mode)`. A conta já sabe quais
  times ocupar (`_fc_account_team_ids`). Ganha companheiro novo,
  `get_my_matchmaking_status(p_fc_account_id)`, o read model que a tela
  Jogar consome agora (estado por CONTA, não por time).
- `cancel_match_search`/`report_match_found_and_start_game` passam a
  receber `p_fc_account_id` em vez de `p_team_id` (mesmo tipo `uuid`,
  `create or replace` bastou, sem `drop`).
- Regra de conflito preservada e generalizada como **superconjunto, não
  cadeia**: buscar com conta ligada a Goiás+Palmeiras bloqueia SEARCHING
  nos dois, então Pedro (só Goiás) e João (só Palmeiras) ficam bloqueados
  mesmo sem overlap direto entre eles — não é transitividade por jogador
  compartilhado, é a MESMA sessão tocando os dois times.
- **Simplificação documentada de propósito**: uma conta na FILA trava o
  conjunto INTEIRO de times dela até ser promovida, mesmo que só parte
  deles esteja ocupada agora. Preferi superbloquear (nunca duplo-reservar)
  a arriscar promoção parcial errada. Está comentado na própria migration.
- Locking: todo o conjunto de times é travado em ordem (`_lock_teams_
  matchmaking`, ordenado por `team_id`) antes de qualquer leitura-decide-
  escreve — mesma disciplina de advisory lock por time que já existia,
  só estendida para N locks em vez de 1, sempre na mesma ordem (evita
  deadlock entre duas buscas que compartilham times).
- Promoção (`_promote_next_queued_players_for_teams`) virou um loop: acha a
  entrada de fila mais antiga cujo conjunto INTEIRO de times está livre
  agora, promove, repete — permite promover mais de uma conta disjunta
  numa única liberação de times.
- FQ035 novo: conta sem nenhum time vinculado, busca impossível.
- Histórico/estatísticas por time (`get_team_match_search_history`/
  `get_team_matchmaking_stats`) também passaram a enxergar sessões cujo
  time primário é outro mas que tocaram este time via join — senão o
  histórico de um "time secundário" ficaria mudo para buscas multi-time.

**Flutter**: `MatchmakingRepository`/`MatchmakingCubit`/`MatchmakingSection`
saíram de "escopado por `teamId`" para "escopado por `fcAccountId`".
`MyMatchmakingSnapshot` (entidade nova) substitui `MatchmakingSnapshot`
(deletada). O cubit assina o canal Realtime de CADA time vinculado à conta
(não mais um só) e reassina só quando o conjunto muda de verdade.
`TeamStatusCubit`/`get_team_player_statuses` (tela de Time) continuam
usando `watchTeam(teamId)` sem mudança — aquele uso é "avise quando este
time mudar", não estado de busca.

## Jogar (Parte A, itens 1 e 3)

`HomePage` perdeu o card de contexto do time (nome+tag+botão trocar) —
Times agora troca de tela pela seção "Times" (Parte B), não pelo Jogar.
Layout novo em blocos separados: card "Conta" (`FcAccountSelectorRow`),
card "Modo" (rótulo + `GameModeSelector`), card "Escalação"
(`SquadSelectorRow`, já mostrava "Principal · 4-3-3" com "Alterar"
secundário desde a Etapa 10), depois Weekend League/Pending Match/
`MatchmakingSection`. Nenhum seletor de Time em lugar nenhum desta tela.

## Times (Parte B)

Menu renomeado para "Times" (plural). Split em duas telas:

- `TeamsListPage` (`/app/team`, aba do shell): só a lista dos times do
  usuário, cada linha com nome/tag/contagem (`N jogadores · M ativos`,
  buscado via `fetchPlayerStatuses` por linha, sem realtime — é só um
  snapshot pra lista, o realtime mora na tela de detalhe).
- `TeamDetailPage` (`/app/team/:teamId`, nova rota push): nome, tag, lista
  de jogadores com status operacional (mesmo `TeamStatusCubit`/`get_team_
  player_statuses` de sempre), engrenagem de configurações — que SAIU da
  lista e só existe aqui agora.

## Perfil de player (Parte B)

RPC nova `get_team_member_profile(p_team_id, p_user_id, p_fc_account_id
default null)` — migration `20260918100100_team_member_profile.sql`.
Retorna: display_name/avatar, a Conta vinculada A ESTE TIME especificamente
(com desambiguação se o alvo tiver mais de uma conta linkada ao mesmo time
— devolve os candidatos e `needs_account_selection`, a UI oferece seletor),
divisão de Rivals atual, histórico de Weekend League (últimos 10 eventos
com W/L), resumo do squad principal (nome/formação/% completude). Nunca
expõe busca/histórico de fila, outras contas, outros times. Autorização:
caller e alvo precisam ser ambos membros do mesmo time (FQ012 senão).

Flutter: `PlayerProfilePage` (`/app/team/:teamId/player/:userId`),
`TeamRepository.fetchMemberProfile` novo, `PlayerProfile` entidade nova em
`features/teams/domain/entities/player_profile.dart`.

## Squad (Parte D)

Item 8 (squad principal) já vinha pronto da Etapa 10 — nada a fazer.
Item 9 (indicador de salvamento): badge "Salvo"/"Salvando…" no header do
Squad Builder, reagindo a `SquadBuilderState.isSaving` (já existia,
persistência já é por ação) — sem staging novo, só o indicador.

## Histórico/Filtros (Parte C)

`FilterChipRow` novo (`features/history/presentation/widgets/
filter_chip_row.dart`): altura fixa, scroll horizontal em vez de `Wrap`
quebrando linha. Usado nos três lugares que tinham filtro solto
(`ActivityTimelineView`, `MatchHistoryView`, `MatchmakingStatsView`).
Puramente layout — nenhuma lógica/dado mudou.

## Correções de SQL encontradas ao aplicar

`npx supabase db push` (real, não `--dry-run`, que só lista arquivos
pendentes sem validar SQL) pegou dois bugs reais na primeira tentativa,
ambos corrigidos e commitados (`eb02798`):

- `cancel_match_search`/`report_match_found_and_start_game` usavam `create
  or replace function` trocando o NOME do parâmetro (`p_team_id` →
  `p_fc_account_id`) mantendo o mesmo tipo `uuid` — Postgres recusa isso
  (`cannot change name of input parameter`, SQLSTATE 42P13). Precisou
  `drop function` explícito antes do `create`, com `revoke`/`grant`
  re-declarados depois (o drop apaga os grants existentes).
- `search_fc_player_cards`: o `revoke`/`grant` da assinatura nova estava
  digitado com os 3 últimos parâmetros como `uuid, uuid, uuid` quando a
  função de verdade os declara `text, text, text` (são nomes —
  `league_name`/`club_name`/`nation_name` — não ids). Postgres não achava a
  função para revogar/conceder (`function ... does not exist`, SQLSTATE
  42883).

Migrations 1 e 2 do lote aplicaram de primeira; só a 3ª precisou da
correção acima, reaplicada sozinha depois.

## Provider research (fut.gg/futbin/futwiz/outras/decisão)

`docs/card_provider_research.md` — decisão final e concreta, sem "tipo X ou
equivalente": **"FC 26 (FIFA 26) Player Data"**, dataset Kaggle de
`rovnez` (`kaggle.com/datasets/rovnez/fc-26-fifa-26-player-data`), licença
**CC BY 4.0**, scraping declarado de sofifa.com, versão 3
(`dateModified` 2025-09-22), 18k+ jogadores, colunas no padrão
sofifa/"FIFA complete player dataset" (`long_name`, `short_name`,
`overall`, `player_positions`, `pace/shooting/passing/dribbling/
defending/physic`, `goalkeeping_diving/handling/kicking/positioning/
reflexes/speed`, `height_cm`, `preferred_foot`, `weak_foot`,
`skill_moves`, `club_name`, `league_name`, `nationality_name`) — o mesmo
padrão que o mapeamento default do importer já assumia. Fallback: SoFIFA
direto (HTML público, scraping pontual e manual, nunca em cron), só para
preencher campo isolado que faltar. fut.gg/futbin/futwiz ficam anotados
como "vire parceiro oficial da EA Community API primeiro", não como alvo
de scraping — motivo completo na tabela comparativa do doc.

**Limitação encontrada e documentada**: datasets sofifa-style não trazem
técnicos/managers — item 68 do pedido original vira fallback permanente
(sem fonte gratuita conhecida para isso), não pendência temporária.

**Bug de parsing corrigido no importer antes do primeiro uso**:
`player_positions` vem como uma string única tipo `"ST, LW, CF"` (primária
+ alternativas juntas); o mapeamento original jogava essa string crua em
`primary_position` (ficaria `"ST, LW, CF"` inteiro) e duplicava tudo em
`alternative_positions`. Corrigido em `tool/sync_fc_cards.dart`: separa a
lista uma vez, primeira posição vira `primary_position`, o resto vira
`alternative_positions`.

## Dados reais (schema)

Migration `20260918100200_extend_fc_card_catalog.sql`:

- `fc_clubs` nova (clube deixa de ser só `club_name` texto solto).
- `fc_player_cards` ganha `game_version`, `is_active`, `last_synced_at`,
  `source_url`, `club_id`/`league_id`/`nation_id` (FK, com fallback pro
  texto legado via `coalesce` em `_fc_card_json`), os 6 stats de GK
  (`gk_diving/handling/kicking/reflexes/speed/positioning`) com CHECK
  garantindo que GK e outfield stats nunca coexistem na mesma linha,
  `skill_moves`, `weak_foot`, `playstyles`, `height_cm`, `preferred_foot`,
  `player_roles`, `rarity`.
- **Bug encontrado e corrigido nesta migration**: as 4 cartas GK do seed
  LOCAL da Etapa 10 tinham os 6 stats de linha preenchidos por engano
  (violaria a CHECK nova) — zeradas antes de criar a constraint.
- As 50 cartas `provider = 'LOCAL'` viram `is_active = false` — continuam
  no banco pra navegar em dev, mas `search_fc_player_cards` filtra
  `is_active` sempre, sem precisar de um segundo caminho "só produção".
- `search_fc_player_cards` ganha filtros de rating/liga/clube/nação/tipo —
  por NOME, não por id, porque `PlayerCardQuery` (Etapa 10) já declarava
  `leagueName/clubName/nationName` sem uso: o contrato existente mandou,
  em vez de inventar um contrato por id.

## Backend (RPCs/importer/segurança)

- `get_my_matchmaking_status`, `request_match_search` (3 args),
  `cancel_match_search`/`report_match_found_and_start_game` (por conta),
  `get_team_member_profile`, `search_fc_player_cards` (10 args) — todos
  `security definer`, `search_path=''`, `revoke`/`grant` explícitos, mesmo
  padrão de sempre.
- Importer `tool/sync_fc_cards.dart`: Dart standalone, nunca importado pelo
  app Flutter, autentica com `SUPABASE_SERVICE_ROLE_KEY` do ambiente (nunca
  hardcoded), lê CSV local, upsert idempotente por `(provider,
  provider_card_id)`, nunca deleta — marca `is_active=false` pro que sumiu
  da rodada. Mapeamento de colunas é externo (`--map=`) porque datasets
  comunitários variam nome de coluna entre si; `--dry-run` reporta quantas
  linhas seriam puladas por falta de campo obrigatório antes de escrever
  qualquer coisa.

## Git

Commits desta etapa (mais recente primeiro), todos em `origin/main`:

```
3accc60 Add the server-side card catalog importer script
8c3497d Extend the card catalog schema for real data and wire up the picker
1288b74 Align History's filter rows into one consistent toolbar
551db03 Split Times into a list and a per-team detail, add player profiles
91af06a Rebuild the Jogar screen around Account instead of Team
65404d4 Let one search occupy every team an account is linked to
67913f1 Rename Elenco to Conta across every user-facing string
```

`git status` limpo além de `.agents/`/`skills-lock.json` (tooling, nunca
commitado, como sempre). `flutter analyze` limpo depois de cada bloco.
`dart format lib`/`dart format tool` aplicados.

## Pendências conscientes

- **Migrations: RESOLVIDA.** As 3 aplicadas no Supabase remoto, local =
  remoto confirmado (`supabase migration list`, 55/55).
- **O importer de cartas reais ainda não rodou — bloqueado em 2 passos que
  só o usuário consegue destravar, nenhum deles é um "não tentei":**
  1. **Baixar o dataset de fato.** Kaggle exige conta logada para o botão
     de download (não é paywall, é o padrão do site) — esta sessão não tem
     login no Kaggle nem deveria ter. Preciso que o usuário baixe
     `kaggle.com/datasets/rovnez/fc-26-fifa-26-player-data` (arquivo ZIP,
     ~3.1MB) pela própria conta e coloque o CSV extraído em
     `tool/data/fc26_players.csv` (pasta nova, `tool/data/` — adicionar ao
     `.gitignore`, dataset de terceiro não deve ir pro Git).
  2. **`SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY` não estão no ambiente**
     desta máquina (`env | grep -i supabase` veio vazio). O importer já
     recusa rodar sem as duas (`tool/sync_fc_cards.dart:48-57`) — nunca
     devem ser coladas no chat; se o usuário confirmar que vai exportá-las
     no shell antes de rodar, o próximo passo é só `dart run
     tool/sync_fc_cards.dart --csv=tool/data/fc26_players.csv --dry-run`
     primeiro (confere o mapeamento contra o CSV real, o mapeamento
     default já foi corrigido pro schema deste dataset especificamente —
     ver seção Provider research), depois sem `--dry-run`.
  Com o arquivo e as env vars prontos, o resto é mecânico: dry-run,
  conferir contagem de puladas, import pequeno primeiro (`head -200
  fc26_players.csv > amostra.csv` e rodar contra a amostra), depois o
  arquivo inteiro.
- **Card type nas filtros do picker**: rating/liga/clube/nação estão
  implementados; `cardType` ficou de fora da UI do picker (a RPC já aceita
  o parâmetro, só falta o controle visual) — os valores possíveis dependem
  do dataset real, mais fácil decidir a UI depois de ver dados de verdade.
- **Traduções**: todas as chaves novas têm pt/en/es preenchidos, mas não
  passaram por revisão linguística aprofundada (regra da etapa: só a etapa
  final audita l10n).
- **Testes automatizados**: não rodados (regra do projeto, só a pedido).
- **Faxina antiga**: `weekend_league_event_model.dart` órfão (mencionado
  desde a Etapa 9) continua sem mexer — não é desta etapa.

## Pronto para a Etapa 12?

**Ainda não, com uma dependência clara primeiro**: aplicar as 3 migrations
novas no Supabase remoto e rodar o importer contra um dataset real (as duas
pendências acima) — sem isso o app roda com o catálogo LOCAL inativo
(picker vazio em produção) e o matchmaking multi-time nunca foi exercitado
contra o Postgres de verdade. Depois de resolvido isso, a Etapa 12 (gols,
assistências, estatísticas individuais, artilharia por WL/Rivals, evolução
de desempenho) tem uma base pronta: `game_matches.squad_snapshot` já guarda
jogador/posição/rating por partida desde a Etapa 10, e cada slot congelado
tem `card_id` — o suficiente para começar a contar gols/assistências por
carta sem precisar de outra migration de schema base.
