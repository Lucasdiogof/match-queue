# Gameplay Flows Refresh — handoff

## Escopo desta etapa

Rodada separada do UI/UX Refresh (`docs/handoff_ui_refresh.md`) — regras
funcionais reais: ordem Conta FC → Time, anti-duplicação no picker do
Squad Builder, fotos de carta, overlap no campo, um bug real de overflow em
bottom sheet, filtros hierárquicos de Nação/Clube, e um card de Rivals que
faltava na Home. Auditoria completa (em paralelo) feita antes de
qualquer edição — vários itens do pedido original já estavam corretos no
código (Weekend League resumo+detalhado, Division Rivals como estado), e
foram só confirmados/documentados, não reconstruídos.

## Fluxo Auth → Home → Conta FC → Time

Sem mudança no router: usuário autenticado sempre cai em Início, nunca
bloqueado por falta de Conta FC/Time (mesmo padrão já usado em `Controle`
para Conta FC e em `Times`/`Histórico` para Time — estado vazio branchado
*dentro* da tela, nunca redirect de rota).

## Regra de Conta FC obrigatória

- `CreateTeamSheet` (`lib/features/teams/presentation/widgets/create_team_sheet.dart`):
  agora reage a `FcAccountsCubit.state.hasAccounts`. Sem nenhuma Conta FC,
  mostra o convite pra criar a primeira (mesmo texto de
  `FcAccountOnboardingCard`) em vez do formulário de time — reativo: assim
  que uma conta é criada, o próprio `BlocBuilder` troca pro formulário
  real, sem fechar/reabrir o sheet.
- Fluxo de convite (`lib/features/invitations/presentation/pages/join_team_page.dart`):
  em `_openTeam`, uma entrada **nova** (não reabertura de quem já era
  membro) dispara `_linkFcAccounts` — sem Conta FC, empurra pra
  `/app/fc-accounts` e retoma o mesmo fluxo ao voltar. A adesão ao time
  (`team_members`) já aconteceu nesse ponto (é o que a RPC de convite faz)
  — o que fica pendente é só o vínculo Conta FC ↔ Time, nunca a entrada em
  si.

## Relação Time ↔ Conta FC

**Nenhuma migration nova.** O vínculo N:N já existia pronto desde a Etapa 9
(`fc_account_teams`, RPCs `link_fc_account_to_team`/
`unlink_fc_account_from_team`, já expostas em `FcAccountsCubit.linkToTeam`/
`unlinkFromTeam` e usadas em `fc_account_detail_page.dart`). O trabalho
desta etapa foi 100% de orquestração client-side: chamar `linkToTeam` no
momento certo (depois de criar/entrar no time), nunca duplicar a lógica de
autorização que a RPC já garante (dono da conta + membership do time).

## Fluxo de convite

Ver seção acima — preservado integralmente (`resolve_team_invite`/
`join_team_by_invite` intocadas), só ganhou o passo de seleção de Conta(s)
FC depois de uma entrada nova bem-sucedida.

## Picker anti-duplicação

Gap real confirmado por código: `search_fc_player_cards` não excluía
cartas já usadas em outro slot do squad, e `set_fc_squad_slot` realocava a
carta em silêncio ao selecioná-la de novo. Fix:

- Migration `20260930100000_search_fc_player_cards_exclude_ids.sql`:
  `search_fc_player_cards` ganha `p_exclude_card_ids uuid[] default null`
  (aditivo — nenhuma chamada antiga quebra). Verificado ao vivo em
  produção: excluir o id do Mbappé faz ele sumir da lista, mantendo a
  ordenação por rating dos demais.
- `FcSquadDetail.usedCardIds` (novo getter) alimenta o picker nos 3 pontos
  onde ele abre: slot titular vazio, banco/reserva vazio, e "Trocar" num
  slot já preenchido (nesse último, exclui todo `usedCardIds` MENOS o
  próprio card do slot em edição — senão ele sumiria da lista sem motivo).
- Unicidade continua por **card id**, não por jogador (`fc_player_id`) —
  decisão consciente: duas versões de carta do mesmo atleta continuam
  podendo ocupar dois slots, é o modelo correto hoje.

## Status das imagens das cartas

Schema e dado real **já tinham** as imagens (`player_image_url`/
`card_image_url`, populadas pelo importer real). O card do campo
(`squad_player_card.dart`) já renderizava com fallback de iniciais. O gap
era só a linha do picker (`_PlayerRow`), que ignorava o campo — agora
renderiza a mesma imagem com o mesmo fallback.

## Campo do Squad Builder (overlap)

`squad_field.dart`: `cardWidthForFormation` (função livre, testável)
substitui o `width/5.4` fixo. Agrupa os slots da formação ativa por linha
(mesmo `y` arredondado), acha o menor espaçamento horizontal real entre
slots vizinhos de cada linha, e usa isso como teto do tamanho do card —
nunca menor que 48px (prefere card legível a eliminar 100% do overlap numa
formação extrema), nunca variando entre cards da mesma tela. Testes
unitários em `test/features/fc_squads/squad_field_card_width_test.dart`
(baseline sem linha densa, encolhimento numa 5-across, respeito ao
espaçamento real, piso absoluto, estabilidade).

