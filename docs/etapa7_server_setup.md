# Etapa 7 — fechamento do lado servidor (push/FCM)

Runbook de execução. Vive no repo de propósito (sobrevive a troca de conta/
máquina). Auditado contra o estado real do projeto em 2026-09-08:
`process-notification-outbox` **não está deployada**, **zero secrets**
configurados no Edge Functions, **zero valores no Vault**, tabelas de
notificação com **zero linhas** (nenhum resíduo de QA). `pg_cron`, `pg_net`,
`pgcrypto` instalados; Vault confirmado funcional (schema `vault` responde a
query, mesmo não aparecendo como extensão própria). Cron jobs já ativos:
`matchmaking-expire-searches` (Etapa 5) e `notification-outbox-dispatch`
(Etapa 7, rede de segurança de 1 min).

---

## 0. Achados desta auditoria (corrigidos ou a decidir)

### 0.1 `verify_jwt` — CORRIGIDO agora
`_notify_worker()` chama a function só com o header próprio `x-worker-secret`,
nunca com `Authorization: Bearer`. Por padrão o gateway do Supabase exige JWT
válido e devolveria 401 **antes** do código da function rodar — e isso
falharia em silêncio, porque `_notify_worker()` nunca confere a resposta do
`net.http_post` (entrega é best-effort de propósito, para não seguraro lock
do time esperando HTTP). Adicionei ao `supabase/config.toml` (não é secret,
já commitável):

```toml
[functions.process-notification-outbox]
verify_jwt = false
```

O comando de deploy abaixo também passa `--no-verify-jwt` como reforço, caso
sua versão da CLI não leia essa seção do `config.toml`.

### 0.2 Canal de notificação Android — ENCONTRADO E CORRIGIDO
Commit `aaa9c60`. O worker sempre mandou notificação Android no canal
`queue_alerts`, mas nada no client criava esse canal — a partir do Android 8
o sistema derruba isso em silêncio. `FirebaseBootstrap._ensureAndroidNotificationChannel`
agora cria o canal (`Importance.high`, som e vibração ligados) logo após
`Firebase.initializeApp`, antes do handler de background, usando
`flutter_local_notifications` (dependência nova, só usada por isso). Nome e
descrição vêm de `AppLocalizations`, resolvidos pelo mesmo locale efetivo que
`LocaleSyncListener` já calculava (preferência explícita, senão o locale do
aparelho). Protocolo do backend **não mudou** — `channel_id` continua
`queue_alerts` dos dois lados. `flutter analyze`/`dart format`/`flutter build
web --release` verdes; `flutter build apk` bateu no mesmo loopback do Gradle
de sempre (ambiente, não o código). Sem device Android real aqui pra
confirmar visualmente que o canal aparece em Config → Apps → FIFA Queue →
Notificações — isso fica pra quando você tiver um aparelho em mãos.

### 0.3 Consistência de nomes — CONFERIDA, tudo bate
| Nome | Onde aparece | Confere com |
|---|---|---|
| `WORKER_SECRET` | Edge Function secret (`Deno.env.get`) | valor igual ao Vault `notification_worker_secret` |
| `notification_worker_secret` | Vault (`_notification_worker_secret('notification_worker_secret')`) | mesmo valor de `WORKER_SECRET` |
| `notification_worker_url` | Vault (`_notification_worker_secret('notification_worker_url')`) | URL pública da function deployada |
| `x-worker-secret` | header enviado pelo `_notify_worker()` e lido pela function | nomes batem exatamente (case-insensitive em HTTP) |
| `FIREBASE_PROJECT_ID` | Edge Function secret | `"fifa-queue"` (confirmado em `firebase.json`, é o Project ID, não o sender/project number `927848400584`) |
| `notification-outbox-dispatch` | job do `pg_cron` (rede de segurança, 1 min) | já ativo no banco, aponta pra `dispatch_pending_notifications()` → `_notify_worker()` |

Nada para corrigir aqui — só faltam os *valores*.

---

## 1. Segredos necessários — o que é, onde vive, como obter

