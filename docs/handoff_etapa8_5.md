# Handoff — Etapa 8.5 (Jogar, modos, partida, resultado, reorg de UX)

Documento de continuidade no repositório (sobrevive à troca de conta/máquina).
Backend COMPLETO, aplicado e validado. Fluxo Jogar/partida/resultado no
Flutter também COMPLETO (commit `5f6504a`) — `flutter analyze` limpo,
`flutter build web --release` verde. **Ainda falta** a reorg de UX (Time,
Perfil, Histórico) e o auth polish continua não commitado — ver seção 3.

Referência: `origin/main`, HEAD `5f6504a`. 33 migrations locais = 33 remotas
(pooler `aws-0-sa-east-1`). `dart format .` QUEBRA aqui (varre `build/`); usar
`dart format lib`.

---

## 1. PRONTO — Backend (commit `b9619fc`, aplicado + QA verde)

5 migrations `20260914*` + 1 correção (`..100500` tornou `get_pending_game_match`
volatile — era `stable` e o UPDATE lazy quebrava com 25006/405 no PostgREST).

- **game_mode** em `match_search_sessions` e `match_search_queue` (nullable +
  CHECK). `request_match_search(p_team_id, p_game_mode)` — assinatura NOVA (a de
  1 arg foi dropada). A promoção da fila herda o modo escolhido.
- **Cooldown 30s** dentro de `request_match_search`: rejeita com **FQ020** se o
  usuário iniciou uma partida há menos de 30s (por usuário, qualquer time). A
  promoção automática NÃO passa por cooldown.
- **game_matches**: partida real. status `IN_MATCH/FINISHED/ABANDONED/EXPIRED`;
  `result WIN/LOSS`; `goals_for/against`; `game_mode`; `weekend_league_event_id`
  (nullable, só WL); `rivals_division` (nullable, ainda NÃO gravado por nenhuma
  RPC); `account_squad_id` uuid nullable **sem FK** (gancho da Etapa 9).
  Índice único parcial `where status='IN_MATCH'` = **≤1 IN_MATCH por usuário**.
- **report_match_found_and_start_game(p_team_id)**: encerra a busca MATCH_FOUND,
  abre a partida IN_MATCH, **auto-marca ABANDONED** qualquer IN_MATCH anterior do
  usuário (decisão do item 13), vincula ao evento WL da janela atual, promove o
  próximo — tudo atômico. (Substituiu `report_match_found`, que foi dropada.)
- **finish_game_match(p_match_id, p_result?, p_goals_for?, p_goals_against?)**:
  placar deriva WIN/LOSS; sem placar aceita WIN/LOSS direto; empate → **FQ024**;
  só de IN_MATCH (double-finish → **FQ022**); partida não sua → **FQ021**.
- **get_pending_game_match()**: a partida IN_MATCH pendente do usuário (ou null),
  expira 20 min lazily. Expiração de 20 min: `_expire_stale_game_matches` +
  cron `game-match-expire` a cada 1 min. `EXPIRED` de PARTIDA ≠ `EXPIRED` de
  busca (tabelas distintas).
