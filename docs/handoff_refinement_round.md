# Rodada de refinamento (23 itens) — handoff

**Status: FECHADA.** Dos 23 itens, 20 foram resolvidos (13 numa etapa
anterior + 7 nesta) e 3 (headers/background/card de modo — itens 20/23/24)
foram auditados e não têm correção de código pendente; ver seção 5.

`flutter analyze` limpo, `flutter test` 17/17 verdes, `main` sincronizado com
`origin` após o commit desta rodada.

---

## 1. O que já está FEITO (não refazer)

### Bugs críticos de fluxo — todos os 3 corrigidos

**Histórico não carregava.** Causa real: `get_team_activity_history` existia
**duas vezes** no banco. `20260916100400` usou `create or replace function`
acrescentando `p_fc_account_id` — mudar a lista de parâmetros **não
substitui**, cria uma sobrecarga. A versão de 10 argumentos ficou órfã desde
a Etapa 9. Como o cliente omite parâmetros nulos, a chamada casava com as
duas assinaturas e o PostgREST recusava escolher (PGRST203), o que a UI
mostrava como falha genérica de servidor. Migration
`20261002100000_drop_stale_activity_history_overload.sql` remove a órfã.
Conferido: era a **única** função duplicada do schema.

**Buscar não respondia depois de "partida encontrada".** `_runAction` do
`MatchmakingCubit` guardava a falha em `state.failure`, mas o card de erro só
aparece quando `status == failure`, que uma ação nunca produz. O cooldown de
30s (FQ020) ficava invisível e o botão parecia morto. Agora há um
`BlocListener` que mostra a falha. **A regra continua no servidor** — só
passou a ser dita.

**"Quero informar detalhes" não navegava.** Salvar o resultado tira a partida
da lista, o card sai da árvore e o `context` desmonta enquanto o diálogo está
aberto; o `context.push` depois dele caía num `mounted` falso, em silêncio. O
router agora é capturado **antes** do diálogo.

### Partidas pendentes (backend + Flutter)

Migration `20261002100100_pending_game_matches.sql`. Coluna
`game_matches.result_dismissed` separa **"não informar" (decisão)** de **"como
a partida terminou" (status)**. `EXPIRED` continua sendo o cron, `ABANDONED`
continua sendo "começou outra", e tudo que não foi dispensado segue
reportável depois. `default false` devolve o histórico existente ao alcance.

- `finish_game_match` aceita qualquer pendência, não só `IN_MATCH`; FQ022
  passa a significar "já resolvida". `ended_at` usa `coalesce` — reportar
  tarde não reescreve quando a partida acabou.
- `discard_game_match` marca a decisão; `dismiss_all_pending_game_matches()`
  e `list_pending_game_matches(p_limit)` são novas.
- Flutter: `PendingMatchState` virou lista (`matches`), com `match` derivado
  para não quebrar os fluxos existentes; card único na Home com contagem,
  mais recente, "Ver partidas" e "Não informar"; `pending_matches_sheet.dart`
  com a lista ordenada e ações por linha.
- **Nova busca nunca depende de resolver pendência** — preservado.

### Weekend League ≤ 15

Migration `20261002100200_weekend_league_match_limit.sql`:
`_weekend_league_max_matches()` (= 15), checagem na RPC (**FQ046**) e
constraint na tabela. Dados existentes já cabiam (12), então a constraint
entrou válida. Provado ao vivo: 10/6 é barrado. Cliente valida antes de
gastar ida ao servidor (`weekendLeagueMaxMatches`), com mensagem em PT/EN/ES.

### Realtime da tela Jogar — JÁ FUNCIONAVA, nada construído

Investigado como pedido, e a cadeia está inteira: `_notify_matchmaking_changed`
emite, `team_matchmaking_revisions` **está na publicação `supabase_realtime`**
(conferido), `MatchmakingCubit` assina por time via `_resubscribeIfNeeded` e
ainda há timer de segurança + refresh no retorno de foreground. **Não
reconstruir.**

### Outros fechados

- Aviso "o resultado informado manualmente é diferente…" **removido** (a
  string órfã também).