| Nome | Onde configurar | Sensível? | Como obter |
|---|---|---|---|
| `WORKER_SECRET` | Edge Function secret | Sim (você gera) | Seção 2.1 — gerado localmente, não vem de lugar nenhum externo |
| `FIREBASE_PROJECT_ID` | Edge Function secret | Não (é público) | `fifa-queue` — já confirmado, pode usar direto |
| `FIREBASE_CLIENT_EMAIL` | Edge Function secret | Sim | Seção 2.2 — vem do JSON da service account do Firebase |
| `FIREBASE_PRIVATE_KEY` | Edge Function secret | **Muito sensível** | Seção 2.2 — idem, campo `private_key` do mesmo JSON |
| `SUPABASE_URL` | *(nada a fazer)* | — | Injetado automaticamente pela plataforma em toda Edge Function |
| `SUPABASE_SERVICE_ROLE_KEY` | *(nada a fazer)* | — | Idem — nunca precisa (nem deve) ser setado manualmente |
| `notification_worker_url` | Supabase Vault (Postgres) | Não (é uma URL pública) | `https://lteujeclnhmurcewurkg.supabase.co/functions/v1/process-notification-outbox` — confirme contra a URL exata impressa pelo `supabase functions deploy` |
| `notification_worker_secret` | Supabase Vault (Postgres) | Sim | **Mesmo valor exato** do `WORKER_SECRET` acima |

---

## 2. Como obter cada valor

### 2.1 `WORKER_SECRET` — gerado por você, localmente, sem depender de nada externo

Não é uma credencial de nenhum provedor — é só uma string aleatória que o
Postgres manda para a Edge Function provar que a chamada é legítima. Gere no
terminal (Git Bash já tem `openssl`):

```bash
openssl rand -hex 32
```

Guarde o resultado só na sua cabeça/gerenciador de senhas por enquanto — as
próximas seções mostram como colocá-lo nos dois lugares sem nunca digitá-lo
aqui no chat.

### 2.2 Service account do Firebase (`FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY`)

1. Abra **https://console.firebase.google.com** → selecione o projeto
   **fifa-queue**.
2. Clique na engrenagem ⚙️ ao lado de "Visão geral do projeto" (canto
   superior esquerdo) → **Configurações do projeto**.
3. Vá na aba **Contas de serviço** ("Service accounts").
4. Na seção **Firebase Admin SDK**, clique em **Gerar nova chave privada**
   ("Generate new private key") → confirme no modal.
5. O navegador baixa um arquivo `fifa-queue-firebase-adminsdk-xxxxx.json`.
   **Isso só pode ser feito uma vez por chave gerada** — se perder o
   arquivo, gere outra (a antiga pode ser revogada na mesma tela).
6. Abra o JSON localmente (nunca cole o conteúdo aqui no chat). Ele tem este
   formato:
   ```json
   {
     "type": "service_account",
     "project_id": "fifa-queue",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@fifa-queue.iam.gserviceaccount.com",
     ...
   }
   ```
   - `FIREBASE_CLIENT_EMAIL` = o campo `client_email`.
   - `FIREBASE_PRIVATE_KEY` = o campo `private_key` **inteiro, com as
     sequências `\n` literais como estão no JSON** — o código da Edge
     Function (`pemToDer`) já espera exatamente esse formato
     (`.replace(/\\n/g, '\n')`), então não precisa reformatar nada, só
     copiar o valor do campo como está.
7. Depois de configurar o secret (seção 3), **apague o arquivo JSON baixado**
   do seu disco (ou mova pra um cofre de senhas) — ele nunca deve ficar
   solto numa pasta, e principalmente nunca dentro do repositório.

### 2.3 APNs Authentication Key (.p8) para push no iOS

Precisa de conta paga no Apple Developer Program.

1. Abra **https://developer.apple.com/account** → **Certificates,
   Identifiers & Profiles** → aba **Keys** (menu lateral esquerdo).
2. Clique no **+** para criar uma nova key.
3. Dê um nome (ex.: "FIFA Queue APNs Key"), marque a caixa **Apple Push
   Notifications service (APNs)** → **Continue** → **Register**.
4. Na tela de confirmação, clique **Download** para baixar o arquivo
   `AuthKey_XXXXXXXXXX.p8`. **Só é possível baixar uma vez** — guarde num
   cofre de senhas, nunca solto numa pasta comum (o `.gitignore` já bloqueia
   `*.p8`, mas o ideal é nem deixar chegar perto do repo).
5. Anote também, ainda nessa tela: o **Key ID** (10 caracteres
   alfanuméricos, ex. `ABC123DEFG`) e o seu **Team ID** (visível no canto
   superior direito de qualquer página do Apple Developer, ou em
   **Membership** no menu).
6. Volte ao **Firebase Console** → **fifa-queue** → Configurações do projeto
   → aba **Cloud Messaging**.
