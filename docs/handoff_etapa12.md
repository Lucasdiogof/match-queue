# Handoff — Etapa 12 (Detalhamento de partida: placar, gols, assistências, estatísticas)

Status em 2026-09-08: **backend e Flutter escritos, commitados e pushados em
`origin/main`** (`flutter analyze` limpo no fim do lote). A migration desta
etapa foi aplicada no Supabase remoto de primeira via `npx supabase db push`
(sem erro de SQL, diferente da Etapa 11). Nenhum teste foi rodado (regra
permanente do projeto) — `flutter analyze` foi a única verificação, conforme
autorizado para migration/RPC crítica.

## Objetivo e modelo, em uma frase

Três níveis opcionais de detalhamento de partida (Vitória/Derrota → placar →
gols/assistências por jogador), nunca bloqueando o fluxo rápido, e resultado
editável a qualquer momento depois de `FINISHED`, sem janela de tempo.

## Banco

Migration nova: `supabase/migrations/20260919100000_game_match_player_stats.sql`
(nenhuma migration antiga foi editada). Namespace de erro `FQ0xx` estendido:
`FQ036` payload de stats inválido, `FQ037` jogador fora do snapshot, `FQ038`
partida sem `squad_snapshot`, `FQ039` partida ainda não `FINISHED`.

### Tabela `game_match_player_stats`

Agregado por jogador, não evento-a-evento (decisão já tomada pelo dono do
produto, seguida à risca): `game_match_id`, `snapshot_player_key` (hoje
sempre o `card_id` do momento do congelamento — é a única chave que já vem
de graça dentro do `squad_snapshot`, e `fc_squad_slots_unique_card_per_squad`
garante que não repete dentro do mesmo squad), `player_card_id` (nullable,
pode sumir se o catálogo mudar), `player_name`/`position`/`rating`
(derivados do snapshot, nunca do client), `goals`/`assists` (`0..99`,
`unique(game_match_id, snapshot_player_key)`). RLS habilitada, zero policies
— tudo passa por RPC, mesmo padrão do resto do projeto. Índice explícito em
`game_match_id` e um composto em `game_matches (fc_account_id, game_mode,
status)` para os agregados novos.

### RPCs criadas

- `update_game_match_result(p_game_match_id, p_result, p_goals_for,
  p_goals_against)` — só o dono, só quando `status = 'FINISHED'` (edita
  quantas vezes quiser, sem limite de tempo; `IN_MATCH` continua usando
  `finish_game_match`, que não mudou).
- `upsert_game_match_player_stats(p_game_match_id, p_stats jsonb)` — atômica
  (uma função = uma transação): recebe `[{snapshot_player_key, goals,
  assists}]`, valida cada item **contra o `squad_snapshot` congelado daquela
  partida** (`FQ037` se o jogador não estiver lá — titular ou banco, ambos
  elegíveis), deriva nome/posição/rating do próprio snapshot, nunca do
  client. Substitui a linha inteira por partida a cada chamada (delete +
  insert dos não-zerados) — o Flutter sempre manda o roster completo do
  snapshot, então isso é seguro e mantém a tabela enxuta.
- `get_game_match_details(p_game_match_id)` — partida + conta + squad
  snapshot + player stats numa única chamada (evita N+1 no Historico). Dono
  ou membro do mesmo time pode ler; a resposta carrega `is_owner` pra UI
  decidir se mostra CTA de editar.
- `get_fc_account_stats(p_fc_account_id)` — partidas/W/L/gols pró-contra-
  saldo, todos os modos, só o dono.
- `get_weekend_league_account_stats(p_fc_account_id,
  p_weekend_league_event_id)` — computado (das partidas reais) e manual
  (override já existente desde a Etapa 9) **sempre em campos separados**,
  nunca somados; artilharia e assistências ordenadas por
  `goals desc, assists desc, name asc` e `assists desc, goals desc, name
  asc` respectivamente.
- `get_rivals_account_stats(p_fc_account_id)` — mesmo padrão pra Division
  Rivals, **all-time** (sem season/semana modelada ainda — simplificação
  consciente documentada no próprio comentário da função).
- `get_team_member_profile` ganhou um `sport_summary` (Rivals all-time +
  até 3 líderes de gols/assistências da conta) — mesma assinatura de
  antes, só o corpo mudou (`create or replace`, sem quebrar chamadas
  existentes).
- Dois helpers internos reaproveitados por tudo acima:
  `_fc_account_match_aggregate` e `_fc_account_player_leaderboard` — ambos
  filtram **direto em `game_matches.fc_account_id`**, nunca fazem join com
  `match_search_session_teams`/`match_search_queue_teams`. Isso é
  deliberado: `game_matches.team_id` é sempre singular por partida (uma
  linha = uma partida real), então não existe caminho pra duplicar por
  causa do matchmaking multi-time nesses agregados — testei mentalmente o
  caso do produto (conta ligada a 2 times, 1 partida) e confirmo que
  aparece uma vez só, porque a query nunca toca as tabelas de junção da
  Etapa 11.

