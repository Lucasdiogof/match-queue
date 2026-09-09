# UI/UX Refresh (Fase B visual) — handoff

## Escopo desta etapa

Reformar a casca visual do app (navegação, Controle, Times público/privado,
Histórico, backgrounds/headers) sem tocar regra de negócio, matchmaking,
auth ou realtime. Plano completo aprovado em `AskUserQuestion`/plan mode
antes de qualquer edição; auditoria de código feita antes de escrever
qualquer linha.

## Navigation — antes/depois

**Antes**: 4 destinos (`Jogar`/`Times`/`Histórico`/`Perfil`), `Jogar` era o
branch index 0 e já era a tela de matchmaking. Sem item central destacado.

**Depois**: 5 destinos, ordem `Início | Times | Controle | Histórico |
Perfil` (`AppRoutes.control` novo, rotas antigas preservadas). Controle é o
item central — círculo elevado com acento verde (`colors.success`, já
existente no design system), sem FAB solto, sem neon. Implementado em
`lib/app/pages/app_shell_page.dart` com `_PrimaryNavItem` custom (não usa
`NavigationBar` do Material para o item central, porque o Material não
permite esse destaque sem ficar parecendo FAB). `NavigationRail`
(tablet/desktop) recebe o mesmo acento no ícone selecionado do Controle.

## Controle (novo)

`lib/features/control/presentation/pages/control_page.dart`. Reaproveita
`MatchmakingCubit`/`FcAccountsCubit`/`GameModeSelector`/`SquadSelectorRow`
como estavam — nenhuma lógica de fila foi tocada. Quando não há fila ativa
(ou nenhuma Conta selecionada), mostra 2 cards de descoberta:

- **Explorar cartas**: abre o `PlayerPickerSheet` já existente
  (`positionCode: null`) — reaproveita 100% do Squad Builder, não duplica
  nada.
- **Clubes**: mostra nome, liga, contagem de cartas e rating médio, vindos
  da RPC nova `get_fc_club_catalog_summary` (migration
  `20260929100100_fc_club_catalog_summary.sql`). Só clubes com ≥1 carta
  ativa — nunca inventa número.

Empty state próprio (`controlEmptyTitle`/`controlEmptyMessage`) — nunca uma
tela vazia sem ação, sempre com os cards de descoberta abaixo.

## Início (era "Jogar"/Home)

`lib/features/home/presentation/pages/home_page.dart` foi esvaziado do hub
de matchmaking (que foi para o Controle) e virou um resumo leve: banner de
Weekend League/partida pendente (widgets já existentes, sem alteração) +
grade de atalhos para Times/Histórico/Controle. Nunca duplica formulário.

## Times — Meus Times / Explorar

`lib/features/teams/presentation/pages/teams_list_page.dart` virou
`TabBarView` com duas abas. Ações de criar time / código de convite saíram
do empty state e foram para o header (ícones na `AppAppBar`) — pararam de
duplicar em 3 telas.

### Visibilidade Público/Privado

- **Migration** `20260929100000_team_visibility.sql`: `teams.is_public
  boolean not null default true` (times existentes viram públicos —
  comportamento pedido explicitamente, não efeito colateral). Índice
  parcial `teams_public_created_idx` para a query de Explorar.
- **RPCs** (mesmo padrão de `get_public_profile`, campo a campo, nunca
  `select *`): `set_team_visibility` (owner/admin, reaproveita
  `is_team_admin`), `list_public_teams` (só colunas seguras + contagem de
  membros), `get_public_team` (payload da página pública). Nenhuma policy
  de RLS nova — a postura "fechado por padrão" de `teams`/`team_members`
  continua intacta; a única porta de leitura pública é a RPC
  `security definer`.
- **Membros na página pública**: só aparecem nomeados se o próprio membro
  tiver o perfil público (Etapa 16) habilitado — o time nunca "destrava" a
  exposição de alguém que não optou. Retrospecto (V/D/gols) vem agregado de
  `game_matches` — nunca expõe email, token de convite ou configuração
  interna.
- **UI**: toggle Público/Privado em `TeamSettingsPage` (`_VisibilitySection`,
  admin-only). Badge de visibilidade no card de "Meus Times".

### Página pública do time

`lib/features/teams/presentation/pages/team_public_page.dart`, rota
`/app/team/public/:teamId`. Time inexistente e time privado devolvem a
mesma resposta (`found: false`) — nunca revela que um id privado existe.

## Histórico

Empty state próprio (`historyEmptyTitle`/`historyNoTeamMessage`, ícone de
timeline) — já não reusa `TeamEmptyState`. Badge de resultado (V/D) ganhou
ícone (seta cima/baixo) além da cor, para não depender só de cor
(acessibilidade a daltonismo).

## Design system

- `AppBackground` (`lib/core/design_system/components/app_background.dart`):
  textura leve reutilizável — gradiente radial sutil + linhas diagonais
  finas via `CustomPainter`, sem `BackdropFilter`/blur (perf), variante
  `dense` pra telas de detalhe. Cores lidas de `context.colors` — mesmo
  tratamento em light e dark desde o início.
- `FeatureHeader`: eyebrow + título + subtítulo curto + trailing opcional,
  usado como primeiro item do corpo rolável nas telas principais.
  `AppAppBar` continua cuidando só da barra de sistema (voltar/ações).

## O que NÃO foi feito nesta etapa (deliberado)

- Nenhuma alteração em `AppCard` — o componente já suportava `onTap`
  (ripple) e `borderColor` (estado selecionado via cor), suficiente para o
  escopo atual sem reescrever o design system.
- "Clubes" mostra só um preview horizontal — não existe página de detalhe
  de clube (não foi pedido, e criar uma exigiria decisões de produto novas).
- Nenhum teste automatizado de widget novo (o repo não tinha suíte de
  widget test antes desta etapa — só `test/tool/`). RLS/RPCs de
  visibilidade foram verificados ao vivo contra produção (ver Validação).

## Validação

- `flutter analyze`: **No issues found**.
- `dart format lib`: aplicado.
- `flutter test`: suíte completa (6 testes, `test/tool/`) — todos passam,
  nenhuma regressão.
- RPCs verificadas ao vivo contra produção (`npx supabase db query
  --linked`): `teams.is_public` default aplicado retroativamente (1/1 time
  existente virou público), `list_public_teams`/`get_fc_club_catalog_summary`
  retornam dados reais (614 clubes com carta ativa).
- QA visual: **NOT EXECUTED — ENVIRONMENT LIMITATION** (sem emulador/
  dispositivo conectado nesta sessão).

## Migrations desta etapa

- `supabase/migrations/20260929100000_team_visibility.sql`
- `supabase/migrations/20260929100100_fc_club_catalog_summary.sql`

Ambas aplicadas em produção via `npx supabase db push --linked` e
confirmadas com `--dry-run` (`upToDate: true`).

## Nota operacional

No meio desta etapa, uma leva de edições em arquivos já commitados
anteriormente (design system, rotas, entidades/repositório de Times,
l10n) foi perdida do working tree por um motivo externo a esta sessão
(não foi `git checkout`/`reset` desta sessão) — todas foram refeitas e
re-verificadas (`flutter analyze` limpo) antes do commit final. Também foi
detectada uma reescrita de histórico do `origin/main` (mesmos commits,
hashes diferentes) entre o commit anterior desta sessão e agora — resolvida
com `git rebase origin/main` (conteúdo idêntico, sem perda), nunca com
force-push.
