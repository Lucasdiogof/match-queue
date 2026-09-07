# Banco de dados

Tudo que existe hoje no schema do FIFA Queue nasceu de migrations em
`supabase/migrations/`. Não há alteração feita à mão no Dashboard — a única
coisa que vive lá são as configurações administrativas de Auth, listadas em
[`supabase_setup.md`](supabase_setup.md).

## `public.profiles`

| Coluna | Tipo | Notas |
| --- | --- | --- |
| `id` | `uuid` | PK e FK para `auth.users(id)`, `on delete cascade` |
| `display_name` | `text` | Obrigatório, 2–32 caracteres após `btrim`, não precisa ser único |
| `avatar_url` | `text` | Nulo hoje; upload é etapa futura. Só aceita `https://` |
| `locale` | `text` | Nulo hoje; reservado caso o idioma passe a seguir a conta |
| `created_at` | `timestamptz` | `now()` |
| `updated_at` | `timestamptz` | `now()`, mantido pelo trigger `profiles_set_updated_at` |

Constraints:

- `profiles_display_name_not_blank` — `btrim(display_name) <> ''`, então um
  nome só de espaços é rejeitado no banco, não apenas na UI.
- `profiles_display_name_length` — entre 2 e 32 caracteres. Os mesmos limites
  vivem em `AppValidators.displayNameMinLength/MaxLength` no app.
- `profiles_avatar_url_scheme` e `profiles_locale_format` — formato.

### Por que não existe `email` aqui

O e-mail de autenticação pertence ao Supabase Auth e continua em
`auth.users`, que o cliente nunca lê. Copiá-lo para uma tabela lida por
outros usuários criaria, na prática, um diretório pesquisável de e-mails de
jogadores. Convite por e-mail, quando chegar, será resolvido no backend
(RPC/Edge Function) recebendo o endereço e devolvendo só um resultado, sem
nunca expor a lista.

O e-mail exibido na tela de Perfil vem da sessão do próprio usuário
(`AuthUser.email`), não de uma query em tabela.

## Como o profile nasce

```
signUp(email, password, data: {display_name: "Lucas"})
        │
        ├── auth.users recebe a linha nova
        │      raw_user_meta_data = {"display_name": "Lucas"}
        │
        ├── trigger on_auth_user_created (AFTER INSERT)
        │      └── public.handle_new_user()
        │             raw_user_meta_data->>'display_name'
        │             ↓ (se vazio) raw_user_meta_data->>'name'
        │             ↓ (se vazio) parte local do e-mail
        │             ↓ (se < 2 caracteres) 'Jogador'
        │             insert into public.profiles ... on conflict do nothing
        │
        └── sessão criada, app entra autenticado
```

`handle_new_user` é `security definer` com `search_path = ''` (nomes sempre
qualificados) e tem um `exception when others` que registra `raise warning` e
deixa o signup seguir. A escolha é deliberada: um usuário sem profile é
recuperável, um signup que falha inteiro não é.

A rede de recuperação fica no app: `ProfileCubit.load()` chama
`ensureMyProfile`, que faz `select` e, se não achar nada, faz o `insert` do
próprio profile (permitido pela policy `profiles_insert_own`). Isso cobre
contas criadas antes desta migration ou criadas fora do app.

## RLS

RLS está habilitada em `public.profiles`. Todas as policies são
`to authenticated` — a role `anon` não casa com nenhuma e, além disso, teve
o grant removido.

| Policy | Comando | Permite |
| --- | --- | --- |
| `profiles_select_own` | `select` | Ler apenas a própria linha (`auth.uid() = id`) |
| `profiles_insert_own` | `insert` | Criar apenas a própria linha (`with check auth.uid() = id`) |
| `profiles_update_own` | `update` | Atualizar apenas a própria linha; `using` + `with check` amarrados ao `auth.uid()`, então trocar o `id` da linha para o de outra pessoa é rejeitado |

Não existe policy de `delete`: o profile morre junto com o usuário via
`on delete cascade`, não pela mão do cliente.

`auth.uid()` aparece dentro de um `select` nas policies para o Postgres
avaliar a função uma vez por query em vez de uma vez por linha.

### Por que self-only e não "todo autenticado lê"

Companheiros de time vão precisar ver nome e avatar uns dos outros, mas quem
é companheiro de quem só passa a existir com `team_members`, na Etapa 3.
Abrir leitura para qualquer usuário autenticado agora entregaria a lista
inteira de jogadores da plataforma sem nenhuma necessidade atual. A policy de
leitura por time entra junto com a tabela que a define.

## Fluxos de Auth

| Fluxo | O que acontece |
| --- | --- |
| **signup** | `signUp` com `display_name` em user metadata → trigger cria o profile → sessão criada na hora (confirmação de e-mail desligada) → `AuthCubit` emite `authenticated` → `ProfileSessionListener` carrega o profile |
| **login** | `signInWithPassword` → sessão → mesmo caminho de profile |
| **logout** | `signOut` → `AuthCubit` volta para `unauthenticated` → `ProfileCubit.clear()` → guard do router leva para `/login` |
| **restore session** | `Supabase.initialize` recupera a sessão antes do `runApp`; `AuthCubit.initialize()` lê `currentUser` de forma síncrona, então o app já monta resolvido e nunca pisca Login antes da Home |
| **forgot password** | `resetPasswordForEmail` com `redirectTo` calculado por `AuthRedirects` — na Web `<origin>/reset-password`, no mobile `com.lucasdiogof.fifaqueue://auth-callback`. A UI responde sempre com a mesma mensagem neutra, exista a conta ou não |
| **reset password** | O link devolve uma sessão de recuperação; `AuthChangeEvent.passwordRecovery` vira `AuthState.isPasswordRecovery`, o guard força `/reset-password`, e `updateUser(password:)` grava a nova senha e limpa a flag |

## O que ainda não existe

`teams`, `team_members`, `team_invites`, `team_invite_links`,
`match_search_sessions`, `match_search_queue`, `match_search_events`,
`devices`, `notification_preferences`, `user_settings`. Nenhuma decisão desta
etapa conflita com eles — em particular, participação em time continua sendo
N:N via `team_members`, nunca `profiles.team_id`.
