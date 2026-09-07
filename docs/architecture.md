# Arquitetura

## Camadas

```
app/        composition root — bootstrap, DI, router, MaterialApp
core/       infraestrutura transversal, sem regra de negócio
features/   feature-first; cada feature tem data / domain / presentation
shared/     widgets e helpers reaproveitados entre features
```

### Regras de dependência

| Camada | Pode depender de |
| --- | --- |
| `app` | tudo (é o ponto de composição) |
| `features/*/presentation` | `domain` da própria feature, `core`, `shared` |
| `features/*/data` | `domain` da própria feature, `core` |
| `features/*/domain` | **nada de infraestrutura** — sem Flutter UI, Supabase, Firebase ou get_it |
| `core` | pacotes de infraestrutura; **não** importa `features` |
| `shared` | `core` |

Duas consequências práticas disso:

- **`Supabase.instance.client` nunca aparece em Widget, Page ou Cubit.** O
  client é injetado no `SupabaseAuthRemoteDataSource` pelo módulo de DI.
- **`core/navigation` guarda apenas os contratos de rota** (`AppRoutes`,
  `GoRouterRefreshStream`, url strategy). A montagem do `GoRouter`, que
  precisa importar páginas de features, mora em `app/router/app_router.dart`.

## Injeção de dependência

`get_it` com um único locator (`getIt`, em `core/di/injector.dart`) e
registro dividido por módulo:

```
app/dependencies.dart          registerDependencies(...)
  core/di/core_module.dart     config, logger, prefs, crash, analytics, client
  features/auth/auth_module.dart
  features/settings/settings_module.dart
  features/invitations/invitations_module.dart
```

Escopo de sessão autenticada já está previsto em `SessionScope`
(`core/di/injector.dart`), que empurra/derruba um escopo nomeado `session`
do get_it. Ainda não há nada registrado nele — ele existe para que
repositórios que só fazem sentido com um usuário logado (fila, time,
histórico) possam viver e morrer junto com a sessão.

Widgets **não** chamam `getIt`. As dependências chegam à árvore via
construtor de `FifaQueueApp` e `BlocProvider.value`.

## Estado

Um Cubit por domínio, nenhum `AppCubit` global:

| Cubit | Responsabilidade |
| --- | --- |
| `AuthCubit` | sessão, login, cadastro, logout, recuperação de senha |
| `ProfileCubit` | profile do usuário logado, edição do nome |
| `ThemeCubit` | `ThemeMode` persistido |
| `LocaleCubit` | idioma persistido (`null` = idioma do dispositivo) |
| `PendingInviteCubit` | convite capturado antes da autenticação |

## Erros

`AppFailure` é uma `sealed class` pura (sem Flutter, sem Supabase) em
`core/errors/app_failure.dart`. A tradução de exceções de infraestrutura para
`AppFailure` acontece em um único lugar — `SupabaseErrorMapper` — e a
tradução de `AppFailure` para texto acontece em outro único lugar:
`AppFailureL10n.localizedMessage` (`core/l10n/app_failure_l10n.dart`).

Repositórios lançam `AppFailure`. Cubits capturam `on AppFailure` e colocam a
falha no estado. Não há `try/catch` + `print` espalhado.

## Decisões tomadas nesta etapa

**Sem use cases por enquanto.** Em `auth`, um use case seria apenas um
repasse 1:1 para o repositório. A pasta `domain/usecases/` será criada quando
existir orquestração real (ex.: "iniciar busca" precisará validar estado do
time, chamar RPC e atualizar fila). A estrutura já suporta isso sem
refatoração.

**Sem enums de domínio prematuros.** `PlayerStatus` e `SearchSessionStatus`
não foram criados: eles pertencem à feature de matchmaking, que ainda não
existe. O que a Etapa 1 garante é que, quando existirem, eles nascerão em
`features/matchmaking/domain/entities/` e não em Presentation.

**O timer nunca será fonte da verdade no cliente.** Nada nesta etapa cria
estado de tempo local. Quando `match_search_sessions` existir, o cliente vai
receber `started_at` / `expires_at` e derivar o restante — por isso não há
nenhum `Timer` ou contador embutido em Widget.

## Modelo de dados previsto (ainda não implementado)

Nenhuma migration foi criada nesta etapa. O esboço abaixo existe para que as
decisões tomadas agora não se tornem incompatíveis depois.

```
profiles

teams
team_members            (N:N — um usuário participa de vários times)

team_invites
team_invite_links

games
team_games

match_search_sessions   (started_at, expires_at — fonte da verdade do timer)
match_search_queue
match_search_events     (histórico; sessões não são apagadas ao terminar)

devices
notification_preferences
user_settings
```

Mais adiante, provavelmente: `matches`, `player_statistics`,
`team_statistics`, `audit_logs`.

### Invariantes que pertencem ao backend

- **No máximo um `SEARCHING` por time.** Quando dois jogadores tocam em
  "Buscar" no mesmo instante, quem decide é uma transação/RPC no PostgreSQL —
  nunca o Flutter. O cliente apenas reflete o resultado.
- **O tempo restante é derivado de `expires_at`.** O cliente não guarda
  contador próprio, então fechar o app, bloquear o celular, trocar de
  dispositivo, voltar do background ou reconectar não muda nada.
- **Papéis (`OWNER`, `ADMIN`, `PLAYER`) e RLS** decidem o que cada membro
  pode fazer. A UI só esconde botão; a garantia é no banco.


## Decisões da Etapa 2

**O domínio não conhece o `User` do Supabase.** `AuthRepository` fala em
`AuthUser` e `AuthSnapshot`. `AuthSnapshot` existe porque o app precisa saber
*por que* a sessão mudou — sem ele, `AuthChangeEvent.passwordRecovery`
(evento do gotrue) teria que vazar até a Presentation só para o router
descobrir que deve mandar o usuário para `/reset-password`. O mapeamento de
`AuthChangeEvent` para `AuthSessionEvent` acontece uma única vez, no
`SupabaseAuthRepository`.

**O ciclo de vida do `ProfileCubit` é explícito, não implícito.** Ele é
app-scoped e reage à sessão por meio do `ProfileSessionListener`, um
`BlocListener<AuthCubit>` na raiz da árvore: entra sessão, carrega o profile;
sai sessão, limpa. A alternativa seria registrar o repositório no
`SessionScope` do get_it e reprovisionar os cubits na árvore a cada troca de
sessão — mais cerimônia e mais chances de erro para o mesmo resultado.
`SessionScope` continua existindo, ainda vazio, para os repositórios da
Etapa 3 que realmente só fazem sentido com um time carregado.

O primeiro carregamento não vem do listener: quando o app abre com sessão
restaurada, o `AuthCubit` já resolveu antes da árvore existir e nenhuma
transição acontece. Por isso o `bootstrap` dispara `profileCubit.load()`
diretamente quando encontra um usuário restaurado.

**Validação mora em um lugar só.** `AppValidators` é Dart puro e devolve
enums (`EmailValidationError`, `PasswordValidationError`, ...), não texto —
quem traduz é `validation_l10n.dart`. Assim a regra é testável sem
`BuildContext` e os limites (`displayNameMinLength`, `passwordMinLength`)
ficam no mesmo lugar que as constraints do banco espelham.

**Repositórios locais não são mock de teste, são o modo development.**
`LocalAuthRepository` e `LocalProfileRepository` entram quando não há
Supabase configurado. Isso mantém o app inteiro navegável sem backend e, de
quebra, deixa um fake pronto para quando a etapa de testes chegar.