7. Role até **Configuração de apps para Apple** → encontre o app iOS
   (`com.lucasdiogof.fifaqueue`) → seção **Chave de autenticação APNs** →
   **Fazer upload**.
8. Envie o `.p8`, cole o **Key ID** e o **Team ID** → **Fazer upload**.

Depois disso o FCM consegue entregar push no iOS usando essa key — não
precisa de nenhum secret adicional no Supabase para isso (o backend já fala
só com o FCM v1, que internamente repassa pro APNs).

**Pendência separada, ainda no Xcode** (fora do que dá pra fazer neste
ambiente Windows — precisa de um Mac): no target **Runner**, aba **Signing &
Capabilities**, adicionar as capabilities **Push Notifications** e
**Background Modes** → marcar **Remote notifications**. Sem isso o app iOS
nem registra token, mesmo com a APNs key certa no Firebase.

---

## 3. Comandos exatos

### 3.1 Edge Function secrets

Como `FIREBASE_PRIVATE_KEY` é multi-linha, a forma mais segura é um arquivo
`--env-file` local — **nunca digite os valores como argumento direto do
comando** (ficaria no histórico do shell). Crie o arquivo fora de qualquer
pasta rastreada pelo Git ou com extensão `.env` (o `.gitignore` do projeto já
ignora `*.env`/`.env*` em qualquer lugar do repo, então mesmo criando dentro
do projeto ele não vai ser commitado — mas o mais seguro é fora do repo
mesmo, ex. na sua pasta pessoal).

Exemplo do conteúdo do arquivo (`~/fifa-queue-worker.env`, ajuste o caminho):

```env
WORKER_SECRET=<cole aqui o valor do openssl rand -hex 32>
FIREBASE_PROJECT_ID=fifa-queue
FIREBASE_CLIENT_EMAIL=<cole aqui o client_email do JSON>
FIREBASE_PRIVATE_KEY=<cole aqui o private_key do JSON, com os \n literais como estão>
```

Depois, rode (você mesmo, no seu terminal — não precisa me colar nada disso):

```bash
npx supabase@latest secrets set --project-ref lteujeclnhmurcewurkg --env-file ~/fifa-queue-worker.env
```

Confirme que os 4 nomes apareceram (sem mostrar valor nenhum):

```bash
npx supabase@latest secrets list --project-ref lteujeclnhmurcewurkg
```

Depois de confirmado, **apague o arquivo `.env` local**:

```bash
rm ~/fifa-queue-worker.env
```

### 3.2 Supabase Vault

**Caminho recomendado — pelo Dashboard**, porque nunca passa pelo histórico
do shell e tem UI própria pra isso:

1. Abra **https://supabase.com/dashboard/project/lteujeclnhmurcewurkg/settings/vault**
2. **Add new secret** → Name: `notification_worker_url` → Secret value:
   `https://lteujeclnhmurcewurkg.supabase.co/functions/v1/process-notification-outbox`
   (confirme contra a URL exata que o deploy do passo 3.3 vai imprimir) →
   Save.
3. **Add new secret** de novo → Name: `notification_worker_secret` → Secret
   value: o **mesmo valor exato** do `WORKER_SECRET` gerado em 2.1 → Save.

**Alternativa por SQL** (se preferir, mas fica no histórico do terminal —
rode você mesmo, não precisa me passar o valor):

```bash
npx supabase@latest db query --linked "select vault.create_secret('https://lteujeclnhmurcewurkg.supabase.co/functions/v1/process-notification-outbox', 'notification_worker_url');"
npx supabase@latest db query --linked "select vault.create_secret('COLE_O_MESMO_WORKER_SECRET_AQUI', 'notification_worker_secret');"
```

Conferir que os nomes existem (sem expor o valor decifrado):

```bash
npx supabase@latest db query --linked "select name, created_at from vault.secrets where name in ('notification_worker_url','notification_worker_secret') order by name;"
```

### 3.3 Deploy da Edge Function

Sim — **dá pra fazer 100% por CLI**, depois dos secrets prontos (a function
já lê tudo de `Deno.env`, não tem nada hardcoded). Rode:

```bash
npx supabase@latest functions deploy process-notification-outbox --project-ref lteujeclnhmurcewurkg --no-verify-jwt
```

A CLI imprime a URL pública ao final — **confira que bate exatamente** com o
que você colocou em `notification_worker_url` no Vault (passo 3.2). Se
divergir, atualize o valor no Vault (Dashboard → Vault → editar o secret).

