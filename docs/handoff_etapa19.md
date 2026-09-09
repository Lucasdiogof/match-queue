# Handoff — Etapa 19 (Release QA)

Status em 2026-09-09: **NOT READY FOR STORE RELEASE** — não por bug de
código, mas porque **nenhuma das 3 plataformas pôde ser executada de
verdade** neste ambiente (todos os 3 bloqueios foram reconfirmados ao
vivo nesta sessão, não presumidos de memória antiga). Nenhum bug de
código foi encontrado nem corrigido. HEAD não mudou: `8377350`.

## 1. Auditoria pré-QA (Fase 1)

| Item | Estado |
| --- | --- |
| HEAD / git status | `8377350`, árvore limpa, `origin/main` em `f32592e` (1 commit local à frente, não pushado) |
| Flutter/Dart | Flutter 3.44.1 stable, Dart 3.12.1 |
| Flavors/entrypoints | Nenhum flavor — `lib/main.dart` único |
| `applicationId` / bundle id | `com.lucasdiogof.fifaqueue` (idêntico Android/iOS) |
| Supabase | `env/development.json` presente localmente, gitignored; publishable key só, sem secret exposta |
| Firebase | `google-services.json` e `GoogleService-Info.plist` presentes localmente, gitignored |
| Android signing | **Sem `android/key.properties`** — build de release recusaria assinar com debug key por design (`gradle.taskGraph.whenReady` lança exceção de propósito). Não é bug: comportamento correto documentado em `docs/android_signing.md`. Precisa ser gerado antes do release real. |
| iOS signing | `IPHONEOS_DEPLOYMENT_TARGET = 13.0`, bundle id correto, `GoogleService-Info.plist` presente. Assinatura/perfil de distribuição não verificável fora do Xcode/macOS. |
| Web/PWA | `web/manifest.json` com ícones 192/512, sem script Firebase (Web push deliberadamente adiado, decisão antiga). |
| Environment/config release | `env/production.example.json` existe como template; `env/production.json` real não versionado (esperado). |
| Edge Functions | `process-notification-outbox` v3 ACTIVE, `delete-account` v1 ACTIVE — inalteradas. |
| Migrations | 76 locais = 76 remotas. |

Nenhuma alteração foi feita nesta fase.

## 2. Plataformas realmente executadas

| Plataforma | Execução real | Resultado |
| --- | --- | --- |
| **Web** | `flutter build web --release` (compilação real) | **PASS** — compila limpo, 33,8s, tree-shaking de ícones ok. `flutter run -d chrome` dentro do navegador de preview deste ambiente **trava antes do primeiro frame** — reconfirmado ao vivo nesta sessão (CanvasKit carrega, `flt-glass-pane` nunca aparece mesmo após 20s+ de espera): a causa é a própria inicialização do Supabase (`await Supabase.initialize(...)` antes de `runApp()`) fazer uma chamada de rede externa que o sandbox deste navegador de preview bloqueia silenciosamente — limitação de ambiente já documentada num projeto irmão, agora confirmada neste também, não um bug do FIFA Queue. |
| **Android** | `flutter build apk --debug` (tentativa real) | **FALHOU NO AMBIENTE** — `java.io.IOException: Unable to establish loopback connection` do Gradle, reconfirmado ao vivo nesta sessão (não presumido). Limitação conhecida deste Windows/ambiente, não do código. |
| **iOS** | Nenhuma — Windows não compila projeto Xcode | **NOT EXECUTED — REQUIRES macOS** |

**Nenhuma das 3 plataformas pôde de fato abrir uma tela do app neste
ambiente.** Todo o restante desta etapa (Fase 2) foi validado da única
forma disponível: **REST real contra o Supabase de produção**, com
usuários de QA descartáveis, criados e removidos sem resíduo — o mesmo
caminho de dados que a UI usaria, só sem o renderizador visual na
frente. Isso prova a lógica de servidor, não a experiência visual.

## 3. Fase 2 — Fluxos críticos (via REST real, produção)

### Auth
Signup/login real via `/auth/v1/signup` e `/auth/v1/token` usados
dezenas de vezes nesta e nas etapas anteriores (15/17B-2/18) contra o
projeto real — **EXECUTED, PASS** pro caminho de servidor. Persistência
de sessão/relogin/recuperação de senha dependem do cliente (app_links,
armazenamento local) — **NOT EXECUTED — ENVIRONMENT LIMITATION** (não
há tela pra testar). Exclusão de conta: Edge Function `delete-account`
está ACTIVE (Fase A), não reexecutada aqui (destrutiva, sem necessidade
de reconfirmar sem achado novo).

