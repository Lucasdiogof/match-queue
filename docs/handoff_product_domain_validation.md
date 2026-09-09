# Validação do domínio do produto — handoff

Auditoria do app inteiro contra a lógica de produto, seguida da correção do
que divergia. **Auditoria feita no código, não nos handoffs**: boa parte do
pedido já estava implementada nas duas rodadas anteriores
(`handoff_ui_refresh.md` e `handoff_gameplay_flows_refresh.md`), e confirmar
isso lendo o código evitou reconstruir o que já funcionava.

## 1. O modelo, escrito uma vez

```
Usuário do FIFA Queue          auth.users / profiles
└── Conta FC ("Lucksrei")      user_fc_accounts
    ├── N:N com Times          fc_account_teams
    ├── Squad / Escalação      fc_squads
    ├── Division Rivals        user_fc_accounts.rivals_division
    └── Weekend League         fc_account_weekend_league_progress

Time (grupo social)            teams / team_members
└── N:N com Contas FC          fc_account_teams
```

Responsabilidade de cada peça:

| Entidade | É | Não é |
| --- | --- | --- |
| **Usuário** | a conta autenticada do app | um jogador de time |
| **Conta FC** | um perfil de Ultimate Team que o usuário declara gerenciar | criada no jogo pelo app |
| **Time** | grupo social do app | um clube do jogo |
| **Squad** | escalação de **uma** Conta FC | o time |
| **Rivals** | estado atual da Conta FC (divisão) | registro obrigatório partida a partida |
| **Weekend League** | semana competitiva da Conta FC | do Time |
| **Matchmaking** | quem do grupo pode buscar agora | registro de resultado |
| **Histórico** | consulta do que aconteceu | dashboard |
| **Perfil público** | opt-in, por Conta FC | a visibilidade dentro do Time |

O membro real do Time é a **Conta FC vinculada**, não o usuário autenticado.

## 2. Já estava correto — confirmado no código

Nada aqui foi reconstruído. Cada item foi verificado na fonte indicada.

| Regra | Onde | Evidência |
| --- | --- | --- |
| N:N Conta FC ↔ Time | `fc_account_teams` + RPCs `link_/unlink_fc_account_to_team` | Etapa 9 |
| Conta FC obrigatória antes de Time | `create_team_sheet.dart`, `join_team_page.dart` | gameplay refresh |
| Buscar exige Conta FC vinculada a Time | `request_match_search` | **FQ035** explícito |
| Conta FC precisa ser do usuário | `request_match_search` | **FQ025** |
| Lock server-authoritative | `_lock_teams_matchmaking`, `_teams_free_for_search` | nada no client decide |
| Resultado não bloqueia nova busca | `request_match_search` | só cooldown de 30s, por tempo |
| Times público/privado | `teams.is_public`, `list_public_teams`, `get_public_team` | privado e inexistente devolvem a mesma resposta |
| Picker anti-duplicação | `search_fc_player_cards(p_exclude_card_ids)` | verificado ao vivo |
| Imagens das cartas | `player_image_url`/`card_image_url` | populadas pelo importer real |
| Campo sem overlap | `cardWidthForFormation` | 5 testes unitários |
| Bottom sheet + filtros hierárquicos | `AppBottomSheet.isChildScrollable`, `catalog_picker_sheet.dart` | overflow de 7178px corrigido na raiz |
| Cadastro de Conta FC só com nick | `create_fc_account_sheet.dart` | um campo só, como pedido |
| Navegação de 5 abas com Controle central | `app_shell_page.dart` | UI refresh |
| Rivals como estado, não partida a partida | `update_rivals_division` | Etapa 9 |
| WL resumo **e** detalhado, nenhum obrigatório | `manual_wins/losses` + `weekend_league_event_id` | "computado nunca é somado ao manual" |

## 3. Divergências encontradas e corrigidas

### 3.1 A Home bloqueava pela entidade errada

`home_page.dart` fazia `if (selected == null) return TeamEmptyState()`, onde
`selected` era o **Time**. Consequência real: quem tinha Conta FC mas nenhum
Time via um convite pra criar time e **nada de si mesmo** — nem Rivals, nem
Weekend League, que são da Conta FC e existem antes de qualquer Time. A ordem
correta estava invertida na tela.

Além disso a Home não tinha **nenhuma** presença de Conta FC: sem CTA pra
primeira, sem mostrar a ativa, sem trocar entre várias.

Correção: `HomeFcAccountCard` no topo — zero contas mostra
`FcAccountOnboardingCard` (o mesmo do Controle, não uma cópia), uma conta
mostra a ativa, várias reusam `showFcAccountSwitcherSheet`, que já existia. O
convite pra entrar num Time virou um card no fluxo, nunca um bloqueio.

### 3.2 Não havia como não informar o resultado

O backend já tratava resultado como opcional — partida sem resultado nunca
bloqueou busca nova, e começar outra marcava a anterior como `ABANDONED`. O
que faltava era a saída explícita: o card oferecia só Vitória, Derrota e
Adicionar placar, então quem não queria registrar tinha que esperar 20 minutos
ou buscar de novo só pra limpar o card.

