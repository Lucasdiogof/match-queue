# Handoff — Etapa 8.5 (Jogar, modos, partida, resultado, reorg de UX)

Documento de continuidade no repositório (sobrevive à troca de conta/máquina).

**Estado: FECHADA.** Todos os 12 critérios de fechamento definidos pelo
usuário estão cumpridos: Jogar, partida/resultado, Time reorganizado, status
de jogadores, Configurações do Time, Perfil reorganizado, Aparência/Idioma/
Notificações em páginas próprias, Histórico combinado, filtros redesenhados,
WL computed record, auth polish commitado.

Referência: `origin/main`, HEAD `32e211f`. 37 migrations locais = remotas
(pooler `aws-0-sa-east-1`). `dart format .` QUEBRA aqui (varre `build/`); usar
`dart format lib`. `flutter analyze` limpo, `flutter build web --release`
verde (este é o único nível de verificação feito nesta rodada — o usuário
pediu para não parar pra QA/teste manual/tradução; isso fica pra etapa de
hardening).

---

## 1. Backend — commits `b9619fc` (base) + `db1492a`..`7f30d52` (fechamento)

Base da Etapa 8.5 (`b9619fc`, 5 migrations `20260914*`): game_mode em
sessions/queue, cooldown 30s (FQ020), `game_matches` (≤1 IN_MATCH por usuário),
`report_match_found_and_start_game`, `finish_game_match`,
`get_pending_game_match`, `weekend_league_events` (seed WL#1), record
computado+manual, `get_team_player_statuses` (só IN_MATCH/SEARCHING/QUEUED/
NONE nessa versão).

**4 migrations novas no fechamento** (`20260915*`):
- `profiles.last_active_at` (heartbeat espaçado, nunca presença real) +
  índice parcial.
- `get_team_player_statuses` estendida: tiers `RECENTLY_ACTIVE`/`OFFLINE`
  (corte de 60min sobre `last_active_at`), mais `queue_position` no payload.
- **Bug real corrigido**: `report_match_found_and_start_game` e
  `finish_game_match` nunca chamavam `_notify_matchmaking_changed` (a
  function antiga que substituíram tinha essa chamada; a nova nasceu sem
  ela). Sem isso, "Encontrei" mudava o estado (IN_MATCH) mas os outros
  membros do time só veriam no próximo refresh espontâneo, não em tempo
  real. Corrigido reaproveitando o mesmo sinal
  (`team_matchmaking_revisions`) que o resto do matchmaking já usa desde a
  Etapa 6.
- `get_team_activity_history(...)`: timeline combinada `game_matches` +
  `match_search_sessions`, paginação keyset por `(occurred_at, id)`, escopos
  ALL/GAMES/SEARCHES (ALL esconde buscas MATCH_FOUND, já representadas pela
  partida vinculada).

Todas as RPCs novas: security definer, `search_path=''`, member-gated, anon
revogado. Nenhuma migration já aplicada foi editada.

**FQ020–024 mapeados no client** (não estava feito antes): `GameFailure`/
`GameFailureReason` em `app_failure.dart`, textos PT/EN/ES.

## 2. Flutter — commits `db1492a`, `7f30d52`, `32e211f`

- **Tela Time reorganizada**: para de ser mistura de info/convite/edição e
  vira "quem está fazendo o quê agora" — `TeamStatusCubit` (escopado por
  time, escuta o mesmo canal realtime do matchmaking + poll leve de 60s só
  pros tiers de atividade, que são eventualmente consistentes por natureza)
  + `TeamStatusBadge` com a badge certa por status. Header mostra "N
  jogadores · M ativos".
- **Configurações do time** (rota nova `/app/team/settings`, ícone de
  engrenagem no AppBar da tela Time): Informações (nome/tag, sheet
  reaproveitado sem a duração), Busca (chips de duração — **único lugar que
  escreve `default_search_duration_seconds` agora**, via
  `update_team_search_duration` especificamente, não mais pelo `updateTeam`
  genérico, que perdeu esse parâmetro), Convites (`InviteSection` movida
  pra cá inteira) e Membros.
- **Perfil virou menu**: card de conta, depois Aparência/Idioma/
  Notificações como rotas próprias (`ThemeCubit`/`LocaleCubit`/stack de
  notificação existentes, só realocados, nada reescrito), Sessão embaixo.
- **Heartbeat de presença**: `PresenceHeartbeatListener` escreve
  `last_active_at` no foreground e a cada 75s enquanto autenticado — nunca
  por segundo, best-effort.
- **Histórico combinado**: `TeamActivityEntry` selado sobre
  `GameHistoryEntry`/`SearchHistoryEntry`, `ActivityHistoryCubit`/
  `ActivityTimelineView` substituem a aba de busca antiga. Toolbar:
  Tudo/Partidas/Buscas, com uma segunda linha de chips escopada à seleção
  (Vitórias/Derrotas ou Encontradas/Canceladas/Expiradas), período agora com
  90 dias. Sheet de detalhe funciona pros dois formatos de item. A aba
  Estatísticas não foi tocada (continua só sobre buscas).
- **`WeekendLeagueCard`** agora mostra o record computado (W–L) da campanha
  atual, via `get_weekend_league_record` (já existia, não era consumida).
- **Auth polish commitado** (`32e211f`): wordmark 56→76, ícones mail/lock
  outline nos campos, hint de bolinhas na senha, "Criar conta" reposicionado
  no login, footer removido do cadastro.

## 3. Pendências conscientes — ficam para a Etapa 9

- **Rivals division**: coluna `rivals_division` existe em `game_matches`,
  nenhuma RPC grava ainda. Vai ligada ao Elenco/Conta.
- **WL record manual** (override): `set_weekend_league_manual_record` já
  existe no backend, mas não tem UI — vai junto do Elenco/Conta também.
- **`account_squad_id`**: coluna sem FK em `game_matches`, gancho pronto pra
  quando a tabela de elencos existir.
- Mostrar o modo de jogo (`SearchingPlayer.gameMode`) nos cards de
  matchmaking em si (buscando/na fila) — campo já existe no snapshot, só
  não é exibido; cosmético, não bloqueia nada.
- Antigo `HistoryCubit`/`MatchHistoryView`/`get_team_match_search_history`
  (Etapa 8) ficaram órfãos depois da troca pela timeline combinada — não
  foram deletados nesta rodada (não era o foco), candidatos a limpeza na
  etapa de hardening.

## 4. Não commitar
Scripts de QA vivem no scratchpad.

## 5. Git
Push feito em cada bloco lógico, direto
pra `main`, como autorizado para este projeto.
