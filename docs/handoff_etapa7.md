# Handoff — Etapa 7 (push/FCM)

Documento de continuidade. Vive no repositório de propósito: sobrevive a troca
de conta e de máquina, coisa que a memória local do assistente não faz.

**Estado (2026-09-08): Etapa 7 FECHADA.** Backend completo e validado; client
completo com Firebase real; canal Android `queue_alerts` registrado; secrets
da Edge Function e Vault configurados; `process-notification-outbox`
deployada e ACTIVE; QA ponta a ponta rodado contra o projeto real e passou
(ver `docs/etapa7_server_setup.md`, seção 6). Só ficam pendentes, por
limitação de ambiente e não por defeito: a APNs key pro iOS (precisa de Mac)
e a confirmação visual da notificação chegando num device Android/iOS real.

Referência de fechamento: HEAD `67f3955`, 24 migrations locais = 24 remotas,
`origin/main` sincronizado.

---

## 1. PRONTO

### Backend de notificações — 5 migrations aplicadas (24 no total no remoto)

`user_devices`, `notification_preferences`, `notification_outbox`, os hooks de
matchmaking e o worker da outbox. Decisões: Transactional Outbox na mesma
transação da fila; `YOUR_TURN` nasce só em `_promote_next_queued_player`;
idempotência por `dedupe_key`; disparo por trigger + `pg_net`, cron de 1 min
como rede de segurança; RLS fechada para `anon`/`authenticated`; worker RPCs só
para `service_role`. QA de backend verde (14/14 + outbox conferida por SQL);
dados de QA removidos.

### Firebase configurado (client)

Projeto `fifa-queue` (sender `927848400584`), apps Android/iOS/Web via
`flutterfire configure`. Gerados/versionados conforme o `.gitignore`:

- `lib/firebase_options.dart` — **gitignored** (contém as chaves de cliente).
- `android/app/google-services.json` — **gitignored**.
- `ios/Runner/GoogleService-Info.plist` — **gitignored**.
- `firebase.json` e os plugins Gradle (`com.google.gms.google-services`,
  `com.google.firebase.crashlytics`) — **versionados** (não têm segredo).

> Como esses três arquivos de config são gitignored, qualquer novo checkout/CI
> precisa recebê-los fora do Git (ver seção 3).

### Camada Flutter de push — completa

- `FirebaseBootstrap` real: inicializa o Firebase em Android/iOS, registra o
  background handler e encadeia Crashlytics (`recordFlutterError` +
  `PlatformDispatcher.onError`). Tudo em try/catch: se o Firebase não subir, o
  app segue inteiro com o fallback. **Web/desktop não inicializam Firebase de
  propósito** (push web depende de VAPID + service worker + domínio) e usam o
  `UnavailablePushMessagingService`.
- Seleção de serviço no DI: `FirebasePushMessagingService` quando o Firebase
  inicializou (Android/iOS); `UnavailablePushMessagingService` caso contrário.
  Repositório: `SupabaseNotificationRepository` (real) ou
  `LocalNotificationRepository` (modo local).
- `NotificationRepository` (prefs + register/deactivate device via RPC),
  `NotificationSettingsCubit` (permissão + 3 preferências, escrita otimista),
  seção **Notificações** no Perfil com os 3 toggles (Sua vez / 30s / encerrado)
  e o convite pré-permissão (`enable_notifications_sheet`).
- `PushTokenCoordinator`: registra o token no login e em `onTokenRefresh`;
  **desativa o device ANTES do signOut** (a baixa depende de `auth.uid()`).
- `NotificationLifecycleListener` (acima do shell): liga/desliga o token pela
  sessão, roteia toques (`NotificationRouter` → seleciona o time do payload e
  reabre a Home, **relendo o estado do backend**, nunca confiando no payload),
  **suprime push em foreground** (o Realtime já cobre a tela) e mostra o convite
  pré-permissão uma vez, só depois de o usuário ter time.
- `LocaleSyncListener`: espelha o idioma efetivo para `profiles.locale`
  (**write-only**; a UI manda pela preferência local, nunca se lê de volta).
- l10n PT/EN/ES de tudo que é novo.

### Validado (app web real contra o Supabase de produção)

- App sobe na Web com Firebase habilitado, sem quebrar (cai no fallback).
- **Bug do time selecionado corrigido e comprovado**: default = time mais
  antigo (Falcons), trocar para Furia → reload → Furia; trocar para Falcons →
  reload → Falcons. Causa raiz: `.order()` do postgrest-dart é DESCENDENTE por
  padrão (`teams.first` virava o time recém-criado) e o fallback não era
  persistido — os dois corrigidos.
- Seção Notificações renderiza; toggle salvou no backend
  (`queue_turn_enabled=false` confirmado); `profiles.locale='pt-BR'` gravado no
  login. Dados de QA removidos (0 usuários, 0 times).

---

## 2. Server-side — CONCLUÍDO

Esta seção descrevia o server-side como pendente. Não é mais: tudo abaixo
está configurado e rodando no projeto `lteujeclnhmurcewurkg`. O runbook com
os comandos exatos, onde obter cada credencial e a sequência de validação
está em `docs/etapa7_server_setup.md`.

| Item | Estado |
| --- | --- |
| Service account do Firebase (assinatura FCM v1) | **feito** |
| Secrets da Edge Function (`WORKER_SECRET`, `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) | **feito** |
| Supabase Vault (`notification_worker_url`, `notification_worker_secret`) | **feito** |
| Deploy de `process-notification-outbox` | **feito** — ACTIVE, `verify_jwt=false` |
| Canal Android `queue_alerts` registrado antes do primeiro uso | **feito** |
| QA real backend/FCM | **verde** (`etapa7_server_setup.md`, seção 6) |

O `_notify_worker()` não faz mais no-op: o Vault responde, o trigger dispara
e o worker processa. O que foi provado de ponta a ponta contra o Google, com
dados reais: outbox → trigger `pg_net` → worker → OAuth2 assinado pela
service account → requisição ao FCM v1 → resposta real → desativação de
token morto → idempotência por `dedupe_key` → timing correto de YOUR_TURN,
SEARCH_EXPIRING e SEARCH_EXPIRED. Dados de QA removidos ao final.

### O que realmente falta (nada bloqueia o app)

1. **Confirmação visual em Android físico.** Falta só ver a notificação
   aparecer na barra de status com um token FCM genuíno. `flutter build apk`
   falha neste Windows pelo loopback do Gradle, e um token real só existe
   depois de o app rodar num device com o Firebase inicializado. O caminho
   de envio já foi exercitado de verdade — o FCM respondeu, apenas rejeitando
   o token de teste inválido, que era o esperado.
2. **APNs/iOS.** A Authentication Key (.p8) e as capabilities do target
   Runner (*Push Notifications* + *Background Modes → Remote notifications*)
   dependem de um Mac. Passo a passo em `etapa7_server_setup.md`, seção 2.3.
3. **Web Push — adiado conscientemente.** Depende de par VAPID +
   `firebase-messaging-sw.js` + domínio HTTPS. Web e desktop não inicializam
   Firebase de propósito e usam o `UnavailablePushMessagingService`.

Fora isso: Crashlytics — o plugin Gradle já está aplicado; confirmar upload
de símbolos num build de release real.

## 3. Config gitignored a fornecer em novo checkout/CI

`lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist` não estão no Git. Reobtê-los com
`flutterfire configure` (precisa do FlutterFire CLI) ou copiá-los de um ambiente
confiável. `env/development.json` (SUPABASE_URL + PUBLISHABLE_KEY) idem.