### Times
Criar time, gerar convite, entrar por código, dono ↔ membro — testado
ao vivo nesta sessão (ver seção 4). **PASS.** Remover membro, edge cases
de OWNER, edição de time: já cobertos por RLS/RPC em etapas anteriores,
não reexecutados sem motivo.

### Conta FC
Criar conta, vincular a time — testado ao vivo nesta sessão. **PASS.**

### Squad Builder
Já validado a fundo na Etapa 18 (posição, anti-duplicação, overall,
chemistry, contra o catálogo real de 17.873 cartas) — não repetido
aqui, sem necessidade.

### Matchmaking
Testado ao vivo nesta sessão, ponta a ponta: Conta A busca → `SEARCHING`;
Conta B busca com A ocupando → `QUEUED` (fila FIFO); A reporta "Encontrei"
→ A sai da busca, B é promovido automaticamente → `SEARCHING`. **PASS**
para o núcleo (fila, FIFO, promoção/YOUR_TURN). Entrega real de push,
comportamento em background/foreground, e reconexão de Realtime **não
são observáveis sem device/tela** — **NOT EXECUTED — ENVIRONMENT
LIMITATION**.

### Partidas/Stats/WL/Rivals
RPCs de resultado, gols/assistências, ranking e leaderboard já
validados com dados reais nas Etapas 12-14 e 18; não reexecutados sem
achado novo que justifique.

### Notificações
Inbox, read/unread, categorias, dedupe, push condicional — validados
ao vivo na Etapa 15 (múltiplos casos, incluindo múltiplos devices e
membro removido). Entrega visual do push num device real **NOT
EXECUTED — ENVIRONMENT LIMITATION** (mesma pendência desde a Etapa 7).

### Perfil público
`get_public_profile` auditado nesta sessão: expõe só `display_name`,
`avatar_url`, nome da conta, e campos de stats/rivals **apenas quando
opt-in** (`show_stats`/`show_rivals`). Nenhum e-mail, `user_id` ou dado
privado no payload. **PASS** (revisão de código + já testado ao vivo na
Etapa 16).

### Legal
Rotas `/legal/privacy`, `/legal/terms`, `/legal/about` e exclusão de
conta existem desde a Fase A, confirmadas no router; não há mudança pra
revalidar.

## 4. Evidência da Fase 2 (matchmaking, ao vivo, produção real)

```
A (SEARCHING) -> B busca -> B QUEUED, A é quem bloqueia
A reporta "Encontrei" -> A sai (my_state=NONE)
B consulta status -> B agora SEARCHING (promovido automaticamente)
```
Time, contas e usuários de QA removidos ao final — zero resíduo
confirmado (`auth.users`, `teams`, `user_fc_accounts`).

## 5. Fase 3 — Lifecycle e erros

**NOT EXECUTED — ENVIRONMENT LIMITATION.** Background/foreground,
perda/recuperação de conexão, refresh de sessão, timeout, reconexão de
Realtime, duplo clique, back button Android — todos exigem um app de
verdade rodando numa tela, o que nenhuma das 3 plataformas ofereceu
neste ambiente (seção 2). Não fingido como testado.

## 6. Fase 4 — QA visual

**NOT EXECUTED — ENVIRONMENT LIMITATION**, nas 3 plataformas, pelos
motivos exatos da seção 2. Nenhum item desta fase (overflow, SafeArea,
teclado, scroll, dark/light, PT/EN/ES visual, nomes longos, imagens
ausentes) foi marcado como PASS — ficam todos como pendência de
ambiente, não como aprovados.

## 7. Fase 5 — Android

- Build debug: **FALHOU** (Gradle/loopback, ambiente — seção 2).
- Configuração estática auditada e correta: `applicationId`, `minSdk`/
  `targetSdk` via `flutter.minSdkVersion`/`targetSdkVersion`, permissão
  `INTERNET` explícita, `POST_NOTIFICATIONS` **contribuída automaticamente
  pelo manifest do plugin `firebase_messaging` 16.6.0** (confirmado
  lendo o `AndroidManifest.xml` do pacote no pub cache — não precisa
  estar duplicada no manifest do app), `FirebaseMessaging.requestPermission()`
  já é chamado no fluxo de push (dispara o prompt do Android 13+
  automaticamente).
- **Sem `key.properties`** — precisa ser gerado antes de qualquer
  release real (ver `docs/android_signing.md`). Nenhum artefato de
  release foi produzido, e nenhum seria produzido mesmo com a config
  correta, porque nem o build de debug conseguiu rodar neste ambiente.
