# Launch Gap Analysis — auditoria pré-lançamento (Etapa 17)

Status em 2026-09-08. Esta é uma **auditoria**, não uma etapa de
implementação: nenhuma feature nova foi construída. HEAD confirmado
`28ecdf9` = `origin/main`, árvore de trabalho limpa, 71 migrations locais
= 71 remotas, `flutter analyze` — **No issues found** (confirmado rodando
de novo nesta auditoria).

Metodologia: leitura de todos os `docs/handoff_etapa*.md` (7 a 16) e
`architecture.md`/`database.md`, seguida de inspeção direta do código
(`lib/features/*`, rotas, DI, `supabase/migrations/`, `supabase/functions/`,
config Android/iOS/Web) via grep dirigido e leitura pontual — não uma
leitura linha a linha das 71 migrations. Onde o código e a documentação
divergem, o veredito é sempre o código.

---

## 1. Resumo executivo

O FIFA Queue tem um **backend excepcionalmente maduro** para o estágio do
projeto: 71 migrations consistentes, todo acesso passando por RPC
`security definer` com `search_path=''`, RLS habilitada em toda tabela
tocada, zero policy solta, grants para `anon` restritos a exatamente dois
endpoints públicos intencionais (resolver convite, perfil público). O
domínio (matchmaking multi-time, squad builder com química, notificações
com dedupe por destinatário, stats por partida) foi implementado com
disciplina de engenharia rara — inclusive um bug crítico real de
fan-out de notificação foi encontrado e corrigido pela própria etapa
anterior antes de fechar.

O que falta para um lançamento real **não é o produto em si — é tudo que
cerca o produto**: zero teste automatizado, zero CI/CD, sem assinatura de
release configurada (Android usa a chave de debug), sem Política de
Privacidade/Termos, sem exclusão de conta (bloqueador de App Store/Play
Store), e um nome de produto (`FIFA Queue`) que carrega risco real de
marca registrada ao citar "FIFA", "EA SPORTS FC" e "Ultimate Team"
diretamente em nome do app, descrição e strings visíveis ao usuário. O
catálogo real de cartas FC27/FC26 continua vazio — mas isso é uma
limitação **externa** já bem documentada (Etapa 11) e o app funciona
inteiro sem ele.

Em uma frase: **o produto funciona e o backend está pronto para
produção; o pacote de lançamento (legal, loja, QA automatizado) não foi
começado.**

---

## 2. Percentuais de conclusão

| Dimensão | % | Peso | Por quê |
| --- | --- | --- | --- |
| Product Features | 82% | 25% | 16 etapas fechadas cobrindo todo o domínio central; gaps são conscientes (Icons/Heroes na química, season em Rivals) ou externos (catálogo FC27) |
| Backend/Data | 90% | 20% | Migrations consistentes, RLS/security definer/search_path uniformes em ~177 funções, dedupe correto, snapshot imutável, zero divergência achada nesta auditoria |
| UX Completeness | 78% | 15% | Fluxos ponta-a-ponta existem e têm estado vazio/erro tratado; nunca passou por QA visual real nem revisão de responsividade em dispositivo |
| Security | 85% | 15% | Postura estática forte; puxa nota pela ausência de exclusão de conta/exportação de dados e por não ter havido pentest/revisão externa |
| Localization | 70% | 5% | 752 chaves × 3 idiomas com paridade estrutural exata; nunca passou por revisão linguística de um falante nativo de cada idioma |
| Test/QA readiness | 5% | 10% | **Zero arquivo de teste automatizado no repositório inteiro** (`test/` não existe) |
| Release/Store readiness | 15% | 10% | Sem CI/CD, sem assinatura de release, sem Política de Privacidade/Termos, sem exclusão de conta, risco de marca não avaliado formalmente |
| **Overall weighted** | **≈ 68%** | 100% | Média ponderada pelos pesos acima |

