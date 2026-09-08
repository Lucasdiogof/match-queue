# Handoff — Etapa 15 (Central de Notificações + eventos esportivos)

Status em 2026-09-08: **Etapa 15 FECHADA**, com um bug crítico real
encontrado e corrigido durante esta auditoria. HEAD `02e1fe7`, **70
migrations locais = 70 remotas**, `origin/main` sincronizado, árvore limpa,
`flutter analyze` sem issues. Edge Function `process-notification-outbox`
ACTIVE, versão 3, `verify_jwt: false`.

Esta é uma auditoria de uma etapa já implementada por sessões anteriores
(commits `eb2e76f`, `47b0b2a`, `8fb4879`), não uma reescrita. O texto abaixo
descreve o que foi conferido linha a linha e o único gap real corrigido.

---

## 1. Infra existente (reuso vs. mudança)

Tudo da Etapa 7 foi **reutilizado**, nada duplicado:

- `notification_outbox`, `user_devices`, `notification_preferences` (as 3
  colunas antigas de matchmaking), `claim_notification_batch`,
  `complete_notification`, `deactivate_device_token`, o trigger
  `notification_outbox_dispatch` + `pg_net`, e o cron de 1 min
  `notification-outbox-dispatch` — nenhum foi recriado, só estendidos via
  `create or replace` ou `alter table` quando necessário.
- `_notification_allowed(uuid, notification_type)` foi **estendida** (create
  or replace) para cobrir os 5 masters de categoria por cima das 3 colunas
  granulares antigas — não virou uma segunda função paralela.
- `notification_type` (enum) ganhou 6 valores novos via `alter type ... add
  value` em migration própria e isolada — obrigatório em Postgres (valor de
  enum só pode ser usado em transação posterior à que o criou).
- O worker (`process-notification-outbox/index.ts`) é o **mesmo arquivo**
  reeditado: os 6 tipos novos entram no mesmo dicionário `COPY` (PT/EN/ES),
  o mesmo `sendToToken`, o mesmo laço `Promise.all` por token. Nenhuma
  function nova foi criada.

## 2. Inbox

Tabela `user_notifications`: `user_id`, `category` (enum de 5 valores),
`type` (text, espelha `notification_type`), `title_key` + `params` (jsonb —
nunca frase pronta), `deep_link_type`/`deep_link_params`,
`source_entity_type`/`source_entity_id` (sem FK, de propósito — entidade
pode ser apagada e a notificação antiga continua legível), `dedupe_key`,
`created_at`, `read_at` nullable. Bate com o esperado, exceto por ter
`category` como coluna própria (granularidade de preferência) separada de
`type` (granularidade de ícone/copy/deep link) — decisão documentada no
próprio comentário da migration, não uma divergência acidental.

RLS: só `select` para o dono (`auth.uid() = user_id`); zero policy de
insert/update/delete — só RPCs `security definer` escrevem.

Paginação: `list_my_notifications(p_limit, p_cursor_created_at,
p_cursor_id)` é keyset por `(created_at desc, id desc)`, nunca offset.
Testado ao vivo com 5 linhas de `created_at` **idênticos** (mesma
transação) — paginação em páginas de 2 não duplicou nem perdeu item,
porque o `id` desempata corretamente mesmo com timestamp empatado.

Read/unread: `get_my_unread_notification_count`, `mark_notification_read`
(idempotente, silencioso se já lida ou de outro dono),
`mark_all_notifications_read`. Testado ao vivo: usuário B tentando marcar
notificação de A como lida não altera `read_at` (continua `null`);
`mark_all_notifications_read` zera o unread count do dono.

## 3. Event types (o que existe de fato)

Implementados, com push condicional por categoria: `TEAM_MEMBER_JOINED`,
`TEAM_LEADER_CHANGED` (+ variante "`notification_you_are_team_leader`" para
o próprio novo líder), `TEAM_TOP_SCORER_CHANGED`, `TEAM_TOP_ASSIST_CHANGED`,
`WEEKEND_LEAGUE_FINISHED`, `RIVALS_DIVISION_CHANGED`. Os 3 antigos da Etapa
7 (`YOUR_TURN`/`SEARCH_EXPIRING`/`SEARCH_EXPIRED`) continuam só-push, nunca
viraram inbox — decisão explícita, documentada no comentário da migration
(são eventos efêmeros de fila, não "algo para reabrir depois").

