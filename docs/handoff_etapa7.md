# Handoff — Etapa 7 (push/FCM) em andamento

Documento de continuidade escrito no meio da Etapa 7. Ele vive no
repositório de propósito: sobrevive a troca de conta e de máquina, coisa que
a memória local do assistente não faz.

**Estado:** backend completo e validado; camada Flutter pela metade.

---

## 1. O que já está PRONTO e APLICADO

### Correções prévias (pedidas antes do Firebase)

**Bug do time selecionado.** A causa raiz era o `.order()` do postgrest-dart,
cujo default é **descendente**. `fetchMyMemberships` ordenava `joined_at`
DESC, então `teams.first` era o time mais **recente**, não o mais antigo — e
o fallback nunca era persistido, então toda abertura recalculava a seleção e
entrar num time novo movia o usuário sozinho.

Corrigido em três frentes:
- `team_remote_data_source.dart`: `ascending: true` explícito, com desempate
  por `team_id`.
- Mesmo bug atingia a lista de membros (`order('role')` DESC colocava o
  **OWNER por último**) — também corrigido.
- `TeamsCubit._resolveSelectedId`: agora é `async`, descarta preferência
  órfã, e **persiste a seleção resolvida** mesmo vinda do fallback.

> ⚠️ **Falta o QA de persistência** descrito no item 1.1 da Etapa 7
> (selecionar A → recarregar → A continua; selecionar B → recarregar → B
> continua). O código está correto por leitura, mas não foi exercitado na UI.

**FQ013.** Mapeado para `InviteFailureReason.generationFailed` em
`supabase_error_mapper.dart`, com texto localizado
(`errorInviteGenerationFailed`) em PT/EN/ES. `FQ014` continua livre.

### Backend de notificações — 5 migrations aplicadas no Supabase

| Migration | Conteúdo |
| --- | --- |
| `20260912100000_create_user_devices.sql` | `user_devices` + enum `device_platform` + RPCs `register_device`/`deactivate_device` |
| `20260912100100_create_notification_preferences.sql` | `notification_preferences` + `handle_new_user` passa a criar a linha + backfill |
| `20260912100200_create_notification_outbox.sql` | enum `notification_type`, `notification_outbox`, `_enqueue_notification` |
| `20260912100300_matchmaking_notification_hooks.sql` | hooks de `YOUR_TURN`/`SEARCH_EXPIRED`/`SEARCH_EXPIRING` + `run_matchmaking_maintenance` |
| `20260912100400_notification_outbox_worker.sql` | `pg_net`, dispatch por trigger, `claim_notification_batch`, `complete_notification`, `deactivate_device_token`, cron de segurança |

Decisões que importam:

- **Transactional Outbox.** A transação que muda a fila grava a notificação
  junto. Rollback da RPC = nenhuma notificação. Nenhuma chamada HTTP acontece
  com o lock do time na mão.
- **`YOUR_TURN` nasce dentro de `_promote_next_queued_player`** e em nenhum
  outro lugar — cobre match-found, cancel, expiração lazy e cron sem repetir
  lógica. Quem toca em "Buscar" sem fila **não** passa por ali, então não
  recebe "sua vez" (correto: não houve espera).
- **Idempotência** por índice único em `dedupe_key` = `TIPO:session_id`.
- **Latência**: trigger `AFTER INSERT ... FOR EACH STATEMENT` chama
  `net.http_post` (pg_net é assíncrono) → push em segundos. Cron de 1 minuto
  é só rede de segurança. Cron de 30s (o da Etapa 5) foi **reaproveitado**
  via upsert de `cron.schedule`, não duplicado.
- **`_expire_team_search_if_needed` continua devolvendo boolean** (Etapa 6) e
  agora também enfileira `SEARCH_EXPIRED`.
- **Segurança**: `notification_outbox` com RLS e zero policies/grants para
  `anon`/`authenticated`. `user_devices` só select-own (escrita só por RPC).
  Worker RPCs só com `grant execute to service_role`.

### QA de backend — executado e verde

14/14 em segurança/dispositivos via HTTP com 4 usuários reais:
isolamento de tokens entre contas, reatribuição de token ao trocar de conta
no mesmo aparelho, cliente sem acesso à outbox nem às RPCs do worker,
preferências nascendo com a conta e isoladas por usuário.

Conteúdo da outbox conferido por SQL após os quatro fluxos:

```
SEARCH_EXPIRED   QA A  ×1     (cron expirou)
SEARCH_EXPIRING  QA A  ×1     (janela de 30s, uma só apesar de vários ticks)
YOUR_TURN        QA B  ×2     (match found + promoção por expiração)
YOUR_TURN        QA C  ×1     (cancel)
QA A             ×0 YOUR_TURN (primeiro buscador não recebe)
```

`qty == distinct_keys` em tudo. Worker validado por SQL: supressão por
preferência, curto-circuito de `no_active_device`, lease impedindo
re-claim imediato, e desistência após 5 tentativas preservando o erro.

Todos os dados de QA foram removidos (zero linhas residuais).

### Edge Function