**Explicação dos pesos**: Product Features e Backend/Data pesam mais
(25%+20%=45%) porque são o que efetivamente define "o app funciona" — e
é onde este projeto está mais forte. Test/QA e Release/Store juntos
valem 20% porque, apesar de hoje quase zerados, são bloqueadores binários
de lançamento (não dá para publicar sem eles, não importa quão bom o
resto esteja) — não pesam mais que isso porque ausência de teste
automatizado não significa app quebrado (a disciplina de "validação
pontual ao vivo contra o Supabase remoto" documentada em cada handoff
supre parte do papel que testes teriam). Security e UX pesam 15% cada
por serem necessários mas não bloqueadores de lançamento por si só no
estágio atual (nenhuma vulnerabilidade concreta foi encontrada).
Localization pesa só 5% porque a estrutura já está pronta — falta
revisão, não trabalho de implementação.

---

## 3. Matriz de features

| Área | Status | % | Blocker? | O que falta |
| --- | --- | --- | --- | --- |
| Auth (signup/login/logout/reset/restore) | COMPLETE | 95% | Não | Confirmação de e-mail desligada por decisão de produto; sem verificação adicional de força de senha além do mínimo |
| Profiles | COMPLETE | 100% | Não | — |
| Teams / Convites (link/código) | COMPLETE | 100% | Não | Convite dirigido a usuário específico não existe (decisão de arquitetura, não gap) |
| Matchmaking multi-time | COMPLETE | 100% | Não | — |
| Realtime (fila/status) | COMPLETE | 100% | Não | — |
| Notifications (push + inbox) | COMPLETE | 95% | Não | Confirmação visual em device físico Android/iOS pendente (limitação de ambiente, não de código) |
| History / Activity | COMPLETE | 100% | Não | — |
| Weekend League / Rivals | COMPLETE | 90% | Não | Season/semana não modelada em Rivals (decisão consciente, all-time) |
| Squad Builder / Chemistry / Overall | COMPLETE | 95% | Não | Icons/Heroes não têm exceção de química; PlayStyle+ não separado |
| Catálogo de cartas (fc_players/fc_player_cards) | PARTIAL — EXTERNAL-BLOCKER | 100% código / 0% dado | Não (app funciona vazio) | Dataset real FC27/FC26 nunca importado — bloqueio de fonte de dados externa, não de código |
| Gols/Assistências/Stats de partida | COMPLETE | 100% | Não | Minuto do gol, posse, cartões, xG fora de escopo (decisão) |
| Team Dashboard esportivo | COMPLETE | 100% | Não | Hall histórico de ex-membros fora de escopo (decisão) |
| Perfil Público / Sharing | COMPLETE | 95% | Não | Universal links nativos (AASA/App Links) e QR code não implementados (aceitos como fora de escopo) |
| Settings (Aparência/Idioma/Notificações) | COMPLETE | 100% | Não | — |
| Web | COMPLETE (sem push) | 90% | Não | Push Web adiado por decisão (VAPID/service worker/domínio) |
| Firebase (Messaging/Crashlytics) | CODE READY | 90% código | Não p/ dev, sim p/ prod real | Config gitignorada existe localmente; build de release Android/iOS num device físico nunca confirmado visualmente |
| Android/iOS build config | PARTIAL | 40% | **Sim, para loja** | Assinatura de release usa chave de debug (`signingConfig = signingConfigs.getByName("debug")`), sem `key.properties` |
| Privacidade/Termos | MISSING | 0% | **Sim, para loja** | Nenhuma tela, nenhum texto — nada encontrado no app inteiro |
| Exclusão de conta | MISSING | 0% | **Sim, para loja (Apple exige desde 2022)** | Nenhuma RPC, nenhuma UI |
| Analytics real | PARTIAL/DEAD | 10% | Não | `AnalyticsService` registrado só como stub de log; nenhum evento de negócio instrumentado de verdade |
| Crashlytics | PARTIAL | 60% | Não | Captura de crash automática ligada no bootstrap; abstração `CrashReporter` de app é stub de log, quase não usada nas features |
| CI/CD | MISSING | 0% | Recomendado, não bloqueador técnico | Nenhum `.github/` |
| Testes automatizados | MISSING | 0% | **Sim, para confiança de release contínuo** | `test/` não existe; zero arquivo `_test.dart` no repo inteiro |
| Marca/Trademark | NÃO AVALIADO FORMALMENTE | — | Risco real | Nome do app, descrição e strings usam "FIFA", "EA SPORTS FC", "Ultimate Team" diretamente |

