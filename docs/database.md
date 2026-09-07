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

`match_search_events`, `devices`, `notification_preferences` e
`user_settings`. `teams`, `team_members`, `team_invite_links`,
`match_search_sessions` e `match_search_queue` já existem — foram criadas
nas Etapas 3 a 5.

## Realtime: `public.team_matchmaking_revisions`

| Coluna | Tipo | Notas |
| --- | --- | --- |
| `team_id` | `uuid` | PK e FK para `teams(id)`, `on delete cascade` |
| `revision` | `bigint` | Contador monotonico. Diagnostico, nao estado |
| `updated_at` | `timestamptz` | `now()` a cada incremento |

### Por que ela existe

A Etapa 5 deixou `match_search_sessions` e `match_search_queue` com RLS
ativa, **zero policies e zero grants** — todo acesso passa por RPC. Postgres
Changes so entrega linha que o assinante consegue `SELECT`, entao assinar
aquelas tabelas exigiria abrir leitura direta nelas: a fila e os horarios de
busca do time passariam a ser legiveis por PostgREST, fora do read model
controlado, so para ganhar um "algo mudou".

Esta tabela e o contrario: existe para ser lida, e nao carrega estado
nenhum. O maximo que revela e "houve atividade neste time" — e so para quem
ja e membro dele.

**O estado oficial continua vindo apenas de `get_team_matchmaking_state`.**
Nenhum evento e aplicado como patch local no cliente.

### Policies e grants

| Regra | Efeito |
| --- | --- |
| `team_matchmaking_revisions_select_member` (`select`, `authenticated`) | So membros do time enxergam a linha, via `public.is_team_member(team_id)` |
| Sem policy de `insert`/`update`/`delete` | O cliente nunca escreve: ninguem forja um evento |
| `revoke all ... from anon` | Anonimo toma `42501` antes de qualquer RLS |
| `grant select ... to authenticated` | Unico privilegio concedido |

A tabela esta na publication `supabase_realtime` (adicionada por migration,
nao pelo Dashboard).

### Quem emite

`public._notify_matchmaking_changed(team_id)` faz um upsert incrementando
`revision`. E chamada **so** de dentro das RPCs security definer, sempre
depois que o estado final da operacao ja foi escrito.

Como e um write comum, participa da transacao: **se a RPC falhar e der
rollback, o evento nao acontece** — nenhum cliente e avisado de uma mudanca
que nao existiu.

Regra de emissao — no maximo uma notificacao por transacao, e so quando algo
mudou de verdade:

| Origem | Notifica? |
| --- | --- |
| `request_match_search` que criou sessao ou entrada de fila | sim |
| `request_match_search` repetido de quem ja esta no estado | nao |
| `cancel_match_search` / `report_match_found` | sim |
| `get_team_matchmaking_state` (leitura pura) | **nao** |
| Qualquer RPC cuja expiracao lazy corrigiu uma sessao vencida | sim |
| `process_expired_searches` (pg_cron) por time expirado | sim |

A linha de baixo dessa tabela e a mais importante: se a leitura notificasse,
cada refresh de um cliente viraria evento para todos os outros, que leriam de
novo, que notificariam de novo. Por isso `_expire_team_search_if_needed`
passou a devolver `boolean` — o chamador so avisa quando ela realmente agiu.

### Ordem e duplicidade

O cliente nunca deriva estado do evento, entao evento repetido, fora de
ordem ou atrasado e inofensivo: no pior caso provoca uma releitura
redundante, que o debounce de 200ms do cubit ainda agrupa.