**Não existem, por decisão de arquitetura pré-existente, não por
esquecimento desta etapa:**

- `MATCH_FOUND` — já era decisão da Etapa 7 (comentário em
  `20260912100100_create_notification_preferences.sql`) que este evento
  nunca gera push: o próprio jogador agiu e os companheiros com o app
  aberto já veem pelo Realtime. Não há como retroagir isso sem contradizer
  uma decisão de produto anterior — documentado, não é gap desta etapa.
- `TEAM_INVITE` — o modelo de convite do projeto é por **link/código**
  (`team_invite_links`), não por convite dirigido a um usuário específico.
  Não existe "convidar fulano" no domínio, só "gerar link e compartilhar
  fora do app" — logo não há destinatário conhecido para notificar no
  momento do convite. O que existe (e cobre a intenção do item) é
  `TEAM_MEMBER_JOINED`, disparado para os membros já existentes quando
  alguém usa o link.

## 4. Dedupe — bug crítico encontrado e corrigido

**O gap real desta auditoria**: `dedupe_key` era único **globalmente**
(índice único por `dedupe_key` sozinho) tanto em `user_notifications`
quanto em `notification_outbox`. Isso nunca deu problema nos 3 tipos da
Etapa 7 porque cada evento ali tem exatamente **um** destinatário (quem
estava na vez da fila). A Etapa 15 introduziu eventos de **fan-out**: um
Time inteiro é notificado do mesmo evento (novo líder, novo artilheiro,
membro novo, WL encerrada, divisão do Rivals cair/subir). Todo o laço usa
o **mesmo** `dedupe_key` para todos os membros do Time — só muda o
`user_id`. Com o índice global, o primeiro `insert` "ganhava" a chave e
**todos os outros membros eram descartados em silêncio** pelo `on conflict
(dedupe_key) do nothing` — nunca recebiam a notificação, nem na inbox nem
no push.

Confirmado ao vivo em QA: numa troca real de artilheiro com 3 destinatários
esperados (dono + 2 membros, excluindo o autor), só 1 recebeu antes da
correção.

**Correção** (migration nova `20260924100600_fix_notification_dedupe_key_scope.sql`,
commit `02e1fe7`, já aplicada e no ar):
- `user_notifications`: índice único trocado de `(dedupe_key)` para
  `(user_id, dedupe_key)`.
- `notification_outbox`: mesma troca.
- `_enqueue_notification` (Etapa 7) e `_emit_user_notification` (Etapa 15)
  recriados via `create or replace` com `on conflict (user_id, dedupe_key)`.

Depois da correção, QA repetida confirmou: mesma troca de artilheiro agora
notifica **todos** os destinatários esperados, cada um com sua própria
linha (mesmo `dedupe_key`, `user_id` diferente).

**Multi-time**: uma Conta ligada a 2 Times gera 2 eventos distintos (um por
`team_id`, presente no próprio `dedupe_key`), nunca cruzados. **Retry**:
chamar `_emit_user_notification` duas vezes com o mesmo `(user_id,
dedupe_key)` produz 1 linha só, testado ao vivo. Reprocessar
`upsert_game_match_player_stats` com os mesmos stats (líder inalterado) não
gera notificação nova — testado ao vivo, contagem idêntica antes/depois do
retry.

`dedupe_key` é sempre determinístico: `TYPE:team_id:version` (a versão é um
contador inteiro incrementado só em troca real, nunca timestamp/random) ou
`TYPE:team_id:fc_account_id[:campo]` para eventos por Conta. Uma repetição
do mesmo evento sempre produz a mesma chave.

## 5. Anti-spam e baseline (item crítico)