---

## 4. O que está de fato completo

Confirmado por leitura de código nesta auditoria, não apenas pelos
handoffs:

- **Segurança estática uniforme**: 177 ocorrências de `security definer`
  contra 173 de `search_path = ''` nas migrations (a pequena diferença é
  função auxiliar/trigger que não precisa do padrão completo — não achei
  nenhuma função com `security definer` e sem `search_path` fixo). RLS
  habilitada em toda tabela nova (as 3 primeiras tabelas do projeto
  habilitam RLS numa migration separada logo em seguida — não um
  esquecimento, é o padrão do próprio repositório desde o início).
- **`anon` tem exatamente 2 grants de função em todo o schema**:
  `resolve_team_invite` e `get_public_profile` — ambos são os dois únicos
  pontos do produto desenhados para funcionar sem sessão. Nenhum outro
  grant a `anon` existe.
- **Rotas**: todas as 20 rotas registradas em `app_router.dart` têm
  origem de navegação real no código (`context.push`/`context.go`
  confirmados para `notifications`, `fcAccounts`, `fcAccountDetail`,
  `squadBuilder`, `matchDetail`, `teamSettings`, `playerProfile`). Nenhuma
  rota órfã, nenhum botão para lugar inexistente encontrado.
- **`weekend_league_event_model.dart` confirmado órfão** desde a Etapa 9
  — `grep` no projeto inteiro só encontra a própria classe se
  autorreferenciando, nenhum import de fora do arquivo.