---

## 4. Checklist de placeholders a preencher

- [ ] `WORKER_SECRET` gerado (`openssl rand -hex 32`)
- [ ] Service account do Firebase baixada, `FIREBASE_CLIENT_EMAIL` e
      `FIREBASE_PRIVATE_KEY` extraídos, arquivo JSON apagado depois
- [ ] `supabase secrets set --env-file ...` rodado, `secrets list` mostra os
      4 nomes, arquivo `.env` local apagado
- [ ] `notification_worker_url` no Vault
- [ ] `notification_worker_secret` no Vault (== `WORKER_SECRET`)
- [ ] `supabase functions deploy ... --no-verify-jwt` rodado, URL conferida
      contra o Vault
- [ ] APNs key (.p8) gerada no Apple Developer, Key ID + Team ID anotados
- [ ] APNs key enviada ao Firebase Console (Cloud Messaging → Apple app config)
- [ ] Capabilities Push Notifications + Background Modes no target Runner
      (precisa de Mac/Xcode — fora deste ambiente)
- [x] Canal `queue_alerts` registrado no Android (achado 0.2, commit `aaa9c60`)

---

## 5. Sequência de validação ponta a ponta

Precisa dos itens 1-6 do checklist acima já prontos (a parte de iOS/APNs não
bloqueia validar no Android/Web primeiro). Rode cada query com
`npx supabase@latest db query --linked "..."`.

**1. Gerar uma linha na outbox de verdade**, forçando uma promoção real
(usuário QUEUED virando SEARCHING) — reaproveite o padrão dos scripts
`qa_*.js` já usados nas Etapas 5/6 (criar 2 usuários reais, ambos num time,
A busca, B busca — B fica QUEUED —, A cancela ou dá match-found, B é
promovido). Depois de promover, confira que a outbox recebeu a linha:

```sql
select id, type, team_id, processed_at, attempt_count, last_error
from public.notification_outbox
order by created_at desc limit 5;
```
Espera-se uma linha `type = 'YOUR_TURN'`, `processed_at is null` (ainda não
processada).

**2. Worker consumir** — o trigger já deve ter disparado sozinho (pg_net,
segundos de latência). Se quiser forçar manualmente sem esperar:
```bash
curl -X POST "https://lteujeclnhmurcewurkg.supabase.co/functions/v1/process-notification-outbox" \
  -H "x-worker-secret: <o mesmo WORKER_SECRET>" -H "Content-Type: application/json" -d '{"trigger":"manual"}'
```
Resposta esperada: `{"claimed":1,"delivered":1,"failed":0}` (ou `delivered:0`
se não houver device ativo — ver item 4 abaixo).

**3. FCM aceitar** — confirmado pelo `delivered` no JSON acima, ou por
`processed_at` não-nulo e `last_error is null` na outbox:
```sql
select id, processed_at, last_error from public.notification_outbox order by created_at desc limit 1;
```

**4. Token receber** — precisa de um device real com o app instalado,
logado, com um `user_devices.fcm_token` ativo (`is_active = true`) e
notificações permitidas no sistema (o canal `queue_alerts` já é criado
automaticamente pelo app no Android, achado 0.2 corrigido). Confirme o
device ativo:
```sql
select user_id, platform, is_active, updated_at from public.user_devices order by updated_at desc limit 5;
```

**5. Outbox marcar processed** — mesma query do passo 3; `processed_at`
preenchido e `last_error is null` é sucesso.

**6. Token inválido ser desativado** — force artificialmente com um token
falso (sem device real): insira um `user_devices` de teste com um
`fcm_token` inventado (ex. `'invalid-token-for-qa-test'`), gere uma outbox
pra esse usuário, rode o worker e confirme:
```sql
select is_active from public.user_devices where fcm_token = 'invalid-token-for-qa-test';
```
Espera-se `is_active = false` depois do worker rodar (o FCM responde
`UNREGISTERED`/`INVALID_ARGUMENT`, `deactivate_device_token` é chamado).
**Lembre de limpar esse device de teste depois** (mesma disciplina de
cleanup das Etapas 5/6 — zero resíduo ao final).

Depois de validar, rode a mesma limpeza de sempre (deletar usuários/times de
teste via `db query --linked`, cascata cuida do resto) e confirme zero linhas
residuais nas 3 tabelas de notificação antes de considerar fechado.
