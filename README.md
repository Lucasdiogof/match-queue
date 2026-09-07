# FIFA Queue

Coordena quem, dentro de um mesmo time de EA SPORTS FC / Clubs, está
autorizado a procurar partida naquele momento — para que dois companheiros
nunca busquem ao mesmo tempo e acabem caindo um contra o outro.

Apenas um jogador fica em `SEARCHING`. Os demais entram numa fila ordenada e
assumem a busca automaticamente quando o jogador da vez encontra partida,
cancela ou tem o tempo expirado.

> **Estado atual: Etapa 1 — fundação.**
> As features de produto (fila, matchmaking, timer, times, convites,
> histórico, notificações) ainda **não** foram implementadas. Esta etapa
> entrega arquitetura, design system, navegação, environments, i18n e
> bootstrap. Veja [Próximos passos](#próximos-passos).

## Plataformas

Android, iOS e Flutter Web a partir da mesma base. Nenhum serviço específico
de plataforma é inicializado indiscriminadamente: url strategy usa import
condicional e Firebase não é inicializado enquanto não houver projeto.

## Stack

| Camada | Ferramenta |
| --- | --- |
| UI | Flutter 3.44 / Dart 3.12 |
| Estado | `flutter_bloc` (Cubit) |
| DI | `get_it` |
| Navegação | `go_router` |
| Backend | Supabase (Auth, PostgreSQL, Realtime, RLS, RPC, Storage) |
| Persistência local | `shared_preferences` |
| i18n | `flutter_localizations` + ARB (`gen-l10n`) |
| CI | Codemagic (`codemagic.yaml`) |

Firebase (FCM, Crashlytics, Analytics) está previsto e desacoplado, mas
**não** foi adicionado como dependência nesta etapa.

## Arquitetura

Clean Architecture com organização *feature-first*. Detalhes e regras de
dependência em [`docs/architecture.md`](docs/architecture.md).

```
lib/
├── app/                        composition root
│   ├── app.dart                MaterialApp.router + providers
│   ├── bootstrap.dart          main → config → serviços → DI → runApp
│   ├── dependencies.dart       registro de todos os módulos
│   ├── startup_failure_app.dart
│   ├── router/app_router.dart  montagem do GoRouter
│   └── pages/                  splash, shell responsivo, rota inválida
│
├── core/
│   ├── config/                 AppEnvironment, AppConfig, AppConfigScope
│   ├── design_system/
│   │   ├── tokens/             colors, spacing, radii, typography, sizing,
│   │   │                       durations, breakpoints
│   │   ├── theme/              AppTheme + AppSemanticColors (ThemeExtension)
│   │   ├── branding/           BrandAssets, BrandMark, BrandWordmark
│   │   ├── layout/             AppScreenSize, ResponsiveLayout, container
│   │   └── components/         15 componentes base (AppButton, AppCard, ...)
│   ├── di/                     getIt, SessionScope, core module
│   ├── errors/                 AppFailure (sealed, Dart puro)
│   ├── firebase/               FirebaseBootstrap (no-op consciente)
│   ├── l10n/                   AppLocales, context.l10n, AppFailureL10n
│   ├── logging/                AppLogger + LogSanitizer
│   ├── navigation/             AppRoutes, refresh stream, url strategy
│   ├── observability/          CrashReporter, AnalyticsService
│   └── supabase/               SupabaseInitializer, SupabaseErrorMapper
│
├── features/
│   ├── auth/                   data + domain + presentation (completo)
│   ├── settings/               tema e idioma persistidos
│   ├── invitations/            convite pendente + /join/:inviteCode
│   ├── home/ teams/ history/ profile/ onboarding/   placeholders
│
├── shared/widgets/
└── l10n/                       app_pt.arb, app_en.arb, app_es.arb
```

## Como executar

```bash
flutter pub get
cp env/development.example.json env/development.json
flutter run --dart-define-from-file=env/development.json
```

Sem credenciais Supabase o app **abre normalmente em development**: o
`SupabaseInitializer` avisa no log, o `LocalAuthRepository` assume o lugar do
repositório real e a tela de login mostra um cartão "modo local" que permite
navegar por toda a estrutura do app.

### Comandos úteis

```bash
flutter analyze
flutter gen-l10n
dart format .
flutter build web --release --dart-define-from-file=env/production.json
flutter build apk --release --dart-define-from-file=env/production.json
flutter build ipa --release --dart-define-from-file=env/production.json
```

## Environments

Três ambientes: `development`, `staging`, `production`. A configuração é
resolvida em `AppConfig.fromEnvironment()` a partir de `dart-define`, nunca
de valores hardcoded.

| Chave | Uso |
| --- | --- |
| `ENVIRONMENT` | `development` \| `staging` \| `production` |
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | chave publicável (aceita `SUPABASE_ANON_KEY` como fallback) |
| `APP_LINK_HOST` | host dos deep links, quando houver domínio |
| `FIREBASE_ENABLED` | liga o bootstrap do Firebase (hoje ainda no-op) |
| `VERBOSE_LOGGING` | nível de log |

```bash
flutter run --dart-define-from-file=env/development.json
flutter run --dart-define-from-file=env/staging.json
flutter run --dart-define-from-file=env/production.json
```

Os arquivos `env/*.json` são ignorados pelo git; apenas os `*.example.json`
são versionados. No Codemagic os valores vêm de *environment variable
groups*.

Em `staging` e `production`, configuração ausente é erro: o app sobe o
`StartupFailureApp` dizendo exatamente quais chaves faltam. Em `development`,
configuração ausente é tolerada.

## Supabase

O que já está pronto:

- `SupabaseInitializer` centralizado no bootstrap, com PKCE.
- `SupabaseAuthRemoteDataSource` + `SupabaseAuthRepository` implementando o
  contrato de domínio `AuthRepository`.
- `SupabaseErrorMapper` traduzindo `AuthException`, `PostgrestException`,
  `StorageException` e erros de transporte para `AppFailure`.
- Fallback local quando não há credenciais em development.

O que depende de criar o projeto Supabase:

- URL e chave publicável.
- Desativar "Confirm email" em *Authentication → Sign In / Providers*, já que
  o cadastro deve criar a sessão sem passar pelo e-mail.
- Todas as tabelas, RLS, RPC e Edge Functions — nada foi criado nesta etapa.

O modelo de dados previsto (`profiles`, `teams`, `team_members`,
`team_invites`, `team_invite_links`, `match_search_sessions`,
`match_search_queue`, `match_search_events`, ...) está registrado em
[`docs/architecture.md`](docs/architecture.md). Decisão já travada:
**participação em time é muitos-para-muitos** (`team_members`), nunca
`profiles.team_id`.

## Firebase

Propositalmente **não** configurado. Não há pacotes Firebase no `pubspec`,
nem `google-services.json`, nem `GoogleService-Info.plist`, nem
`firebase_options.dart` — e os três estão no `.gitignore`.

O que existe é a fronteira: `FirebaseBootstrap` (consciente de environment e
de `FIREBASE_ENABLED`) e as interfaces `CrashReporter` / `AnalyticsService`,
hoje com implementações que apenas registram log. Quando os projetos
existirem, basta trocar a implementação registrada no `core_module` — nenhum
call site muda.

## Navegação

```
/                       splash / resolução de sessão
/login
/signup
/forgot-password
/onboarding
/join/:inviteCode       público, aceita usuário não autenticado
/app/
├── home                Buscar
├── team                Time
├── history             Histórico
└── profile             Perfil
```

A área autenticada usa `StatefulShellRoute.indexedStack` com quatro branches
e navegação que troca de forma conforme a largura: `NavigationBar` no mobile,
`NavigationRail` no tablet e `NavigationRail` estendido no desktop.

O guard de rota vive no `redirect` do go_router e reage ao `AuthCubit` via
`refreshListenable`.

## Deep links

`/join/:inviteCode` já existe, é acessível sem autenticação e o convite é
persistido caso o usuário ainda não esteja logado — sendo retomado
automaticamente após o login. No Web as URLs já são limpas (sem `#`).

App Links (Android) e Universal Links (iOS) dependem de um domínio, que ainda
não foi definido. O passo a passo está em
[`docs/deep_links.md`](docs/deep_links.md).

## Localization

PT-BR, EN e ES desde o primeiro commit, via ARB + `gen-l10n`
(`l10n.yaml` → `lib/l10n/generated/`).

```dart
Text(context.l10n.inviteJoinTeam)
```

Já há exemplos de parâmetro (`authSignedInAs`), plural
(`invitePlayersCount`), data (`inviteReceivedAt`) e número
(`queuePositionLabel`). Todo placeholder declara metadata `@placeholders`
explicitamente — sem isso o `gen-l10n` ordena os parâmetros alfabeticamente
e troca valores silenciosamente.

O idioma segue o dispositivo quando suportado; caso contrário cai em inglês
(`AppLocales.fallback`). O usuário pode fixar um idioma no Perfil, e a
escolha é persistida.

## Tema

`Light`, `Dark` e `System`, com a preferência persistida em
`SharedPreferences` pelo `ThemeCubit`.

A identidade é preto e branco. Cor só aparece com significado semântico:
verde = sucesso / partida encontrada, amarelo = atenção / tempo acabando,
vermelho = erro / cancelamento / expiração. Esses valores moram em
`AppSemanticColors`, um `ThemeExtension`, acessível por `context.colors`.

| Token | Dark | Light |
| --- | --- | --- |
| background | `#090909` | `#F6F6F7` |
| surface | `#111111` | `#FFFFFF` |
| surface elevated | `#181818` | `#FFFFFF` |
| primary | `#FFFFFF` | `#0A0A0A` |

Os demais tokens (spacing, radii, typography, sizing, durations,
breakpoints) ficam em `core/design_system/tokens/`.

## Responsividade

Três faixas — mobile (`< 600`), tablet (`< 1024`) e desktop (`>= 1024`) —
definidas em `AppBreakpoints`. As ferramentas são:

- `context.screenSize` e `context.responsive(mobile:, tablet:, desktop:)`
- `ResponsiveLayout` para composições realmente diferentes por faixa
- `AppContentContainer` (e as variantes `.narrow` / `.form`) para largura
  máxima e conteúdo centralizado
- `AppScaffold`, que já aplica o container e os gutters por faixa

O Web não é uma tela de celular esticada: o conteúdo tem largura máxima e a
navegação muda de forma.

## Branding

**A logo definitiva não foi criada** e nenhuma decisão visual de marca foi
tomada. Enquanto isso o app usa um monograma `FQ` e o wordmark textual
`FIFA Queue`, ambos gerados em código.

Tudo passa por `BrandAssets` — trocar logo, wordmark, ícone e splash é editar
um arquivo. Ver [`docs/branding.md`](docs/branding.md).

## Testes

Não há testes nesta etapa, por decisão explícita. O código foi escrito para
ser testável depois: domínio isolado, repositórios atrás de interfaces,
Cubits pequenos, DI em todos os pontos de composição e nenhuma lógica dentro
de Widget.

## Próximos passos

1. Criar o projeto Supabase, preencher os `env/*.json` e desativar a
   confirmação de e-mail.
2. Telas finais de autenticação (login, cadastro, recuperação, onboarding).
3. Modelagem do banco: `profiles`, `teams`, `team_members`, convites.
4. Convite por link ponta a ponta + domínio + App Links / Universal Links.
5. Fila e matchmaking com RPC transacional garantindo um único `SEARCHING`.
6. Timer com `started_at` / `expires_at` vindos do backend.
7. Realtime nas mudanças de fila.
8. Histórico e eventos de sessão.
9. Firebase: FCM, Crashlytics, Analytics.
10. Etapa dedicada a testes, auditoria e qualidade.
11. Codemagic com signing e publicação.