## Resultado editável depois de finalizado

`finish_game_match` (Etapa 10) não mudou — continua sendo o único caminho
pra sair de `IN_MATCH`. `update_game_match_result` é a RPC nova, chamada só
quando já `FINISHED`. No Flutter: `MatchDetailsPage` mostra "Editar
resultado" pro dono, abrindo `EditMatchResultSheet`
(`lib/features/game/presentation/widgets/edit_match_result_sheet.dart`) —
placar ou Vitória/Derrota direto, igual ao fluxo original de finalizar.

## Player stats (gols/assistências)

Fluxo rápido intocado: os botões Vitória/Derrota do `PendingMatchCard`
continuam ~1 toque. Depois de finalizar (rápido ou com placar), se a
partida tinha squad no momento da busca (`fcSquadName != null` — proxy
confiável pra "tem `squad_snapshot`"), um diálogo oferece, secundariamente,
ir direto pro detalhe registrar gols/assistências — nunca obrigatório,
nunca automático (`maybeOfferMatchDetails` em `pending_match_card.dart`).

`PlayerStatsEditorPage` (`lib/features/game/presentation/pages/
player_stats_editor_page.dart`) lista **titulares e banco, ambos
elegíveis**, exclusivamente do `squad_snapshot` daquela partida (nunca do
squad atual). Cada jogador tem dois steppers `[-] N [+]` (gols/assistências,
0-99). "Salvar detalhes" é explícito, sem autosave — manda o roster inteiro
numa chamada só pra `upsert_game_match_player_stats`.

Validação de snapshot é o ponto que mais me preocupei em acertar: o Flutter
só manda `{snapshot_player_key, goals, assists}` — nome/posição/rating vêm
de volta do backend, derivados do próprio `squad_snapshot` armazenado em
`game_matches`. Testei mentalmente os 4 casos do dono do produto: jogador de
outro squad, de outra conta, carta "atual" fora do congelamento — todos
batem em `FQ037` porque a comparação é sempre contra o
`v_match.squad_snapshot -> 'players'` daquela `game_match_id` específica,
nunca contra o catálogo vivo.

Partida sem `squad_snapshot` (legado pré-Etapa 10, ou busca sem squad):
`GameMatchDetails.canDetailPlayers` fica `false` e a seção inteira some da
UI — nunca um estado de erro.

## Weekend League

`WeekendLeagueCard` (Home) agora mostra o artilheiro (via
`get_weekend_league_account_stats`, `FutureBuilder` leve) e o toque abre
`WeekendLeagueDetailPage` — record (computado x manual, nunca somados;
banner de aviso quando divergem, com a copy `weekendLeagueDetailManualNote`
deixando claro que são coisas diferentes), gols/saldo/partidas, artilharia e
assistências em seções (não abas — o spec permitia e simplifica bastante).
O botão de editar o override manual continua ali dentro
(`showWeekendLeagueManualRecordSheet`, sem mudança). `FcAccountDetailPage`
tem a mesma navegação a partir do card de Weekend League já existente.

## Rivals

Novo `_RivalsStatsSection` em `FcAccountDetailPage` (record + artilheiro
inline) abrindo `RivalsDetailPage` — resumo + artilharia + assistências,
com nota explícita de que é all-time (`rivalsAllTimeNote`) porque season/
semana não está modelada ainda.

## Conta (Estatísticas)

`FcAccountDetailPage` ganhou a seção "Estatísticas" (entre Weekend League e
Times vinculados, como pedido): partidas registradas, vitórias, derrotas,
gols marcados/sofridos, saldo — `get_fc_account_stats`, todos os modos.

## Perfil público (Time → membro)

`PlayerProfilePage` ganhou "Resumo esportivo": record all-time de Rivals e
até 3 líderes de gols/assistências da conta vinculada àquele time — nunca
histórico de busca, nunca lista de partida individual crua (`sport_summary`
do `get_team_member_profile`).

## Histórico

`ActivityTimelineView`'s bottom sheet de detalhe ganhou um botão que leva
pra `MatchDetailsPage` (rota nova `/app/history/match/:matchId`) quando a
entrada é uma partida encerrada — a tela real de detalhe (placar, squad,
gols/assistências por jogador, CTA de editar pro dono). O sheet leve
continua existindo pra visão rápida; a página nova é o destino completo.

## Segurança e integridade — os dois pontos mais enfatizados

1. **Snapshot é a única fonte de verdade dentro de uma partida.** Toda
   validação de jogador em `upsert_game_match_player_stats` compara contra
   `game_matches.squad_snapshot` daquela `game_match_id`, nunca contra
   `fc_player_cards`/`fc_squads` ao vivo. Nome/posição/rating são sempre
   derivados server-side.