Gol/assistência individual nunca gera push por si só — só
`_recompute_team_sports_leaders` (chamada depois de `finish_game_match` e
`upsert_game_match_player_stats`) decide, comparando o líder computado
agora contra `team_sports_leaders_state` (uma linha por Time, guardando
`rank_leader_user_id`/`top_scorer_key`/`top_assist_key` + um contador de
versão por campo). Só notifica quando o **identificador** muda
(`is distinct from`), nunca quando o mesmo líder só aumenta a margem.
Testado ao vivo: reprocessar o mesmo líder com os mesmos gols não gera
notificação.

**Baseline com histórico pré-existente — testado ao vivo e correto.**
Simulei o cenário real de produção: um Time com uma partida e
`game_match_player_stats` **já existentes** antes de qualquer chamada de
`_recompute_team_sports_leaders` (equivalente a um Time real que já jogava
antes da Etapa 15 existir). A primeira chamada real (disparada por uma
partida nova, líder continua o mesmo) gravou o baseline **silenciosamente**
com o líder já correto (o que já vinha ganhando) e **zero notificações**
foram geradas. Este é exatamente o cenário que o item 6 do pedido original
descreve como crítico, e está correto.

**Nuance encontrada, não é o bug do item 6, documentada como observação:**
para um Time **totalmente novo** (zero partidas antes da Etapa 15),
`finish_game_match` chama `_recompute` **antes** dos stats da própria
partida serem gravados (que só acontece depois, em
`upsert_game_match_player_stats`). Isso significa que a primeiríssima
chamada de todas grava baseline com `top_scorer_key = null`, e a chamada
seguinte (já com os stats reais) vê uma transição de `null` para o
primeiro valor real — o que o código trata como "mudança real" e notifica
os outros membros do time sobre o "primeiro artilheiro". Isto é diferente
do problema que o item 6 descreve (dado histórico retroagindo notificação
em Time já existente, que está correto) — é apenas o Time **zerado**
recebendo um aviso de "primeiro artilheiro" no dia zero, o que é
defensável como comportamento de produto (é uma novidade real, não ruído
de backlog). Deixo registrado como nuance de arquitetura, não como pendência
a corrigir agora — mudar a ordem de chamada (não recomputar em
`finish_game_match`, só em `upsert_game_match_player_stats`) resolveria,
mas não foi pedido e o efeito prático é bem mais brando que o cenário
crítico do item 6.

## 6. Preferences

5 categorias (`matchmaking_enabled`, `teams_enabled`,
`weekend_league_enabled`, `rivals_enabled`, `rankings_enabled`), todas
default `true`, coluna nova em `notification_preferences` (reaproveitada,
não recriada). Matchmaking mantém as 3 colunas granulares antigas por
baixo do master switch (desligar a categoria desliga as 3 de uma vez, sem
perder a granularidade fina para uso futuro).

**Inbox e push são responsabilidades separadas de verdade** —
confirmado no código e ao vivo: `_emit_user_notification` sempre insere em
`user_notifications` primeiro; só *depois* de confirmar que a linha é nova
é que verifica `_notification_allowed` para decidir se also enfileira
push. Testado ao vivo: usuário com `rankings_enabled = false` recebeu a
linha na inbox normalmente, e **zero** linha na outbox para esse evento —
outro usuário do mesmo evento (preferência ligada) recebeu os dois.

UI (`NotificationSettingsCubit`/`NotificationSettingsSection`): escrita
otimista com rollback em falha, permissão do sistema tratada à parte
(banner de "ativar" / "negado" / "não suportado"), lida de verdade via
`fetchPreferences`/`savePreferences`.

## 7. Worker/FCM

- Multi-device: `claim_notification_batch` agrega todos os `fcm_token`
  ativos do usuário num único array `tokens` por linha da outbox; o worker
  faz `Promise.all` mandando para cada token, mas só chama
  `complete_notification` **uma vez** por linha (`anyDelivered = algum
  token recebeu`). Ou seja: **1 notificação de inbox → 1 linha de outbox →
  N envios FCM**, nunca N linhas de outbox. Confirmado por leitura de
  código (estrutural, não dependia de device físico para essa parte).
- Invalid token: `DEAD_TOKEN_ERRORS` (`UNREGISTERED`, `INVALID_ARGUMENT`,
  `SENDER_ID_MISMATCH`) chama `deactivate_device_token` por token,
  reaproveitando a RPC da Etapa 7 sem mudança.
