# Handoff — Etapa 9 (Elencos/Contas do usuário + vínculo com clubes + WL/Rivals)

Status em 2026-09-08: **Etapa 9 FECHADA.** Backend aplicado e commitado
(`38b957e`); camada Flutter revisada, `flutter analyze` limpo, `dart format
lib` aplicado, build web de release verde e tudo commitado/pushado em blocos
lógicos. Este doc ficou como registro do que foi feito e das decisões — não
há mais trabalho pendente da Etapa 9.

## O que já está fechado (backend)

6 migrations novas, todas aplicadas em produção (`supabase db push`
confirmado, 43 migrations no remoto), commit `38b957e` já em `origin/main`:

- `20260916100000_create_fc_accounts.sql` — `user_fc_accounts` +
  `fc_account_teams` (N:N puro, nunca `teams.fc_account_id`).
- `20260916100100_fc_account_rpcs.sql` — `create_fc_account`,
  `update_fc_account`, `archive_fc_account`, `update_rivals_division`,
  `link_fc_account_to_team`, `unlink_fc_account_from_team`.
- `20260916100200_fc_account_matchmaking_integration.sql` — `fc_account_id`
  nullable em sessions/queue/game_matches; `request_match_search` evoluiu
  pra `(p_team_id, p_fc_account_id, p_game_mode)` (drop+create, assinatura
  mudou); valida ownership+active (FQ025) e vínculo elenco↔time (FQ026).
- `20260916100300_fc_account_weekend_league_progress.sql` — dropa a tabela/
  RPCs antigas de WL manual (nunca tiveram UI, seguro remover) e recria
  ligadas a `fc_account_id`: `fc_account_weekend_league_progress`,
  `get_weekend_league_record(p_fc_account_id, p_event_id)`,
  `set_weekend_league_manual_record`, `clear_weekend_league_manual_record`.
- `20260916100400_fc_account_list_and_history.sql` — `list_my_fc_accounts()`
  (um único jsonb com todos os elencos + team_ids + WL computado/manual +
  evento atual — desenhado assim de propósito pra não precisar de cubit
  separado de WL); `get_team_activity_history` ganhou 11º parâmetro
  `p_fc_account_id` (CREATE OR REPLACE, trailing default, sem quebrar).
- `20260916100500_pending_match_fc_account.sql` — `get_pending_game_match`
  retorna `fc_account_id`/`fc_account_name`.

Códigos novos: **FQ025** conta não encontrada/não é dono/inativa, **FQ026**
elenco não vinculado ao time, **FQ027** nome inválido, **FQ028** divisão
inválida.

## O que foi escrito na camada Flutter

`git status` mostra a lista completa; resumo por área:

- **`lib/features/fc_accounts/`** (pasta inteira nova): domain (entities
  `FcAccount`/`RivalsDivision`, repository interface), data (datasource,
  model, repositório Supabase + Local honesto, `SelectedFcAccountStore`
  espelhando `SelectedTeamStore`), presentation (`FcAccountsCubit` — um
  cubit só, list+seleção+CRUD, mesmo padrão do `TeamsCubit` — e todos os
  widgets/páginas abaixo), `fc_accounts_module.dart` (DI).
- **Widgets/páginas de elenco**: `create_fc_account_sheet.dart`,
  `rename_fc_account_sheet.dart`, `fc_account_switcher_sheet.dart`,
  `rivals_division_picker_sheet.dart`, `rivals_division_l10n.dart`,
  `weekend_league_manual_record_sheet.dart`, `fc_account_selector_row.dart`
  (linha "elenco atual ▾" na Home), `fc_account_onboarding_card.dart`
  (estado vazio na Home quando zero elencos), `fc_accounts_page.dart`
  ("Meus Elencos", lista + criar), `fc_account_detail_page.dart` (seções
  Divisão/Weekend League/Times vinculados/Configurações com arquivar).
- **Rotas**: `AppRoutes.fcAccounts` (`/app/fc-accounts`) e
  `AppRoutes.fcAccountDetail` (`/app/fc-accounts/:fcAccountId`), registradas
  em `app_router.dart`. Linha "Elencos" nova no Profile
  (`_FcAccountsSection`, antes de Preferências).
- **`app/dependencies.dart`/`bootstrap.dart`/`app.dart`**: `FcAccountsCubit`
  registrado, carregado no bootstrap com sessão restaurada,
  `FcAccountsSessionListener` inserido na cadeia de listeners (entre
  `TeamsSessionListener` e `PendingMatchSessionListener`).
- **Matchmaking**: `MatchmakingRepository.requestSearch` e
  `MatchmakingCubit.startSearch` ganharam `fcAccountId` obrigatório.
  `matchmaking_section.dart` tem um `_StartSearchButton` novo que: sem
  elenco selecionado desabilita o botão (com hint); elenco selecionado mas
  NÃO vinculado ao time vira CTA "Vincular X ao Y" (chama `linkToTeam`,
  nunca busca silenciosamente); só busca de fato quando já vinculado.
  `SearchingPlayer`/`MatchmakingQueueEntry` ganharam `fcAccountName` (vem
  do backend, mostrado na fila).