`discard_game_match(p_match_id)` fecha a partida como `ABANDONED` — não
`EXPIRED`, que é o cron dizendo que ninguém respondeu; aqui é decisão do dono.
A constraint `game_matches_result_consistency` já garante que `ABANDONED` não
carrega resultado, então **não registrar continua diferente de registrar
derrota**.

### 3.3 O histórico parava em "achou partida"

`MatchHistoryEntry` só tinha a **busca**: quando começou, quanto durou, como
terminou, quem buscou. A partida que saiu dela — Conta FC, modalidade,
resultado, placar — não chegava na tela.

`get_team_match_search_history` passou a trazer essa dimensão, com duas
correções de leitura que apareceram no caminho:

- **Escopo do Time.** O filtro era `s.team_id = p_team_id`, mas uma busca toca
  N Times e a sessão guarda só o primeiro em `team_id`. O Time B era cego a
  toda busca que o Time A liderou. Virou `EXISTS` sobre
  `match_search_session_teams` — o mesmo padrão que o dashboard esportivo já é
  obrigado a usar, justamente porque filtra sem multiplicar linha. Conferido
  antes de aplicar: **0 sessões sem vínculo**, então nenhuma linha existente
  sai do resultado.
- **Uma partida por linha.** Não há unique index em
  `game_matches.search_session_id`; um join direto poderia duplicar a sessão.
  Lateral com `limit 1` fecha isso por construção.

`result` nulo renderiza como **"Resultado não informado"**, nunca como
derrota. Coberto por teste.

### 3.4 Weekend League não tinha semanas

Só existia **um** evento no banco inteiro, semeado como placeholder na Etapa
8.5, e nenhuma forma de criar outro. Não havia o que selecionar.

E a janela estava errada de um jeito que o dado provou: o evento começava em
`2026-10-02T00:00Z`, que no Brasil é **quinta 21:00**. A semana é sexta 00:00 →
segunda 00:00 no fuso local, então a fronteira tem que ser calculada em
`America/Sao_Paulo` e guardada como o instante resultante — exatamente o bug de
UTC/local que o pedido mandava evitar.

A autoridade continua no banco, como o schema original decidiu (a janela real
varia por season, ninguém calcula semana no cliente). O que faltava era o
gerador:

| Função | Papel |
| --- | --- |
| `_weekend_league_week_start(ts)` | sexta 00:00 local da semana que contém o instante |
| `_weekend_league_season_anchor()` | âncora fixa da numeração, derivada e não digitada |
| `ensure_weekend_league_events(back, forward)` | povoa o calendário, idempotente |
| `list_weekend_league_events(limit)` | semanas já iniciadas, pro seletor |

**Numeração é a sequência do app, não o número oficial da EA.** O calendário
oficial não é conhecido aqui e não foi inventado.

O evento placeholder foi corrigido **in place** (mesmo id, janela certa) porque
tinha 0 partidas e 0 registros manuais apontando pra ele — conferido antes.

Na tela: `WeekendLeagueWeekSelector` + `showWeekendLeagueWeekPicker`, e o
`weekend_league_event_model.dart` que estava órfão desde a Etapa 9 finalmente
tem uso.

## 4. Validação executada

Contra produção, com dado real:

- `discard_game_match`: `security definer`, `search_path=""`, executável só
  por `authenticated` (`anon` e `service_role` fora).
- Histórico: **0 sessões sem vínculo** em `session_teams` (a troca de filtro
  não perde linha), **0 sessões com mais de uma partida**, e a leitura real
  devolveu conta `Lucao FC`, modo `WEEKEND_LEAGUE`, `FINISHED`/`WIN` **sem
  placar** — o caso em que a tela não pode inventar número.
- Weekend League: 5 semanas geradas, **todas começando sexta** no fuso do
  Brasil, `starts_at` distintos, e `ensure_weekend_league_events()` inserindo
  **0** na segunda execução (idempotência).
- Fronteira da semana testada nos extremos: domingo 23:59 cai na semana
  certa, segunda 00:30 já está fora da janela.

`flutter analyze`: **No issues found**. `flutter test`: **17 testes, todos
verdes** (11 anteriores + 6 novos).

## 5. QA visual

**NOT EXECUTED — ENVIRONMENT LIMITATION.** Sem emulador nem dispositivo
conectado nesta sessão. Home, card de descarte, linha do histórico e seletor
de semana não foram vistos rodando. A verificação foi por leitura de código,
teste unitário e execução real das RPCs contra produção.

## 6. O que continua pendente

Nada desta rodada ficou pela metade. Segue de antes, sem relação com o que foi
auditado aqui:

- **Escopo do histórico por sessão-time** agora é correto, mas
  `fc_account_teams` continua **sem histórico temporal** — o vínculo vale
  "agora", inclusive para partidas anteriores a ele.
- Numeração de semana não corresponde ao número oficial da EA (ver 3.4).
- Empates: o domínio é WIN/LOSS e nenhum DRAW foi inventado.
- Testes de RLS/ownership/lock pedidos no item 31: **não adicionados**. O
  repositório não tem harness de integração contra o Supabase, e teste de RLS
  sem isso seria encenação. As garantias foram verificadas ao vivo (seção 4).
  Montar esse harness é trabalho próprio, não um apêndice desta rodada.
- Revisão linguística PT/EN/ES completa e QA visual seguem para a etapa final.