## Bottom sheet — overflow corrigido

Causa raiz: `AppBottomSheet.child` entrava direto num `Column(mainAxisSize:
min)` sem altura máxima nem scroll — funcionava quando quem chamava já
embrulhava o próprio conteúdo em algo rolável, mas `_showNamePickerSheet`
(filtros de Nação/Liga/Clube) passava uma lista de até ~150+ botões numa
`Column` comum. Fix estrutural: `AppBottomSheet` ganhou `isChildScrollable`
— quando `true`, a sheet ganha altura máxima (85% da viewport) e `child`
recebe o espaço restante via `Flexible`, cabendo ao próprio `child` (agora
sempre um `ListView`) rolar. Título/subtítulo/ações continuam fixos fora
da área rolável.

## Filtro Nação

Agrupamento alfabético (A-C, D-F, ... V-Z — sem bucket "Popular", não
existe critério real de popularidade no catálogo, não foi inventado um).
Novo componente `catalog_picker_sheet.dart` (`showAlphabeticalPickerSheet`)
usado só client-side — nenhuma RPC nova, a lista completa (~157 nações)
já vinha do `getNations()` existente.

## Filtro Liga

Fica flat (decisão registrada, não esquecimento): ~57 ligas no catálogo
real é uma lista administrável, só precisava do fix de scroll acima
(`showFlatCatalogPickerSheet`).

## Filtro Clube

Hierárquico em 2 níveis, como pedido: faixa alfabética de Liga → Liga →
Clubes daquela liga (reaproveita `getClubs(leagueName:)`, que já filtrava
por liga). ~572-646 clubes no catálogo real justificam de verdade a
hierarquia.

## Weekend League

**Já correto, confirmado por auditoria — nada construído.** Modo resumo
(`fc_account_weekend_league_progress.manual_wins/losses`, RPCs
`set_weekend_league_manual_record`/`clear_weekend_league_manual_record`) e
modo detalhado (`game_matches.weekend_league_event_id`, partida a partida)
já coexistem desde a Etapa 9 — "computado nunca é somado ao manual" é
comentário explícito no schema. `WeekendLeagueCard` na Home já era resumo
com link pra `WeekendLeagueDetailPage`, nunca formulário inline.

## Division Rivals

**Já correto, confirmado por auditoria — nada construído.**
`rivals_division` é campo direto em `user_fc_accounts`, atualizado via
`update_rivals_division` RPC, sem depender de partida nenhuma.
`RivalsDetailPage` é leitura agregada (all-time); a divisão é trocada por
um picker sheet simples. Único gap real: **não existia card de Rivals na
Home** — corrigido.

## Cards da Home

Novo `RivalsCard` (`lib/features/game/presentation/widgets/rivals_card.dart`),
espelhando `WeekendLeagueCard` — resumo (divisão atual) + link pra
`RivalsDetailPage`, nunca formulário embutido. Adicionado ao lado do
`WeekendLeagueCard` em `home_page.dart`.

## Telas Time/Conta FC

**Já corretas, confirmado por auditoria — nada alterado.**
`TeamDetailPage` só tem `TeamWeekendLeagueSection`/`TeamRivalsSection`
(leitura agregada, sem formulário). `FcAccountDetailPage` só tem botões
que abrem os sheets de edição (não embute formulário inline). A separação
de responsabilidades pedida já existia.

## Migrations

- `supabase/migrations/20260930100000_search_fc_player_cards_exclude_ids.sql`
  — aplicada em produção, verificada ao vivo (exclusão de card id
  confirmada contra dados reais).

## RLS / Segurança

Nenhuma tabela nova, nenhuma policy nova. `link_fc_account_to_team`/
`unlink_fc_account_from_team` (RPCs já existentes) continuam sendo o único
caminho de escrita do vínculo — já verificam dono da conta + membership do
time, nenhum reforço necessário. `p_exclude_card_ids` na busca de cartas é
só uma lista de uuids a filtrar, mesma superfície de RLS de antes.

## Testes

- `test/features/fc_squads/squad_field_card_width_test.dart` (novo, 5
  casos) — lógica pura de `cardWidthForFormation`, sem harness de widget.
- Suíte completa (`flutter test`): 11 testes, todos verdes, zero
  regressão.
- `flutter analyze`: **No issues found**.

## QA visual

**NOT EXECUTED — ENVIRONMENT LIMITATION** (sem emulador/dispositivo
conectado nesta sessão) — campo do squad, cards das cartas, filtros,
bottom sheets, Time, Conta FC e Home/WL/Rivals não foram verificados
visualmente ao vivo. Verificação feita por leitura de código + teste
unitário da lógica de tamanho de card + teste ao vivo da RPC de exclusão
via SQL direto contra produção.