- **weekend_league_events** (+ seed **WL #1: 02→05/out/2026 UTC**) +
  `get_current_weekend_league_event()`.
- **weekend_league_manual_records** + `get_weekend_league_record(p_event_id?)`
  (computado das partidas FINISHED + override manual, nunca somados) +
  `set_weekend_league_manual_record(...)`.
- **get_team_player_statuses(p_team_id)**: cada membro com status
  `IN_MATCH>SEARCHING>QUEUED>NONE`. Presença (online/ativo há X) NÃO feita
  (deferida de propósito — item 30).
- Todas RPCs: security definer, `search_path=''`, member/ownership-gated, anon
  revogado. Tabelas novas com RLS ligada e sem policy (acesso só por RPC).

**FQ novos:** FQ020 cooldown, FQ021 partida não encontrada/não sua, FQ022 já
finalizada, FQ023 modo inválido, FQ024 resultado/placar inválido.
⚠️ O `supabase_error_mapper.dart` ainda **não mapeia FQ020–024** → caem no
failure genérico. Adicionar mapeamento + textos PT/EN/ES ao construir a UI.

QA validado (scripts em scratchpad, não commitados): search com modo,
QUEUED, Match Found→IN_MATCH+promoção, cooldown FQ020, pending+finish (placar
4-2→WIN e rápido LOSS sem placar), Rivals (evento null), WL vinculada dentro da
janela + record 1-0, double-finish FQ022, empate FQ024, expiração 20min→EXPIRED,
status EM JOGO, anon 401. **Dados de QA limpos: 0 resíduos** (só o seed WL#1
permanece).

## 2. PRONTO — Flutter (commits `48ddcd8` + `5f6504a`, compila e roda)

Fluxo completo de Jogar/modo/partida/resultado:
- `GameMode` enum; `request_match_search` leva o modo; `reportMatchFound` chama
  `report_match_found_and_start_game`.
- `GameModeCubit` app-scoped (lembra o modo em SharedPreferences via
  `SelectedGameModeStore`), provido em `app.dart`. `GameModeSelector` (chips,
  `Wrap`, mesmo padrão dos filtros do Histórico) exibido na Home.
- Feature `game` completa: domínio (`PendingGameMatch`, `GameResult`,
  `WeekendLeagueEvent`, `GameRepository` — ganhou
  `fetchCurrentWeekendLeagueEvent()`), dados (Supabase+Local), `PendingMatchCubit`
  (**app-scoped** como ProfileCubit/TeamsCubit — pending match é do usuário,
  não do time, por causa do índice único `≤1 IN_MATCH por usuário`; carregado no
  bootstrap, limpo por `PendingMatchSessionListener` no logout), `game_module.dart`
  registrado em `dependencies.dart`.
- `PendingMatchCard` (Vitória/Derrota rápidos + "Adicionar placar" →
  `FinishMatchSheet` com validação de empate no client, espelhando o FQ024 do
  banco) e `WeekendLeagueCard` (campanha atual + badge "Em andamento"), ambos
  renderizando `SizedBox.shrink()` quando não há dado — sem estado vazio pra
  desenhar.
- `MatchmakingSection` ganhou `onMatchFound` (prop-drill até o botão Encontrei
  em `_SearchingSelfCard`) — a Home passa
  `() => context.read<PendingMatchCubit>().refreshSilently()`, então o card
  pendente aparece na hora, sem esperar o próximo load espontâneo.
- Nav renomeada: `navSearch` = "Jogar" (mesma chave, valor novo) + ícone
  `sports_esports`. `matchmakingCancelAction` = "Cancelar",
  `matchmakingMatchFoundAction` = "Encontrei".
- **FQ020–024 mapeados**: `GameFailureReason`/`GameFailure` em
  `app_failure.dart`, `_gameReasonFrom` no mapper, textos PT/EN/ES.

## 3. FALTA — Flutter (continuar daqui)

1. **Team reorg** (itens 27–31): tela Time usa `get_team_player_statuses`
   (RPC pronta; falta client + badges EM JOGO/BUSCANDO/NA FILA) e move
   convites/edição/duração para uma nova tela **Configurações do time**.
2. **Perfil reorg** (itens 36–39): sub-páginas Aparência / Idioma / Notificações.
3. **Histórico redesign** (itens 33–35): timeline combinada busca+partida +
   toolbar de filtros nova. ⚠️ NÃO existe read model de histórico de
   `game_matches` (só `get_pending`); criar um (ex.: estender o RPC de history
   ou um novo) para listar partidas FINISHED/EXPIRED.
4. **WL record card** (`get_weekend_league_record` pronta) + override manual
   (`set_weekend_league_manual_record` pronta) — UI mínima (item 25). O
   `WeekendLeagueCard` atual só mostra a campanha, não o placar/record.
5. **Rivals division**: coluna `rivals_division` existe mas nenhuma RPC grava.
   Decidir: passar divisão em `report_match_found_and_start_game` ou update
   próprio. Seleção local por ora (item 26). Pendente de decisão.
6. **Auth polish** (item 40): 4 arquivos AINDA não commitados no working tree
   (`app_text_field.dart`, `login_page.dart`, `sign_up_page.dart`,
   `auth_form_scaffold.dart`) — wordmark maior, ícones mail/lock, hint senha,
   "Criar conta" movido, footer signup removido. Validar no device e commitar
   SEPARADO. NÃO perder.
7. Mostrar o modo de jogo nos cards de matchmaking (buscando/na fila) —
   `SearchingPlayer.gameMode` já existe no snapshot, só falta exibir.

## 4. Não commitar
Scripts de QA vivem no scratchpad.

## 5. Ordem de commits sugerida (item 68)
1. game backend ✅ (`b9619fc`)  2. Flutter Jogar/partida ✅ (`48ddcd8` +
`5f6504a`)  3. team/settings/profile polish  4. auth polish separado  5. docs.
Push `main`.