- Versão da Edge Function: **3**, `ACTIVE`, `verify_jwt: false`
  (confirmado via `npx supabase functions list`).
- Locale do push: `coalesce(profiles.locale, 'en')`, populado por
  `claim_notification_batch`; o worker escolhe PT/EN/ES a partir disso. A
  inbox **não** depende disso — o Flutter resolve `title_key` + `params`
  via `AppLocalizations` no idioma corrente do app
  (`NotificationCopyResolver`), client-side, confirmado no código.

## 8. Flutter

- Sino com badge (`NotificationBellButton`, wired na Home), tela
  `NotificationsInboxPage` com estados loading/error+retry/empty/lista
  agrupada (Hoje/Ontem/Antes), pull-to-refresh (`RefreshIndicator`),
  paginação por scroll (`loadMore` a 320px do fim), destaque visual de não
  lida (borda + ponto, cor `info`, nunca vermelho — respeita a regra
  "zero vermelho" já usada no restante do app), mark-read ao abrir
  (`markRead` disparado antes de navegar).
- Deep links reais confirmados por leitura de código:
  `NotificationDestinationResolver` (tap na inbox) e `NotificationRouter`
  (tap no push/cold start) resolvem para `TeamDetailPage` (todos os 6 tipos
  sociais/esportivos carregam `team_id`) ou `FcAccountDetailPage`
  (`RIVALS_DIVISION_CHANGED` quando só há `fc_account_id`). Todos os
  destinos existem de verdade e são alcançáveis.
  **Observação de arquitetura, não bloqueante**: o backend grava
  `deep_link_type`/`deep_link_params` por evento (`team_ranking`,
  `team_leaderboard`, `team_rivals`, `team_weekend_league`, `team_detail`)
  pensando em destinos mais específicos (`WeekendLeagueDetailPage`,
  `RivalsDetailPage` já existem desde a Etapa 12, por Conta), mas o
  resolver do cliente **ignora esses dois campos** e infere o destino
  direto de `params['team_id']`/`params['fc_account_id']`. Hoje isso nunca
  produz destino errado (todo evento atual tem `team_id` presente e o
  `TeamDetailPage` da Etapa 14 já mostra ranking/artilharia/WL/Rivals do
  Time), mas os campos ficam com dado morto no cliente. Não é uma
  regressão nem um link quebrado — registrado para eventual faxina, não
  para correção agora.
- Auth/logout: `deactivateForSignOut()` chamado **antes** de
  `authCubit.signOut()` (confirmado em `profile_page.dart`), badge zerado
  no `BlocListener<AuthCubit>` quando `isAuthenticated` vira falso — troca
  de conta no mesmo device não vaza unread count nem lista antiga (a tela
  sempre recarrega do backend ao abrir).

## 9. Security

- `user_notifications`: RLS com única policy de `select` filtrando
  `auth.uid() = user_id`; zero policy de insert/update/delete; grant
  restrito a `select` para `authenticated`. Cliente não tem como inserir
  notificação para si mesmo, muito menos para outro usuário.
- Todas as RPCs de escrita (`mark_notification_read`,
  `mark_all_notifications_read`) filtram por `auth.uid()` nas próprias
  cláusulas `where`, testado ao vivo (usuário B não conseguiu marcar
  notificação de A como lida).
- Eventos são sempre gerados server-side, dentro das mesmas RPCs que já
  validavam ownership (`finish_game_match`, `upsert_game_match_player_stats`,
  `join_team_by_invite`, `update_rivals_division`) — nenhuma RPC nova e
  exposta para o cliente cria notificação diretamente.
- Membership sempre lida **no momento do evento**: todo laço de
  notificação usa `public.team_members` (estado atual), nunca uma foto
  antiga. Testado ao vivo: removi um membro do Time no meio do teste e o
  próximo evento real não o notificou (a inbox antiga dele continuou
  existindo, como esperado).

## 10. Validation (o que rodei de verdade, com dados temporários limpos ao final)