2. **Zero risco de duplicação multi-time nos agregados.** Todos os
   agregados novos (`_fc_account_match_aggregate`,
   `_fc_account_player_leaderboard`, e as RPCs públicas em cima deles)
   filtram só por `game_matches.fc_account_id`/`game_mode`/
   `weekend_league_event_id` — nunca fazem join com
   `match_search_session_teams`/`match_search_queue_teams`. Como
   `game_matches.team_id` é singular por design (Etapa 11), uma partida
   nunca aparece duas vezes em nenhum agregado desta etapa.
3. Ownership: escrita (`update_game_match_result`,
   `upsert_game_match_player_stats`) sempre exige `auth.uid() =
   game_matches.user_id`; leitura (`get_game_match_details`) aceita dono OU
   membro do mesmo time, nunca edita. `get_fc_account_stats`/
   `get_weekend_league_account_stats`/`get_rivals_account_stats` exigem
   dono da conta — isolamento entre contas garantido pelo mesmo padrão
   usado desde a Etapa 9 (`user_fc_accounts.user_id = auth.uid()`).
4. Record manual de WL nunca gera partida/stat falsa: `manual` e
   `computed` chegam em campos JSON separados em toda RPC nova, e a UI
   nunca soma um no outro nem inventa a diferença — só mostra os dois
   lado a lado com um aviso quando divergem.

## Flutter — arquivos principais

- Entidades novas: `GameMatchDetails`, `SquadSnapshot`/`SquadSnapshotPlayer`,
  `GameMatchPlayerStat`/`GameMatchPlayerStatInput`, `PlayerLeaderboardEntry`,
  `FcAccountStats`/`ManualRecord`/`WeekendLeagueAccountStats`/
  `RivalsAccountStats` — todas `Equatable`, sem codegen, seguindo o padrão
  do resto do projeto.
- `GameRepository`/`GameRemoteDataSource`/`SupabaseGameRepository`/
  `LocalGameRepository` ganharam `fetchMatchDetails`, `updateMatchResult`,
  `upsertPlayerStats`.
- `FcAccountRepository`/datasource/repositórios (Supabase e Local) ganharam
  `fetchAccountStats`, `fetchWeekendLeagueAccountStats`,
  `fetchRivalsAccountStats`.
- Páginas novas: `MatchDetailsPage`, `PlayerStatsEditorPage`,
  `WeekendLeagueDetailPage`, `RivalsDetailPage`. Widget novo:
  `EditMatchResultSheet`.
- Rota nova: `AppRoutes.matchDetail` (`/app/history/match/:matchId`).
- `flutter gen-l10n` rodado duas vezes (chaves novas em pt/en/es, todas com
  tradução real, nenhuma placeholder).

## Git

Commits nesta sessão, todos em `origin/main`:

```
22d5390 Add per-player match stats, editable results, and account/WL/Rivals aggregates
56ac35d Let match results be edited any time and add a match detail screen
421a5d5 Show account stats, Weekend League and Rivals detail pages
6effdaa Add a sport summary to the player profile
61f608b Add localization keys for match details and stats screens
```

`flutter analyze` limpo depois do lote inteiro. `dart format lib` rodado
(11 arquivos reformatados, nenhuma mudança de lógica). Nenhum teste
existente foi rodado ou quebrado deliberadamente — regra permanente do
projeto (`feedback_defer_tests_until_asked`).

## Pendências conscientes / fora de escopo

- Minuto do gol, chutes/posse/desarmes/defesas/cartões/xG, chemistry do
  squad: fora de escopo por decisão do dono do produto, não modelado.
- Consolidação de identidade entre versões diferentes do mesmo jogador
  (ex. Mbappé Gold vs Mbappé TOTS): são estatísticas separadas nesta V1 —
  `snapshot_player_key`/`player_card_id` são por carta, não por "pessoa".
  Evolução futura, não implementada.
- Ranking global de Time: arquitetura permite (bastaria agregar
  `game_matches` por `team_id` em vez de `fc_account_id`), mas não
  implementado agora.
- Season/semana em Rivals: `get_rivals_account_stats` é all-time,
  documentado como simplificação consciente no comentário da própria RPC.
- Catálogo real de cartas FC27: continua pendência **externa** da Etapa 11
  (situação B, fechada) — não reaberta aqui, e esta etapa inteira funciona
  sem depender dele (tudo usa `squad_snapshot` congelado).
- Não construí abas (TabBar) nas telas de detalhe de WL/Rivals — usei
  seções verticais simples, permitido pelo próprio pedido ("abas ou
  seções") e mais rápido de fazer bem.

## Pronto para a próxima etapa?

Sim, na minha avaliação: banco, RPCs, entidades e UI estão consistentes
fim-a-fim, `flutter analyze` limpo, migration aplicada no remoto sem erro.
Não avancei para nenhuma implementação além do que foi pedido nesta etapa.