- Cancelar busca **sem diálogo** de confirmação.
- Menu do meio: **"Jogar"** (rótulo apenas; rota segue `AppRoutes.control`,
  para não quebrar deep link publicado).
- Ordem da tela Jogar: **Conta → Squad → Modo → card de busca**.
- Card do Squad refeito (título, formação, overall, química) e sheet rolável.
- **"Contas FC" → "Contas"** na UI (desfaz mudança da rodada anterior).
- Nomes próprios: "Division Rivals" e "Weekend League" iguais nos 3 idiomas
  (só havia um vazamento, num hint de notificação).
- Copy da busca: "Quando entrar na partida, marque que encontrou."

---

## 2. Os 10 itens restantes — fechamento desta etapa

| # | Item | O que foi feito |
| --- | --- | --- |
| 9 | WL como card na tela da Conta | **Já estava satisfeito.** `fc_account_detail_page.dart` já embute `_WeekendLeagueSection`, que resume e navega para `WeekendLeagueDetailPage`. Nenhuma tela nova criada. |
| 10 | Rivals como card na tela da Conta | **Já estava satisfeito.** Idem, via `_RivalsStatsSection` → `RivalsDetailPage`. |
| 13 | Remover "Arquivar conta" | **Feito.** Botão e `_confirmArchive` removidos de `fc_account_detail_page.dart`. `is_active` e a RPC `archiveAccount` continuam intocados no domínio/repositório — só saiu da UI. |
| 14 | "Compartilhar conta" → "Privacidade" | **Feito.** `publicProfileSectionTitle` renomeado nos 3 ARBs (PT "Privacidade", EN "Privacy", ES "Privacidad"). |
| 15 | Remover toggle "Conta pública" | **Investigado, nada a remover.** Não existe esse toggle no domínio (`PublicSharingSettings` não tem esse campo) nem na UI — a única string "Conta pública" é o rótulo de uma linha de navegação para *escolher qual conta FC* aparece no perfil público, não um switch. O switch real chama-se "Perfil público" e continua. Slug permanece próprio/editável, como decidido. |
| 16 | Pull-to-refresh em Home, Times, Jogar, Histórico | **Feito.** `RefreshIndicator` adicionado em `home_page.dart` (Teams+FcAccounts+PendingMatch), `control_page.dart` (Teams+FcAccounts), `teams_list_page.dart` (aba Meus Times e Explorar). Histórico **já tinha** (`activity_timeline_view.dart`/`matchmaking_stats_view.dart`), nada a fazer lá. Perfil não recebeu, como pedido. |
| 17 | Acessos rápidos na Home | **Feito.** Grade de atalhos ampliada de 3 para 4 itens reais (Jogar, Contas, Times, Histórico), reorganizada em 2 linhas de 2 colunas. |
| 20 | Header/background da tela Jogar | **Auditado, sem alteração de código.** Ver seção 5 — não existe "bloco verde chapado" no código atual (`feature_header.dart`/`app_background.dart` já usam apenas cor de texto e um glow radial de 5–14% de opacidade); QA visual para confirmar a leitura real na tela não foi possível nesta rodada (ver "Testes e QA visual" abaixo e seção 5). |
| 23 | Card de modo (WL / Rivals) | **Auditado, sem alteração de código.** `game_mode_selector.dart` usa `AppChip` (pílula arredondada, estado selecionado já com contraste via `colors.textPrimary`), o mesmo componente reusado nos filtros do Histórico. Nenhum defeito concreto encontrado. |
| 24 | Background/header global | **Não iniciado.** Depende do resultado real do item 20, que não pôde ser confirmado visualmente nesta rodada. |
| 25 | Filtros do Histórico | **Feito (a colisão de nomes).** `activityScopeGames` renomeado de "Partidas"/"Matches" para "Jogos"/"Games"/"Juegos" — deixa de colidir com o rótulo da aba "Partidas"/"Matches". Layout das 3 fileiras de pílulas mantido (nenhum outro defeito estrutural encontrado). |

### Testes e QA visual desta rodada

- **Testes automatizados**: não escritos por decisão do dono do produto — QA
  manual assumida por ele após o fechamento desta rodada. Suíte automatizada
  segue 17/17 (nada quebrado).