Tudo abaixo foi executado contra o projeto remoto real
(`lteujeclnhmurcewurkg`) com usuários/times/contas/partidas temporários,
**removidos ao final de cada rodada** (confirmado por contagem zero em
todas as tabelas envolvidas, inclusive `auth.users`, antes de fechar):

1. Baseline com histórico pré-existente não notifica — **verde** (seção 5).
2. Troca real de líder/artilheiro notifica os destinatários certos,
   excluindo o autor — **verde após a correção do dedupe_key** (antes da
   correção, só 1 de N destinatários recebia).
3. Mesmo líder aumentando stats não renotifica (retry de
   `upsert_game_match_player_stats` com os mesmos números) — **verde**.
4. Retry literal do emissor com `dedupe_key` repetido não duplica —
   **verde**.
5. Push OFF (categoria RANKINGS) + inbox ON para o mesmo evento — **verde**:
   o usuário recebeu a linha da inbox e zero linha na outbox; outro
   usuário do mesmo evento (preferência ligada) recebeu os dois.
6. Membro removido do Time não recebe evento novo depois da remoção —
   **verde**.
7. Paginação keyset com múltiplas linhas de `created_at` idêntico não
   duplica nem perde item entre páginas — **verde**.
8. Outro usuário não lê/marca notificação alheia (`mark_notification_read`
   como não-dono não altera `read_at`) — **verde**.
9. `mark_all_notifications_read` zera o unread count do dono — **verde**.
10. Multi-device (2 tokens do mesmo usuário) gera 1 linha de outbox, nunca
    2 — confirmado por leitura de código (`claim_notification_batch`
    agrega tokens num array; `complete_notification` chamado uma vez por
    linha). Não testado com envio real de FCM (ver pendências).
11. Migrations 70 locais = 70 remotas — **verde** (`npx supabase migration
    list`).
12. Edge Function versão 3, `ACTIVE`, `verify_jwt: false` — **verde**
    (`npx supabase functions list`).

**Não testado de ponta a ponta** (pendência por limitação de ambiente, não
por defeito — mesma situação documentada desde a Etapa 7): entrega física
de push num device Android/iOS real. O caminho de envio (worker → OAuth2 →
FCM v1) já foi validado ponta a ponta na Etapa 7 e o código dos 6 tipos
novos reaproveita exatamente o mesmo `sendToToken`, sem lógica nova nesse
trecho — não há motivo para suspeitar que os tipos novos se comportem
diferente dos antigos nesse aspecto, mas não há como *ver* a notificação
chegar sem um device físico.

## 11. Git

```
02e1fe7  Scope notification dedupe_key to the recipient, not the whole table   <- corrigido nesta auditoria
8fb4879  Wire up a notification center: bell, inbox page, per-category settings
47b0b2a  Add the notification inbox domain and data layer
eb2e76f  Add per-category notification preferences and event hooks
```

- Migrations: **70 locais = 70 remotas** (`npx supabase migration list`
  confirmado após o push da correção).
- Edge Function `process-notification-outbox`: **versão 3**, `ACTIVE`,
  `verify_jwt: false`.
- `flutter analyze`: **No issues found** (rodado uma vez, no fechamento,
  conforme a regra do projeto).
- Working tree: limpo, tudo pushado em `origin/main`.
- Nenhuma migration aplicada foi editada — a correção do dedupe_key é uma
  migration nova (`20260924100600`), como manda a convenção.

## 12. Pendências conscientes

**Corrigido nesta auditoria (não é mais pendência):**
- Bug crítico de `dedupe_key` global impedindo fan-out para múltiplos
  destinatários do mesmo evento — corrigido e validado ao vivo (seção 4).

**Depende de configuração externa real, não corrigível neste ambiente:**
- Confirmação visual de push chegando num device Android/iOS físico —
  mesma pendência de ambiente já registrada desde a Etapa 7 (`flutter build
  apk` falha no loopback do Gradle deste Windows; iOS precisa de Mac). O
  caminho de envio já foi provado ponta a ponta contra o FCM real na Etapa
  7, e os 6 tipos novos reaproveitam o mesmo código de envio sem lógica
  nova.