- **Weekend League ficou 100% elenco-cêntrico**: `WeekendLeagueCard` foi
  REESCRITO pra ler de `FcAccountsCubit` (não mais de `PendingMatchCubit`) —
  troca de elenco troca o record mostrado, tap abre o sheet de resultado
  manual. Por causa disso, `GameRepository.fetchCurrentWeekendLeagueEvent`/
  `fetchWeekendLeagueRecord` foram REMOVIDOS (a RPC antiga de 1 argumento
  não existe mais, foi dropada pela migration 100300) — `PendingMatchCubit`/
  `PendingMatchState` foram simplificados de volta pra só rastrear a
  partida pendente, sem WL.
- **`PendingGameMatch`/`PendingMatchCard`**: ganharam `fcAccountName`,
  mostrado como linha extra "Elenco: X" no card.
- **Histórico**: `TeamActivityEntry` (base sealed, GAME e SEARCH) ganhou
  `fcAccountName`; parser (`team_activity_model.dart`) já lê
  `fc_account_name` do JSON. O nome passou a aparecer no detail sheet do
  `ActivityTimelineView` (ver seção de fechamento). **O filtro "Todos os
  elencos / <elenco>" NÃO existe** e segue fora de escopo — item 85 não o
  menciona; foi adiado deliberadamente, não esquecido.
- **Erros/l10n**: `FcAccountFailure`/`FcAccountFailureReason` em
  `app_failure.dart`, mapeados em `supabase_error_mapper.dart` (FQ025-028) e
  `app_failure_l10n.dart`. `AppValidators.fcAccountName` (2-40 chars, igual
  ao CHECK do banco) + `validation_l10n.dart`. Todas as strings novas
  (~70 chaves) já estão em `app_pt.arb`/`app_en.arb`/`app_es.arb` e **`flutter
  gen-l10n` já rodou** (os `generated/*.dart` aparecem modificados no git
  status — isso é esperado, não precisa rodar de novo a menos que edite os
  `.arb` de novo).

## Fechamento (o que foi feito na retomada)

1. `flutter analyze` rodou no lote inteiro: 5 avisos, nenhum erro de tipo ou
   compilação — 4 imports não usados (resíduo da limpeza de WL e da fiação
   do `FcAccountsCubit`) e 1 `prefer_const`. Todos corrigidos; analyze
   terminou em **No issues found**.
2. Isso também resolveu o antigo item 4 (conferir `fc_account_detail_page`
   contra os nomes reais de `AppDialog`/`showAppDialog`): o analyze pega
   nome indefinido, então o arquivo compila de fato.
3. `dart format lib` aplicado (22 arquivos). Seis deles eram de Etapas 8/8.5
   que nunca tinham passado pelo formatter — foram isolados num commit
   separado só de formatação, para não poluir os commits da Etapa 9.
4. Item 5 (opcional) **foi feito**: o nome do elenco aparece agora no detail
   sheet do `ActivityTimelineView`, nos dois ramos (GAME e SEARCH), via a
   chave nova `activityDetailFcAccount` em PT/EN/ES. Ficou no sheet e não na
   linha da lista para não competir com placar/status. Entradas anteriores à
   Etapa 9 não têm elenco e simplesmente omitem a linha. **O filtro "Todos os
   elencos / <elenco>" continua não existindo** — segue fora do escopo (item
   85 não pede).
5. Verificações de resíduo: `grep` por `weekendLeagueEvent`/
   `weekendLeagueRecord` fora de `fc_accounts/` só encontra o
   `weekend_league_card.dart`, e lendo o arquivo o `state` ali é
   `FcAccountsState` (o correto). `PendingMatchState` está limpo, sem WL.
   `fetchCurrentWeekendLeagueEvent`/`fetchWeekendLeagueRecord` não existem
   mais em lugar nenhum.
6. `flutter build web --release` verde.
7. `flutter test` **não** foi rodado (regra do projeto: só a pedido).

## Pendências conscientes

- Filtro de histórico por elenco (item 5 acima) — fora do escopo da Etapa 9.
- `weekend_league_event_model.dart` em `features/game/data/models/` ficou
  órfão depois da limpeza do `GameRepository`. Não quebra build; candidato a
  faxina futura.
- Etapa 10 (Squad Builder, formações, campo, time titular) não foi iniciada.

## Coisas específicas pra não esquecer

- `.agents/` e `skills-lock.json` continuam untracked e **nunca devem ser
  commitados** (tooling).
- Nenhuma migration foi editada depois de aplicada — o histórico remoto está
  limpo.
