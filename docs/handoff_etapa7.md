# Handoff — Etapa 7 (push/FCM)

Documento de continuidade. Vive no repositório de propósito: sobrevive a troca
de conta e de máquina, coisa que a memória local do assistente não faz.

**Estado:** backend completo e validado; **camada Flutter (client) completa,
já com Firebase real**; falta apenas o lado servidor da entrega do push.

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

## 2. FALTA — apenas server-side (não bloqueia o app)

Enquanto isto não existir, o app funciona inteiro; a outbox só acumula e o
`_notify_worker()` faz no-op de propósito.

1. **Service account** (Firebase → Configurações → Contas de serviço) para a
   Edge Function assinar o FCM v1.
2. **APNs Authentication Key (.p8)** no Apple Developer, enviada ao Firebase,
   para push no iOS. Capabilities no target Runner: *Push Notifications* +
   *Background Modes → Remote notifications*.
3. **Secrets da Edge Function** (`supabase secrets set`): `WORKER_SECRET`,
   `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
4. **Supabase Vault**: `notification_worker_url`
   (`https://<ref>.functions.supabase.co/process-notification-outbox`) e
   `notification_worker_secret` (= `WORKER_SECRET`).
5. **Deploy** de `supabase/functions/process-notification-outbox`.
6. **Web push** (opcional, adiado): par VAPID + `firebase-messaging-sw.js` +
   HTTPS/domínio. Sem isso, a Web segue sem push conscientemente.

### QA que só dá para fazer em device real

- Push ponta a ponta (Android/iOS) — Android não builda neste ambiente
  (loopback do Gradle) e iOS não builda no Windows.
- Notificação obsoleta: gerar push, deixar a sessão expirar, tocar depois → o
  app deve abrir o time certo e mostrar o estado atual (o router já relê o
  backend; falta confirmar no aparelho).
- Crashlytics: o plugin Gradle já está aplicado; confirmar upload de símbolos
  num build de release real.

---

## 3. Config gitignored a fornecer em novo checkout/CI

`lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist` não estão no Git. Reobtê-los com
`flutterfire configure` (precisa do FlutterFire CLI) ou copiá-los de um ambiente
confiável. `env/development.json` (SUPABASE_URL + PUBLISHABLE_KEY) idem.