**Diferenças de escopo por decisão de arquitetura pré-existente, não
esquecimento:**
- `MATCH_FOUND` nunca gera push nem inbox — decisão da Etapa 7 (Realtime já
  cobre a tela de quem está com o app aberto).
- `TEAM_INVITE` não existe como tipo de notificação porque o modelo de
  convite é por link/código, sem destinatário conhecido no momento do
  convite — `TEAM_MEMBER_JOINED` cobre a intenção do item quando alguém
  efetivamente entra.

**Observação de arquitetura, não bloqueante, candidata a faxina futura:**
- Time totalmente novo (zero histórico) recebe uma notificação de
  "primeiro artilheiro/líder" na primeira partida, por causa da ordem de
  chamada entre `finish_game_match` e `upsert_game_match_player_stats`
  (seção 5). Efeito brando (evento real, não backlog), documentado, não
  corrigido agora.
- `deep_link_type`/`deep_link_params` gravados pelo backend mas ignorados
  pelo resolver do cliente (seção 8) — nunca produz link errado hoje, mas
  é dado morto que poderia ser aproveitado numa faxina futura.

---

## Fechamento contra os ~19 itens do pedido original

1. **Infra da Etapa 7 reutilizada, não duplicada** — ✅ fechado (seção 1).
2. **Inbox persistente com o schema esperado** — ✅ fechado, com a
   diferença documentada de `category` ser coluna própria (seção 2).
3. **Inbox vs. push são responsabilidades separadas** — ✅ fechado e
   testado ao vivo (seção 6).
4. **Tipos/eventos auditados, faltantes listados conscientemente** — ✅
   fechado; `MATCH_FOUND` e `TEAM_INVITE` documentados como decisão de
   arquitetura, não esquecimento (seção 3).
5. **Anti-spam (gol/assistência individual nunca vira push sozinho)** — ✅
   fechado e testado ao vivo (seção 5).
6. **Baseline de ranking não notifica retroativamente** — ✅ fechado e
   testado ao vivo com histórico pré-existente simulado (seção 5); nuance
   de Time zerado documentada, não bloqueante.
7. **Multi-time/dedupe determinístico, sem duplicata** — ✅ fechado **após
   a correção crítica** encontrada e aplicada nesta auditoria (seção 4).
8. **Preferências por categoria, defaults, persistência, UI funcional** —
   ✅ fechado (seção 6).
9. **Matchmaking preservado (MATCH_FOUND prioritário, queue alerts
   intactos, push nunca decide estado)** — ✅ fechado, infra intocada.
10. **Paginação keyset, sem duplicar/perder item** — ✅ fechado e testado
    ao vivo (seção 2/10).
11. **Read/unread completo (unread count, mark one/all, só o dono)** — ✅
    fechado e testado ao vivo (seção 2/10).
12. **Flutter completo (sino, tela, empty/error/retry, pull-to-refresh,
    paginação, destaque visual, mark-read ao abrir)** — ✅ fechado
    (seção 8).
13. **Deep links reais** — ✅ fechado; todos os destinos existem e são
    alcançáveis, com observação de arquitetura sobre campos não usados
    (seção 8).
14. **Auth/logout limpa estado, sem vazamento entre contas** — ✅ fechado
    (seção 8).
15. **Múltiplos devices → 1 inbox, N pushes** — ✅ fechado, confirmado por
    leitura de código (seção 7).
16. **Invalid tokens desabilitados pelo worker** — ✅ fechado, reuso direto
    da Etapa 7 (seção 7).
17. **Locale do push e da inbox documentado** — ✅ fechado, ambos
    confirmados (seção 7).
18. **Segurança (RLS/RPC, sem insert arbitrário, membership atual)** — ✅
    fechado e testado ao vivo (seção 9).
19. **Membro removido não recebe eventos novos do Time** — ✅ fechado e
    testado ao vivo (seção 9/10).

**A Etapa 15 fecha** pelo critério do dono do produto, com um bug crítico
real encontrado e corrigido durante esta própria auditoria (item 7) e uma
única pendência genuína de ambiente (confirmação visual de push em device
físico), na mesma situação já aceita desde a Etapa 7. Não avancei para a
Etapa 16.