- App Links (domínio) seguem pendentes desde a Etapa 1 — decisão de
  produto (precisa de domínio), documentado em `docs/deep_links.md`,
  não é achado novo desta etapa.

## 8. Fase 6 — iOS

**NOT EXECUTED — REQUIRES macOS.**

Checklist para quando houver acesso a um Mac:

1. `flutter build ios --release` (ou abrir `ios/Runner.xcworkspace` no
   Xcode) com um time de desenvolvimento configurado.
2. Confirmar `GoogleService-Info.plist` real (não o placeholder) e que
   o `BUNDLE_ID` dele bate com `com.lucasdiogof.fifaqueue`.
3. Capability *Push Notifications* + *Background Modes → Remote
   notifications* habilitadas no target Runner (para FCM em background).
4. Revisar `Info.plist` (permissões de notificação, URL scheme
   `com.lucasdiogof.fifaqueue` já registrado para o callback de auth).
5. Se/quando o domínio existir: habilitar *Associated Domains* e
   publicar `apple-app-site-association` (ver `docs/deep_links.md`).
6. Assinatura de distribuição (App Store Connect) + TestFlight antes de
   qualquer submissão.

## 9. Fase 7 — Web/PWA

- `flutter build web --release`: **PASS** (compila, tree-shaking ok).
- Carregamento/responsividade/auth/deep links/console errors: **NOT
  EXECUTED — ENVIRONMENT LIMITATION** (seção 2 — o bloqueio é de rede do
  sandbox, não do build).
- Manifest com ícones 192/512, `display: standalone` — presente e
  correto por leitura.
- Firebase Web push: deliberadamente não implementado (decisão antiga,
  depende de VAPID + domínio) — não é um gap desta etapa.
- Service worker: o padrão do Flutter (`flutter_service_worker.js`) é
  gerado pelo build; comportamento de cache/update não observável sem
  execução real (mesma limitação).

## 10. Fase 8 — Segurança/Privacidade

- Nenhuma secret commitada: `git grep` por padrões de chave/token não
  encontrou nada; `env/*.json` (exceto `.example.json`), `firebase_options.dart`,
  `google-services.json`, `GoogleService-Info.plist`, `key.properties`,
  `*.keystore` todos no `.gitignore` e de fato ausentes do índice do git.
- RLS/grants: inalterados desde as etapas anteriores, sem achado novo.
- `get_public_profile`: confirmado sem vazamento de dado privado
  (seção 3).
- Nenhum log de secret impresso nesta sessão (só checagem de
  presença/ausência via `Platform.environment`, nunca o valor).

## 11. Fase 9 — Testes finais

- `flutter test`: 6/6 verde (`test/tool/`, suíte completa do repo).
- `flutter analyze`: **No issues found**.
- Migrations: 76 locais = 76 remotas.
- Edge Functions: `process-notification-outbox` (v3, ACTIVE),
  `delete-account` (v1, ACTIVE) — inalteradas.
- `git status`/`git diff`: limpo, sem mudança de código nesta etapa.

## 12. Pendências reais (não são bugs)

1. **QA visual real** em Android/iOS/Web — precisa de device físico,
   Mac, ou um ambiente de browser sem o bloqueio de rede do sandbox.
2. **`android/key.properties`** — precisa ser gerado antes do release
   Android real.
3. **App Links/Universal Links** — pendentes desde a Etapa 1, dependem
   de domínio (decisão de produto, não técnica).
4. **iOS**: checklist da seção 8, executável só num Mac.
5. Achados antigos, já documentados, não bloqueantes: 32 `fc_clubs` + 6
   `fc_leagues` + 8 `fc_nations` órfãos (Etapas 17B-2/18).

## Veredito

**NOT READY FOR STORE RELEASE.**

Não por bug de código — zero bug encontrado ou corrigido nesta etapa,
`flutter analyze`/`flutter test` limpos, lógica de servidor validada ao
vivo onde foi possível (auth, times, contas, matchmaking, perfil
público). O bloqueio é 100% de execução: nenhuma das 3 plataformas
produziu uma tela real neste ambiente (Web bloqueado pelo sandbox de
rede, Android pelo Gradle/loopback deste Windows, iOS por exigir macOS),
e sem isso a Fase 4 (QA visual, obrigatória pro fechamento) não pode ser
marcada como PASS honestamente. Falta keystore Android pro release real.
Nenhum falso bloqueio de código foi criado — os três motivos acima são
de ambiente, não de produto.