- **QA visual**: tentada via `flutter build web --no-web-resources-cdn
  --no-wasm-dry-run` + servidor local (seção 3). O app renderizou e a tela de
  login apareceu normalmente, mas o botão "Entrar" não respondeu a clique nem
  a Enter no campo de senha (sem navegação, sem banner de erro) — não foi
  possível autenticar para chegar às telas do shell (Home/Jogar/Times/
  Histórico) e comparar visualmente os itens 20/23/24. Marcado como **NOT
  EXECUTED — ENVIRONMENT LIMITATION**, não como PASS.

---

## 3. Como rodar o app (vale ouro, custou tempo)

```
flutter build web --no-web-resources-cdn --no-wasm-dry-run
python -m http.server 8099 --directory build/web
```

- **`--no-web-resources-cdn` é obrigatório**: sem ele o CanvasKit vem da CDN
  bloqueada e o app fica numa tela preta com `main()` já executado e nenhuma
  `flutter-view` montada.
- **Sem `--dart-define-from-file`** o `get_it` registra os repositórios
  locais (`LocalAuthRepository` aceita qualquer e-mail/senha, em memória) —
  QA de UI sem tocar produção.
- **Android continua impossível nesta ferramenta**: Gradle morre em
  `UnixDomainSockets.connect0` → `EINVAL`. Testado em bash e PowerShell, com
  e sem sandbox, `--no-daemon`, `TEMP` longo, `preferIPv4Stack`. No terminal
  do dono funciona.

---

## 4. Armadilhas confirmadas nesta rodada

- **`create or replace function` mudando a lista de parâmetros cria
  sobrecarga, não substitui.** Foi exatamente isso que derrubou o Histórico
  por semanas. Ao alterar assinatura, `drop function` explícito da antiga.
  Varredura de duplicadas:
  `select proname, count(*) ... group by proname having count(*) > 1`.
- **Falha de ação em cubit só aparece se a UI a exibir.** O padrão
  `status == failure` não cobre erro de ação — precisa de listener.
- **`context` de um widget que a própria ação remove não serve para navegar
  depois de um diálogo.** Capturar o router antes.
- `Transform.translate` não encolhe a caixa de layout (bug de 2px na nav,
  rodada anterior).
- **Flutter web/CanvasKit neste ambiente não expõe árvore de acessibilidade**
  (sem semantics ligado, `read_page`/`find` no navegador não acham nada) e o
  botão de login não respondeu a clique nem Enter via automação de browser,
  mesmo com texto visivelmente digitado nos campos — não foi possível
  distinguir se é limitação do driver de automação ou algo real. Não vale
  concluir bug de app a partir disso; só vale concluir que login automatizado
  não é confiável nesta ferramenta.

---

## 5. Itens 20/23/24 — por que não houve mudança de código

Os arquivos citados pela rodada anterior (`feature_header.dart`,
`app_background.dart`, `game_mode_selector.dart`) foram lidos por completo.
Nenhum "bloco verde chapado" existe hoje:

- `feature_header.dart`: o `eyebrow` usa `colors.success` só como **cor de
  texto**, não como fundo.
- `app_background.dart`: o `_PitchTexturePainter` desenha um glow radial de
  5–14% de opacidade (menor ainda na variante `dense`) + linhas diagonais de
  3,5–5% — nada perto de um bloco sólido.
- `game_mode_selector.dart`: usa `AppChip`, pílula (`AppRadii.borderPill`)
  com estado selecionado em `colors.textPrimary`, o mesmo padrão já usado nos
  filtros do Histórico.

Ou a descrição da rodada anterior falava de uma versão anterior a este
commit (já corrigida sem se dar conta), ou o efeito só aparece de fato
renderizado na tela — o que a QA visual bloqueada (seção 2) não deixou
confirmar. Por isso os itens 20/23/24 ficam **auditados, não alterados**:
mudar cor/raio/espaçamento sem ver o resultado seria redesenhar no escuro,
contra a regra desta rodada de só corrigir defeito concreto encontrado. Quem
retomar deve primeiro conseguir a QA visual funcionando (ou usar um device
físico/simulador) antes de tocar nesses três arquivos.
