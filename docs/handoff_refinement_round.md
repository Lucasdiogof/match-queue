# Rodada de refinamento (23 itens) — handoff

**Status: INCOMPLETA — interrompida por limite de uso.** 13 dos 23 itens
fechados. Este documento existe para retomar em outra conta sem perder nada.

HEAD ao interromper: `82c25a1`. `flutter analyze` limpo, `flutter test` 17/17
verdes, 85 migrations locais = remotas, `main` sincronizado com `origin`.

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

## 2. O que FALTA (10 itens)

Nenhum deles foi começado — não há trabalho pela metade em disco.

| # | Item | Observação para quem retomar |
| --- | --- | --- |
| 9 | **WL como card na tela da Conta** | `RivalsDetailPage` e `WeekendLeagueDetailPage` **já existem** — reusar, não criar tela nova. Hoje `fc_account_detail_page.dart` embute as seções. |
| 10 | **Rivals como card na tela da Conta** | idem. A seção de divisão já foi adicionada dentro de `RivalsDetailPage` na rodada anterior. |
| 13 | Remover "Arquivar conta" | Só tirar da UI. Não dropar `is_active` nem a RPC. |
| 14 | "Compartilhar conta" → **"Privacidade"** | `sharing_settings_section.dart`. |
| 15 | Remover toggle "Conta pública" | **Decidido pelo dono**: o endereço/slug do perfil **continua como está** (identificador próprio, editável). NÃO derivar do nome da conta — isso evitaria o problema de unicidade que não existe mais. Perfil público continua. |
| 16 | **Pull-to-refresh** em Home, Times, Jogar, Histórico | Perfil **não**. Não duplicar request nem derrubar Realtime. |
| 17 | Acessos rápidos na Home | Mais itens, componentes melhores, navegação real. |
| 20 | **Header/background da tela Jogar** | Tirar o bloco verde chapado, cantos arredondados, espaçamento. Arquivos: `feature_header.dart` (o eyebrow usa `colors.success`) e `app_background.dart` (`_PitchTexturePainter`, glow radial + linhas diagonais). |
| 23 | Card de modo (WL / Rivals) | `game_mode_selector.dart`. Espaçamento e estado selecionado. |
| 24 | **Background/header global** | O tratamento do item 20 vira linguagem global: Home, Times, Jogar, Histórico, Perfil, Contas, Conta detalhe, WL, Rivals, Squad Builder. Sistema reutilizável, **não** copiar header idêntico; cada tela mantém identidade. |
| 25 | **Filtros do Histórico** | Hoje 3 fileiras de pílulas: (Partidas\|Estatísticas), (Sempre\|7\|30\|90), (Tudo\|Partidas\|Buscas). Refazer sem mudar semântica. **Achado próprio**: "Partidas" aparece 2× com sentidos diferentes (aba e valor de filtro) — colisão real de nome. Arquivos: `filter_chip_row.dart`, `history_page.dart`. |

### Também pendente

- **Testes** dos itens desta rodada (WL > 15, nova busca pós-match, múltiplas
  pendências, não informar, navegação de "informar detalhes"). Nenhum
  adicionado — a suíte segue 17/17 do que já existia.
- **QA visual** desta rodada: não executado.

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
