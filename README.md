# FIFA Queue

Coordena quem, dentro de um mesmo time de EA SPORTS FC / Clubs, está
autorizado a procurar partida naquele momento — para que dois companheiros
nunca busquem ao mesmo tempo e acabem caindo um contra o outro.

Apenas um jogador fica em `SEARCHING`. Os demais entram numa fila ordenada e
assumem a busca automaticamente quando o jogador da vez encontra partida,
cancela ou tem o tempo expirado.

> **Estado atual: Etapa 2 concluída — autenticação real e profiles.**
> Cadastro, login, logout, recuperação de senha e edição de perfil funcionam
> contra o Supabase. Fila, matchmaking, timer, times e convites continuam
> para as próximas etapas. Veja [Próximos passos](#próximos-passos).

## Plataformas

Android, iOS e Flutter Web a partir da mesma base. Nenhum serviço específico
de plataforma é inicializado indiscriminadamente: url strategy usa import
condicional e Firebase não é inicializado enquanto não houver projeto.

Bundle / application ID: `com.lucasdiogof.fifaqueue`.

## Stack

| Camada | Ferramenta |
| --- | --- |
| UI | Flutter 3.44 / Dart 3.12 |
| Estado | `flutter_bloc` (Cubit) |
| DI | `get_it` |
| Navegação | `go_router` |
| Backend | Supabase (Auth, PostgreSQL, RLS; Realtime/RPC/Storage previstos) |
| Persistência local | `shared_preferences` |
| i18n | `flutter_localizations` + ARB (`gen-l10n`) |
| CI | Codemagic (`codemagic.yaml`) |

Firebase (FCM, Crashlytics, Analytics) está previsto e desacoplado, mas
**não** foi adicionado como dependência.

## Arquitetura

Clean Architecture com organização *feature-first*. Regras de dependência e
decisões em [`docs/architecture.md`](docs/architecture.md).

```
lib/
├── app/                        composition root
│   ├── app.dart                MaterialApp.router + providers + listeners
│   ├── bootstrap.dart          config → serviços → DI → runApp
│   ├── dependencies.dart       registro de todos os módulos
│   ├── router/app_router.dart  montagem do GoRouter + guards
│   └── pages/                  splash, shell responsivo, rota inválida
│
├── core/
│   ├── config/                 AppEnvironment, AppConfig, AuthRedirects
│   ├── design_system/          tokens, theme, branding, layout, componentes
│   ├── di/                     getIt, SessionScope, core module
│   ├── errors/                 AppFailure (sealed, Dart puro)
│   ├── firebase/               FirebaseBootstrap (no-op consciente)
│   ├── l10n/                   AppLocales, context.l10n, mapeadores de erro
│   ├── logging/                AppLogger + LogSanitizer
│   ├── navigation/             AppRoutes, refresh stream, url strategy
│   ├── observability/          CrashReporter, AnalyticsService
│   ├── supabase/               SupabaseInitializer, SupabaseErrorMapper
│   └── validation/             AppValidators (e-mail, senha, display name)
│
├── features/
│   ├── auth/                   login, cadastro, recuperação, reset
│   ├── profile/                leitura e edição do profile
│   ├── settings/               tema e idioma persistidos
│   ├── invitations/            convite pendente + /join/:inviteCode
│   └── home/ teams/ history/ onboarding/   placeholders
│
├── shared/widgets/
└── l10n/                       app_pt.arb, app_en.arb, app_es.arb

supabase/
├── config.toml
└── migrations/                 schema versionado
```

## Como executar

```bash
flutter pub get
cp env/development.example.json env/development.json
flutter run --dart-define-from-file=env/development.json
```

Sem credenciais Supabase o app **abre normalmente em development**: o
`SupabaseInitializer` avisa no log e os repositórios locais
(`LocalAuthRepository`, `LocalProfileRepository`) assumem o lugar dos reais.
As telas de login e cadastro são as mesmas — as contas criadas ficam só na
memória do dispositivo, e a tela de login mostra um aviso dizendo isso.

Para conectar a um projeto Supabase de verdade, siga
[`docs/supabase_setup.md`](docs/supabase_setup.md).

### Comandos úteis

```bash
flutter analyze
flutter gen-l10n
dart format .
flutter run -d chrome --web-port=5000 --dart-define-from-file=env/development.json
flutter build web --release --dart-define-from-file=env/production.json
flutter build apk --release --dart-define-from-file=env/production.json
flutter build ipa --release --dart-define-from-file=env/production.json
```

## Environments

Três ambientes: `development`, `staging`, `production`, resolvidos em
`AppConfig.fromEnvironment()` a partir de `dart-define` — nunca de valores
hardcoded.

| Chave | Uso |
| --- | --- |
| `ENVIRONMENT` | `development` \| `staging` \| `production` |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | chave publicável (aceita `SUPABASE_ANON_KEY` como fallback legado) |
| `APP_LINK_HOST` | host dos deep links, quando houver domínio |
| `FIREBASE_ENABLED` | liga o bootstrap do Firebase (hoje ainda no-op) |
| `VERBOSE_LOGGING` | nível de log |

Os `env/*.json` são ignorados pelo git; só os `*.example.json` são
versionados. No Codemagic os valores vêm de *environment variable groups*.

Em `staging` e `production`, configuração ausente é erro: o app sobe o
`StartupFailureApp` dizendo exatamente quais chaves faltam. Em `development`,
é tolerada.

## Supabase

Schema versionado em `supabase/migrations/`. Detalhes de tabelas, trigger,
RLS e fluxos em [`docs/database.md`](docs/database.md); passo a passo de
configuração em [`docs/supabase_setup.md`](docs/supabase_setup.md).

Resumo do que existe:

- `public.profiles` — identidade pública do jogador, 1:1 com `auth.users`.
  **Sem e-mail**: ele continua no Auth, e o app o lê da própria sessão.
- `public.handle_new_user()` + trigger em `auth.users` — cria o profile
  usando `raw_user_meta_data->>'display_name'`, com fallbacks e sem nunca
  abortar o signup.
- RLS self-only: o usuário lê, cria e atualiza apenas a própria linha. Sem
  policy de delete (cascade a partir de `auth.users`) e sem acesso `anon`.

A **service role key nunca entra no app Flutter**.

## Autenticação

E-mail e senha via Supabase Auth, **sem confirmação de e-mail** — o cadastro
cria a sessão na hora. Se essa configuração estiver ligada por engano no
Dashboard, o app não finge que autenticou: mostra a mensagem pedindo a
confirmação em vez de deixar o usuário num limbo.

| Tela | Rota |
| --- | --- |
| Login | `/login` |
| Cadastro (nome, e-mail, senha, confirmação) | `/signup` |
| Esqueci minha senha | `/forgot-password` |
| Definir nova senha | `/reset-password` |

Regras: senha com no mínimo 8 caracteres, nome entre 2 e 32 caracteres (os
mesmos limites existem como constraint no banco). A resposta da recuperação
de senha é sempre neutra, exista a conta ou não, para não permitir
enumeração de e-mails cadastrados.

Nenhuma mensagem crua do Supabase chega à UI: `SupabaseErrorMapper` traduz
para `AppFailure` e `AppFailureL10n` traduz para texto localizado.

## Navegação

```
/                       splash / resolução de sessão
/login
/signup
/forgot-password
/reset-password
/onboarding
/join/:inviteCode       público, aceita usuário não autenticado
/app/
├── home                Buscar
├── team                Time
├── history             Histórico
└── profile             Perfil
```

O guard vive no `redirect` do go_router e reage ao `AuthCubit` via
`refreshListenable`:

- não autenticado em rota protegida → `/login`;
- autenticado em `/login` ou `/signup` → `/app/home`;
- sessão de recuperação de senha ativa → `/reset-password`, e só sai de lá
  depois que a senha for salva;
- `/join/:inviteCode` continua aberto para não autenticados.

A área autenticada usa `StatefulShellRoute.indexedStack` com quatro branches
e navegação que troca de forma conforme a largura: `NavigationBar` no mobile,
`NavigationRail` no tablet e rail estendido no desktop.

## Deep links

`/join/:inviteCode` já existe, é acessível sem autenticação e o convite é
persistido com TTL de 24h caso o usuário ainda não esteja logado — sendo
retomado automaticamente após o login.

A recuperação de senha usa um scheme próprio
(`com.lucasdiogof.fifaqueue://auth-callback`) e por isso funciona no mobile
hoje, sem domínio. App Links (Android) e Universal Links (iOS) para o convite
continuam dependendo de um domínio: passo a passo em
[`docs/deep_links.md`](docs/deep_links.md).

## Localization

PT-BR, EN e ES via ARB + `gen-l10n` (`l10n.yaml` → `lib/l10n/generated/`),
uso via `context.l10n.chave`. Todo texto novo — telas, validações, erros e
mensagens de sucesso — existe nos três idiomas.

**Todo placeholder declara `@placeholders` explicitamente**: sem isso o
`gen-l10n` ordena os parâmetros alfabeticamente em vez da ordem do texto e
troca valores em silêncio.

O idioma segue o dispositivo quando suportado; fallback para inglês
(`AppLocales.fallback`). O usuário pode fixar um idioma no Perfil, e a
escolha é persistida.

## Tema

Light/Dark/System, persistido pelo `ThemeCubit`. Tokens em
`core/design_system/tokens/`; cores semânticas em `AppSemanticColors`, um
`ThemeExtension` acessível por `context.colors`.

A identidade é preto e branco. Cor só aparece com significado: verde sucesso,
amarelo atenção, vermelho erro — e nunca sozinha: todo estado semântico vem
acompanhado de ícone e texto.

| Token | Dark | Light |
| --- | --- | --- |
| background | `#090909` | `#F6F6F7` |
| surface | `#111111` | `#FFFFFF` |
| surface elevated | `#181818` | `#FFFFFF` |
| primary | `#FFFFFF` | `#0A0A0A` |

## Responsividade

Mobile (`< 600`), tablet (`< 1024`) e desktop (`>= 1024`), em
`AppBreakpoints`. Ferramentas: `context.screenSize`, `context.responsive`,
`ResponsiveLayout`, `AppContentContainer` (`.narrow` / `.form`) e
`AppScaffold`.

As telas de autenticação usam `AppContentContainer.form` (440px) centrado
vertical e horizontalmente, então no desktop são um cartão de formulário — e
não uma tela de celular esticada.

## Branding

**A logo definitiva não foi criada.** O app usa um monograma `FQ` e o
wordmark textual `FIFA Queue`, ambos gerados em código, e tudo passa por
`BrandAssets` — trocar logo, wordmark, ícone e splash é editar um arquivo.
Ver [`docs/branding.md`](docs/branding.md).

## Testes

Ainda não há testes, por decisão explícita. O código foi escrito para ser
testável depois: domínio isolado, repositórios atrás de interfaces
(com implementações locais que servem de fake pronto), validadores puros,
Cubits pequenos e nenhuma lógica dentro de Widget.

## Próximos passos

1. **Etapa 3** — times, membros e criação do primeiro time (`teams`,
   `team_members`, papéis OWNER/ADMIN/PLAYER) e a policy de leitura de
   profiles por companheiro de time.
2. Convite por link ponta a ponta + domínio + App Links / Universal Links.
3. Fila e matchmaking com RPC transacional garantindo um único `SEARCHING`.
4. Timer com `started_at` / `expires_at` vindos do backend.
5. Realtime nas mudanças de fila.
6. Histórico e eventos de sessão.
7. Upload de avatar (Storage).
8. Firebase: FCM, Crashlytics, Analytics.
9. Etapa dedicada a testes, auditoria e qualidade.
10. Codemagic com signing e publicação.