- **Zero `TODO`/`FIXME`/`HACK`/`UnimplementedError`/`assert(false)` reais**
  no código. O único `TODO` de produto é um comentário deliberado
  (`player_card_detail_sheet.dart:201`, "listar outras cartas do mesmo
  jogador — etapa futura"), documentado como decisão consciente, não
  esquecimento.
- **Filtro do catálogo de cartas**: `search_fc_player_cards` exclui
  `is_active = false` em toda cláusula (`WHERE c.is_active` confirmado
  duas vezes na migration `20260918100200`), e as 50 cartas `LOCAL` de
  dev viram `is_active = false` na mesma migration que introduziu a
  coluna — o picker em produção genuinamente não mostra nada da massa de
  desenvolvimento.
- **Nenhum secret exposto no repositório**: `firebase_options.dart`,
  `google-services.json`, `GoogleService-Info.plist` e
  `env/development.json` existem localmente (necessários para o build
  deste ambiente), mas **nenhum está rastreado pelo git**
  (`git ls-files` confirma) — `.gitignore` cobre corretamente os 4.
- **`l10n`**: `app_pt.arb`, `app_en.arb`, `app_es.arb` têm exatamente 752
  entradas cada — paridade estrutural perfeita entre os 3 idiomas.
- **Zero vermelho**: `grep` por `Colors.red`/hex de vermelho no projeto
  inteiro não retornou nenhuma ocorrência — a regra é respeitada em nível
  de código, não é coincidência.
- **Ordem/FQ codes**: 43 códigos distintos usados nas migrations, `FQ014`
  confirmado livre (aparece só como comentário histórico numa migration,
  nunca como `errcode` de fato). Nenhum código duplicado com semânticas
  conflitantes.

---

## 5. P0 — bloqueadores de lançamento

1. **Zero teste automatizado no repositório.** `test/` não existe, nenhum
   arquivo `_test.dart` em lugar nenhum (incluindo `ios/RunnerTests`, que é
   scaffold padrão do Xcode, não teste real). Todo o "QA" documentado nos
   16 handoffs é validação manual pontual contra o Supabase remoto — real
   e valiosa, mas não repetível automaticamente, não protege contra
   regressão silenciosa numa mudança futura, e não existe suíte para rodar
   em CI mesmo que um CI fosse criado amanhã.
2. **Sem exclusão de conta.** Nenhuma RPC, nenhuma tela. A Apple exige
   fluxo de exclusão de conta dentro do app desde 2022 para qualquer app
   que permita criar conta — isso bloqueia submissão à App Store
   diretamente, e é também exigência comum de LGPD/GDPR para retenção de
   dados.
3. **Sem Política de Privacidade / Termos de Uso.** Nenhuma tela, nenhum
   texto, nenhum link, em lugar nenhum do app ou do repositório. Ambas as
   lojas (Apple e Google Play) exigem link de Política de Privacidade
   preenchido no formulário de submissão, e o app coleta e-mail, avatar,
   token de push e dados de partida — a ausência de um texto explicando
   isso é bloqueador direto de submissão, não apenas boa prática.
4. **Assinatura de release Android usa a chave de debug.**
   `android/app/build.gradle.kts` tem
   `signingConfig = signingConfigs.getByName("debug")` no bloco `release`
   com o comentário padrão do template Flutter ainda presente — nenhum
   `key.properties`/keystore de produção existe. Um `flutter build
   apk/appbundle --release` hoje gera um artefato **não publicável** na
   Play Store (a Play Store aceita o primeiro upload com qualquer chave,
   mas travaria nela para sempre — publicar assim seria uma decisão
   irreversível errada).
5. **Risco de marca não avaliado formalmente.** O nome do produto (`FIFA
   Queue`), a descrição do `pubspec.yaml` ("... em EA SPORTS FC"), o
   README e múltiplas strings de usuário (`app_pt.arb`: "Suas contas de
   Ultimate Team") citam diretamente marcas de terceiros (FIFA — a
   entidade —, EA, "EA SPORTS FC", "Ultimate Team") sem nenhuma nota de
   isenção de responsabilidade ("não afiliado a EA/FIFA") em lugar
   nenhum do produto. Isso é risco real de rejeição de loja e de
   notificação de remoção por parte do titular da marca — precisa de uma
   decisão de produto (renomear, ou adicionar disclaimer explícito),
   não de código.

---

## 6. P1 — recomendado antes do lançamento amplo

1. **CI/CD ausente.** Nenhum `.github/` no repositório. Mesmo um
   pipeline mínimo (`flutter analyze` + `dart format --check` no PR) já
   fecharia o gap mais barato de todos, principalmente considerando que
   não há testes automatizados ainda para rodar nele.
2. **Analytics real inexistente.** `AnalyticsService` está registrado
   como `LoggingAnalyticsService` (só grava em log local) e é chamado em
   apenas 2 arquivos do projeto inteiro (`join_team_page.dart`,
   `invite_section.dart`). Não há visibilidade real de uso do produto
   (quantos usuários buscam partida, completam squad, etc.) para decisão
   de produto pós-lançamento.
3. **`CrashReporter` de app não é o Crashlytics real.** O Crashlytics
   está corretamente ligado no `firebase_bootstrap.dart` para capturar
   erros não tratados/erros do Flutter automaticamente — isso funciona.
   Mas a abstração `CrashReporter` injetável (para `recordError` manual
   dentro de features) é um stub de log, nunca um adapter real para
   `FirebaseCrashlytics` — então nenhuma feature registra erro de negócio
   customizado no Crashlytics, só o que o framework pega sozinho.
4. **Confirmação visual de push em device físico nunca feita.** Documentado
   desde a Etapa 7 como limitação de ambiente (Gradle falha no Windows
   local, iOS precisa de Mac) — o caminho de envio foi provado ponta a
   ponta contra o FCM real, mas ninguém *viu* a notificação chegar na
   barra de status de um aparelho de verdade.
5. **Documentação de referência desatualizada.** `docs/database.md`
   (escrito na Etapa 2-3) ainda lista `match_search_events`, `devices`,
   `notification_preferences` e `user_settings` na seção "O que ainda não
   existe" — todas as 3 últimas já existem desde a Etapa 7. Não corrigi
   este arquivo nesta auditoria (não é um erro de uma linha isolada, é uma
   seção inteira que precisaria ser reescrita à luz de 14 etapas
   posteriores) — fica como item de faxina documentada, não uma correção
   trivial.

---

## 7. P2 — para depois

1. Consolidação de identidade entre versões da mesma pessoa na artilharia
   (Gold vs TOTS) — depende de decisão de produto sobre `fc_players`,
   adiado desde a Etapa 12/14.
2. Química para Icons/Heroes — estrutura pronta, exceção por carta não
   escrita (Etapa 13).
3. Season/semana em Division Rivals — hoje all-time, documentado como
   simplificação consciente (Etapa 12/14).
4. Universal Links nativos (Apple App Site Association, Android App
   Links verificados) e QR code no Perfil Público — ambos aceitos como
   fora de escopo na Etapa 16, dependem de domínio/infra que não existe
   hoje.
5. Padrão `FutureBuilder` por linha em `TeamsListPage`
   (`fetchPlayerStatuses` chamado uma vez por time da lista) — não é
   N+1 grave hoje (a maioria dos usuários tem poucos times), mas é um
   padrão que escalaria mal com muitos times por usuário; a tela de
   detalhe já usa Realtime corretamente, só a lista usa esse atalho.
6. Cerca de 39-40 chaves de `l10n` têm o mesmo texto em `en`/`pt`/`es`
   (majoritariamente nomes próprios do domínio — "Weekend League",
   "appName" — e não parecem ser bug de tradução esquecida, mas não
   passaram por revisão linguística humana para confirmar).
7. `deep_link_type`/`deep_link_params` gravados pelo backend de
   notificações mas ignorados pelo resolver do cliente (Etapa 15,
   documentado como dado morto, nunca produz link errado hoje).

---

## 8. Débito técnico

- **`weekend_league_event_model.dart`** — confirmado órfão nesta auditoria
  (Etapa 9), zero referência de fora do próprio arquivo. Candidato a
  remoção segura; não removido nesta auditoria porque exclusão de arquivo
  não é bug trivial nem correção de doc — é limpeza de escopo de
  implementação, fora do mandato desta auditoria.
- **`HistoryCubit`/`MatchHistoryView`/`get_team_match_search_history`**
  (Etapa 8) — documentados como órfãos desde a Etapa 8.5, substituídos
  pela timeline combinada. Não reconferidos nesta auditoria (fora do
  escopo de tempo), mas citados no próprio handoff como candidatos de
  faxina.
- **Migration `20260922100100_fc_chemistry_manager_name_fallback.sql`**
  ficou no histórico como tentativa que não funcionou (corrigida pela
  `100200` logo depois) — comportamento correto (nunca editar migration
  aplicada), só registrando que existe uma migration "morta" no meio do
  histórico por design, não por erro desta auditoria.
- **`docs/database.md`** desatualizado (seção 6 acima).

---

## 9. Bloqueadores externos (não corrigíveis neste ambiente)

- **Catálogo real FC27/FC26 nunca importado.** Pesquisa exaustiva de 4
  rodadas (Etapa 11) não achou fonte gratuita sem violar robots.txt/ToS.
  Importer pronto e testado via `--dry-run`; decisão consciente do dono
  do produto de não popular com o dataset FC26 (Kaggle) achado, aguardando
  fonte FC27 real. **Não bloqueia o app** — picker vazio, sem erro.
- **Push físico Android/iOS nunca visto num device real** (Gradle falha
  no Windows local; iOS precisa de Mac). Caminho provado ponta a ponta
  contra o FCM real.
- **APNs (.p8) e capabilities do target iOS** dependem de Mac, nunca
  configurados.
- **Web Push** adiado por decisão (VAPID + service worker + domínio
  próprio, nenhum dos três existe hoje).

---

## 10. Roadmap final recomendado

**Fase A — Bloqueadores de submissão de loja (P0, sem isso não publica em lugar nenhum)**
1. Decisão de produto sobre o nome/marca (renomear ou disclaimer explícito
   de "não afiliado a EA/FIFA" em todo lugar visível).
2. Escrever e publicar Política de Privacidade + Termos de Uso (podem
   viver como página estática linkada do app, não precisa ser tela
   nativa completa).
3. Implementar exclusão de conta (RPC + UI — o padrão de `security
   definer` já usado no projeto todo se aplica direto).
4. Gerar keystore de produção Android e configurar `signingConfig` real
   (+ `key.properties` fora do git, já existe o padrão no `.gitignore`
   para isso).

**Fase B — Confiança para lançar sem medo (P0/P1)**
5. Criar `test/` com ao menos: testes de unidade para `AppValidators`,
   `SupabaseErrorMapper`, e os Cubits mais críticos (matchmaking,
   squad chemistry) — não precisa ser 100% de cobertura para já mudar o
   jogo de "zero" para "algo".
6. CI mínimo (`.github/workflows`): `flutter analyze` + `dart format
   --check lib` em todo PR; adicionar `flutter test` assim que existir
   suíte.
7. Confirmar push em device Android físico real (assim que o ambiente
   permitir) e, se possível, um device iOS via Mac/CI de terceiro.

**Fase C — Polimento antes de tráfego real (P1)**
8. Trocar `AnalyticsService`/`CrashReporter` stub por adapters reais
   (Firebase Analytics + Crashlytics `recordError`) nos pontos de maior
   valor (matchmaking, squad builder, notificações).
9. Revisão linguística humana de PT/EN/ES (a estrutura já está pronta,
   isso é validação, não trabalho de tradução do zero).
10. QA visual/responsividade num dispositivo real ou emulador, focado nas
    telas de maior risco (Squad Builder — campo com 23 posições,
    dashboards de Time com múltiplas seções).

**Fase D — Depois do lançamento**
11. Fonte real de catálogo FC27 (bloqueador externo, monitorar
    surgimento de dataset/API oficial).
12. Itens P2 (Icons/Heroes, season em Rivals, consolidação de
    identidade na artilharia, Universal Links, QR code).
13. Faxina de débito técnico (`weekend_league_event_model.dart`,
    `HistoryCubit` órfão, `docs/database.md`).

---

## 11. Correções aplicadas nesta auditoria

**Nenhuma correção de código foi necessária ou aplicada.** Não foi
encontrado nenhum bug crítico trivial e incontestável, nenhum secret
exposto no repositório, e nada que impedisse a própria auditoria de
rodar (`flutter analyze` já estava limpo). A única divergência
documentação-vs-código encontrada (`docs/database.md`, seção 6 deste
relatório) não é uma correção de uma linha isolada — exigiria reescrever
uma seção inteira à luz de 8+ etapas — então foi reportada, não
corrigida, conforme o critério de "trivial e incontestável" desta
auditoria.

Confirmação de segurança: nenhum valor de secret real foi impresso em
nenhum momento desta auditoria, neste documento ou em qualquer saída
intermediária — a varredura por `SUPABASE_SECRET`, `SERVICE_ROLE`,
`PRIVATE_KEY`, `API_KEY` e credenciais Firebase/FCM encontrou apenas
nomes de variável/coluna (nunca um valor), e os 4 arquivos que de fato
contêm chaves de cliente Firebase (`firebase_options.dart` etc.) estão
corretamente fora do controle de versão.
