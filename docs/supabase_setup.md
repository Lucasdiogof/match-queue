# Configurar o Supabase

O projeto Supabase do FIFA Queue **ainda não existe**. Nada neste repositório
contém URL, chave ou `project_id` real — `supabase/config.toml` tem
`project_id = ""` esperando o `supabase link`.

Este documento é o passo a passo para sair do zero.

## 1. Criar o projeto

No [dashboard do Supabase](https://supabase.com/dashboard), crie um projeto
novo (região mais próxima do Brasil: `sa-east-1`). Guarde:

- **Project URL** → vira `SUPABASE_URL`
- **Publishable key** (em *Project Settings → API keys*) → vira
  `SUPABASE_PUBLISHABLE_KEY`

Nunca use a **service role key** no app Flutter. Ela ignora RLS inteira e não
tem nenhum motivo para sair do servidor.

## 2. Preencher os environments

```bash
cp env/development.example.json env/development.json
```

```json
{
  "ENVIRONMENT": "development",
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "<publishable key>",
  "APP_LINK_HOST": "",
  "FIREBASE_ENABLED": false,
  "VERBOSE_LOGGING": true
}
```

Os `env/*.json` são ignorados pelo git; só os `*.example.json` são
versionados. `SUPABASE_ANON_KEY` continua aceito como fallback legado, mas a
chave publicável é o nome correto hoje (`anonKey` está deprecado no
`supabase_flutter`).

```bash
flutter run --dart-define-from-file=env/development.json
```

## 3. Aplicar as migrations

As três migrations em `supabase/migrations/` criam todo o schema atual.

### Opção A — Supabase CLI (recomendada)

```bash
supabase link --project-ref <project-ref>
supabase migration list
supabase db push
```

`supabase migration list` antes do push confirma que o histórico local bate
com o que o banco remoto já tem. O CLI **não está instalado no ambiente onde
este código foi escrito**, então as migrations foram escritas à mão no
formato oficial e nunca foram aplicadas daqui.

### Opção B — SQL Editor do Dashboard

> **SQL para rodar manualmente.** Se você não for usar o CLI, abra o SQL
> Editor do projeto e cole os três arquivos **nesta ordem**, um de cada vez:
>
> 1. `supabase/migrations/20260907120000_create_profiles.sql`
> 2. `supabase/migrations/20260907120100_profiles_auto_create.sql`
> 3. `supabase/migrations/20260907120200_profiles_rls.sql`
>
> Eles não são idempotentes de propósito (sem `IF NOT EXISTS` decorativo) —
> rodar duas vezes dá erro, e isso é o comportamento desejado.

## 4. Configurações de Auth no Dashboard

Estas **não** vivem em migration. Precisam ser ajustadas na interface.

### Authentication → Sign In / Providers → Email

| Configuração | Valor | Por quê |
| --- | --- | --- |
| **Enable email provider** | ligado | é o único provider da primeira versão |
| **Confirm email** | **desligado** | decisão de produto: o cadastro cria a sessão na hora, sem passar pela caixa de entrada |
| **Minimum password length** | `8` | espelha `AppValidators.passwordMinLength` |
| **Secure password change** | opcional | exige reautenticação para trocar senha |

Se "Confirm email" ficar ligado por engano, o app não finge que autenticou:
`signUp` volta sem sessão, vira
`AuthFailureReason.emailConfirmationRequired` e a tela de cadastro mostra a
mensagem pedindo a confirmação. Isso serve de alarme de configuração errada.

### Authentication → URL Configuration

| Campo | Valor |
| --- | --- |
| **Site URL** | dev Web: `http://localhost:<porta>` — produção: o domínio, quando existir |
| **Redirect URLs** | `http://localhost:<porta>/reset-password`, `com.lucasdiogof.fifaqueue://auth-callback` |

A porta do `flutter run -d chrome` muda a cada execução. Para não brigar com
a allowlist, fixe uma:

```bash
flutter run -d chrome --web-port=5000 --dart-define-from-file=env/development.json
```

e cadastre `http://localhost:5000` e
`http://localhost:5000/reset-password`.

O redirect mobile `com.lucasdiogof.fifaqueue://auth-callback` já está
registrado no `AndroidManifest.xml` (intent-filter) e no `Info.plist`
(`CFBundleURLTypes`) — é um scheme próprio, não depende de domínio.

Quando o domínio existir, defina `APP_LINK_HOST` no environment: a partir daí
o redirect da Web passa a ser `https://<host>/reset-password` em vez do
origin atual.

## 5. Conferir que funcionou

1. Crie uma conta pelo app.
2. No Dashboard, *Authentication → Users*: o usuário deve aparecer com
   `raw_user_meta_data` contendo `display_name`.
3. *Table Editor → profiles*: deve existir uma linha com o mesmo `id` e o
   `display_name` preenchido.
4. Faça logout, login de novo, e edite o nome no Perfil.

Se o usuário aparecer em `auth.users` mas não em `profiles`, o trigger falhou
em silêncio — procure o `raise warning 'handle_new_user falhou...'` nos logs
do Postgres. O app se recupera sozinho criando o profile no próximo acesso,
mas a causa merece investigação.
