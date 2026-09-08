# Handoff — Etapa 8.5 (Jogar, modos, partida, resultado, reorg de UX)

Documento de continuidade no repositório (sobrevive à troca de conta/máquina).
**Escrito no meio da etapa** porque o limite da conta acabou. O backend está
COMPLETO, aplicado e validado; a camada Flutter está PELA METADE mas
**compilando** (`flutter analyze` limpo).

Referência: `origin/main`, HEAD `48ddcd8`. 33 migrations locais = 33 remotas
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

## 2. PRONTO — Flutter (commit `48ddcd8`, compila)

Cliente de matchmaking migrado para o backend novo (senão o app quebraria, pois
os RPCs antigos foram dropados):
- `GameMode` enum; `request_match_search` leva o modo; `reportMatchFound` chama
  `report_match_found_and_start_game`.
- `GameModeCubit` app-scoped (lembra o modo em SharedPreferences via
  `SelectedGameModeStore`), provido em `app.dart`. `matchmaking_section` já passa
  o modo selecionado em ambos os `startSearch`.
- Feature `game`: domínio (`PendingGameMatch`, `GameResult`, `GameRepository`),
  dados (datasource das RPCs `get_pending_game_match`/`finish_game_match`, model,
  repos Supabase+Local) e `PendingMatchState`. **Ainda órfã** (não registrada no
  DI, sem UI).

## 3. FALTA — Flutter (continuar daqui)

1. `game/presentation/cubit/pending_match_cubit.dart` (state já existe): load
   pending, `finish({result?/goals})`, refresh. `game/game_module.dart` +
   registrar em `app/dependencies.dart`.
2. `pending_match_card.dart` (item 14/15): "Você tem uma partida sem resultado" +
   modo + horário + [Vitória][Derrota] + "Adicionar placar". `finish_match_sheet.dart`
   (placar gols pró/contra → finish). Reaproveitar `historyEntryDate/Time` do l10n.
3. **Rename Buscar→Jogar** (item 2): valor do l10n `navSearch` → Jogar/Play/Jugar
   (manter a chave) + ícone em `app_shell_page.dart` (sugestão sports_esports).
4. **Renomear botões** (item 32): `matchmakingCancelAction` → "Cancelar",
   `matchmakingMatchFoundAction` → "Encontrei" (só o valor).
5. **Tela Jogar** (home_page): seletor de modo (chips do `GameModeCubit`) +
   card da campanha WL atual (precisa de um data layer p/
   `get_current_weekend_league_event` — NÃO existe ainda no client) + pending card
   + `MatchmakingSection` + empty state de "precisa de time" (reusar `TeamEmptyState`).
6. Ligar o pending card ao "Encontrei": passar um `onMatchFound` do
   `MatchmakingSection` até o botão (prop-drill por `_SearchingSelfCard`) para
   chamar `pendingCubit.load()` na hora — senão o card só aparece no próximo load.
7. **l10n PT/EN/ES** (item 62): modos (Weekend League / Division Rivals), Encontrei,
   Em jogo, pending/vitória/derrota/placar, WL #N, Jogar. Depois `flutter gen-l10n`.
8. Mapear **FQ020–024** no `supabase_error_mapper.dart` + textos l10n.
9. **Team reorg** (itens 27–31): tela Time usa `get_team_player_statuses`
   (RPC pronta; falta client + badges EM JOGO/BUSCANDO/NA FILA) e move
   convites/edição/duração para uma nova tela **Configurações do time**.
10. **Perfil reorg** (itens 36–39): sub-páginas Aparência / Idioma / Notificações.
11. **Histórico redesign** (itens 33–35): timeline combinada busca+partida +
    toolbar de filtros nova. ⚠️ NÃO existe read model de histórico de
    `game_matches` (só `get_pending`); criar um (ex.: estender o RPC de history
    ou um novo) para listar partidas FINISHED/EXPIRED.
12. **WL record card** (`get_weekend_league_record` pronta) + override manual
    (`set_weekend_league_manual_record` pronta) — UI mínima (item 25).
13. **Rivals division**: coluna `rivals_division` existe mas nenhuma RPC grava.
    Decidir: passar divisão em `report_match_found_and_start_game` ou update
    próprio. Seleção local por ora (item 26). Pendente de decisão.
14. **Auth polish** (item 40): 4 arquivos AINDA não commitados no working tree
    (`app_text_field.dart`, `login_page.dart`, `sign_up_page.dart`,
    `auth_form_scaffold.dart`) — wordmark maior, ícones mail/lock, hint senha,
    "Criar conta" movido, footer signup removido. Validar no device e commitar
    SEPARADO. NÃO perder.

## 4. Não commitar
Scripts de QA vivem no scratchpad.

## 5. Ordem de commits sugerida (item 68)
1. game backend ✅ (`b9619fc`)  2. Flutter Jogar/partida (parcial em `48ddcd8`,
continuar)  3. team/settings/profile polish  4. auth polish separado  5. docs.
Push `main`.