`supabase/functions/process-notification-outbox/index.ts` — escrita, **não
deployada** (depende do Firebase). Faz OAuth2 com a service account via Web
Crypto, resolve o texto PT/EN/ES pelo `locale` do usuário, envia FCM v1,
desativa token morto (`UNREGISTERED`/`INVALID_ARGUMENT`) e fecha o item.

### Flutter — fundações prontas

- Pacotes adicionados: `firebase_core`, `firebase_messaging`,
  `firebase_crashlytics`. **`flutter build web --release` validado com eles.**
- `features/notifications/domain/` — `PushNotificationType`,
  `NotificationPreferences`, `PushPermissionStatus`, `DevicePlatform`,
  `NotificationRepository`, `PushMessagingService`.
- `features/notifications/data/` — `NotificationPreferencesModel`,
  `SupabaseNotificationRemoteDataSource`, `FirebasePushMessagingService`
  (com background handler top-level) e `UnavailablePushMessagingService`.

---

## 2. O que FALTA (continuar daqui)

### Bloqueado por você — Firebase não existe

Nada foi inventado: sem `google-services.json`, sem
`GoogleService-Info.plist`, sem `firebase_options.dart`, sem IDs. Para
destravar é preciso criar o projeto Firebase e fornecer:

1. Projeto Firebase (pode ser um só, com 3 apps: Android, iOS, Web).
2. **Android**: `google-services.json` → `android/app/`.
3. **iOS**: `GoogleService-Info.plist` → `ios/Runner/`, mais a **APNs
   Authentication Key** (`.p8`, criada no Apple Developer) enviada ao
   Firebase, e as capabilities *Push Notifications* + *Background Modes →
   Remote notifications* no target Runner.
4. **Web**: par de chaves VAPID + `firebase-messaging-sw.js`. Depende de
   HTTPS; sem domínio definido, fica pendente conscientemente.
5. `flutterfire configure` para gerar `lib/firebase_options.dart` (o CLI não
   está instalado neste ambiente).
6. Service account (Firebase → Configurações → Contas de serviço) para os
   secrets da Edge Function.

### Secrets a configurar (nunca no Git)

Edge Function (`supabase secrets set ...`):
```
WORKER_SECRET          gerado por você, qualquer string longa
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

Supabase Vault (para o trigger conseguir chamar a função):
```
notification_worker_url     https://<ref>.functions.supabase.co/process-notification-outbox
notification_worker_secret  mesmo valor de WORKER_SECRET
```

Enquanto o Vault não tiver esses dois nomes, `_notify_worker()` faz no-op de
propósito: a outbox acumula e nada quebra.

### Código Flutter que falta escrever

1. `data/repositories/supabase_notification_repository.dart` e
   `local_notification_repository.dart` (implementar `NotificationRepository`).
2. `notifications_module.dart` + registro em `app/dependencies.dart` —
   escolhendo `FirebasePushMessagingService` quando houver config e
   `UnavailablePushMessagingService` caso contrário.
3. `presentation/cubit/notification_settings_cubit.dart` (+state) —
   preferências + status de permissão.
4. `presentation/widgets/notification_settings_section.dart` — seção
   "Notificações" no Perfil com os 3 toggles.
5. `presentation/widgets/enable_notifications_sheet.dart` — convite
   pré-permissão ("Não perca sua vez"), mostrado **depois** de o usuário ter
   time, nunca no Login.
6. `notification_router.dart` — interpreta `type`/`team_id`/`session_id`,
   seleciona o time e navega para a Home. **Nunca confiar no payload** para
   dizer que ainda está SEARCHING: sempre reler o backend.
7. Coordenador de ciclo de vida: registrar token no login, escutar
   `onTokenRefresh`, **chamar `deactivate_device` ANTES do signOut**
   (depois não há sessão), e tratar `initialNotification()` na abertura.
8. Foreground: suprimir alerta do sistema e converter em refresh — o
   Realtime da Etapa 6 já atualiza a UI e o snackbar "Sua vez de buscar!" já
   existe. Não pode sair snackbar duplicado.
9. `FirebaseBootstrap` (hoje no-op consciente) precisa passar a inicializar
   de verdade quando houver `firebase_options.dart`, e registrar Crashlytics.
10. **Sincronizar locale**: `profiles.locale` existe e o worker já o usa, mas
    o app ainda não escreve nele. Precedência decidida: a preferência local
    manda na UI; a cópia no backend é write-only do dispositivo, só para o
    worker escolher o idioma do push. Nunca ler de volta (evita loop).
11. l10n PT/EN/ES das telas novas (as strings de push em si já estão na Edge
    Function).

### QA que falta

- Persistência do time selecionado (item 1.1).
- Push ponta a ponta em device real — impossível aqui: Android não builda
  neste ambiente (`Unable to establish loopback connection` no Gradle, é
  limitação da máquina) e iOS não builda no Windows.
- Notificação obsoleta: gerar push, deixar a sessão expirar, tocar depois →
  o app deve abrir o time certo e mostrar o estado atual, não SEARCHING falso.

---

## 3. Como retomar

```bash
git pull
flutter pub get
npx supabase@latest migration list --linked   # confere que as 22 estão aplicadas
```

O restante da especificação da Etapa 7 (numeração original) está no histórico
da conversa; os itens 29–51 e 63–73 são os que ainda não foram cumpridos.
