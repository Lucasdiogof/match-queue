# Flavors por jogo (Match Queue)

Fundação: commit `c8df926` (`feat: add game flavor foundation`) + o commit que
adiciona o flavor `efootball`. Este doc registra as decisões que não são
óbvias só de ler o código.

## Convenção de nomes

Um único identificador por jogo, usado (com a mesma grafia) em todo lugar:

| Jogo      | `GameFlavorKey.key` (Dart) | Flavor Android/scheme iOS | applicationId / Bundle ID              |
|-----------|----------------------------|---------------------------|-----------------------------------------|
| EA FC     | `ea_fc`                    | `eaFc`                    | `com.lucasdiogof.fifaqueue`             |
| eFootball | `efootball`                | `efootball`               | `com.lucasdiogof.matchqueue.efootball`  |

Comandos:

```bash
# EA FC
flutter run --flavor eaFc --dart-define-from-file=env/development.json --dart-define=APP_GAME=ea_fc
flutter build apk --release --flavor eaFc --dart-define-from-file=env/production.json --dart-define=APP_GAME=ea_fc
flutter build ipa --release --flavor eaFc --dart-define-from-file=env/production.json --dart-define=APP_GAME=ea_fc

# eFootball
flutter run --flavor efootball --dart-define-from-file=env/efootball/development.json --dart-define=APP_GAME=efootball
flutter build apk --release --flavor efootball --dart-define-from-file=env/efootball/production.json --dart-define=APP_GAME=efootball
flutter build ipa --release --flavor efootball --dart-define-from-file=env/efootball/production.json --dart-define=APP_GAME=efootball
```

`--flavor` ficou **obrigatório** em Android/iOS desde que os productFlavors
foram criados (mesmo pra EA FC). Web não usa `--flavor`.

## Scheme do callback do Supabase Auth (`AUTH_CALLBACK_SCHEME` / `APP_URL_SCHEME`)

Cada jogo tem seu próprio scheme de deep link para o callback de
recuperação de senha (`<scheme>://auth-callback`). Hoje, por coincidência
histórica, o scheme do EA FC é literalmente igual ao seu bundle id
(`com.lucasdiogof.fifaqueue`) — mas os dois conceitos são **independentes**:

- **iOS**: build setting `AUTH_CALLBACK_SCHEME`, definido explicitamente em
  cada uma das 6 `XCBuildConfiguration` do target `Runner`
  (`Debug/Release/Profile` × `eaFc/efootball`). O `Info.plist` referencia
  `$(AUTH_CALLBACK_SCHEME)`, nunca `$(PRODUCT_BUNDLE_IDENTIFIER)` — os dois
  hoje têm o mesmo valor para os dois jogos, mas isso é coincidência, não
  uma regra.
- **Android**: `manifestPlaceholders["authCallbackScheme"]` em cada
  `productFlavor` (`build.gradle.kts`), usado pelo
  `android:scheme="${authCallbackScheme}"` no `AndroidManifest.xml`.
- **Dart**: `APP_URL_SCHEME` (dart-define, lido em `AppConfig.appUrlScheme`).
  Ausente = mantém o valor atual do EA FC (retrocompatibilidade com builds
  existentes). Usado por `AuthRedirects.passwordReset` pra montar o
  `redirectTo` do Supabase.
- **Guard cross-flavor**: `GameConfig.expectedUrlScheme` +
  `assertGameMatchesConfig()` (chamado no `bootstrap()`) comparam o
  `APP_URL_SCHEME` resolvido em runtime contra o valor esperado pro jogo que
  `APP_GAME` resolveu. Se um build passar o env/dart-define do flavor
  errado, o app falha alto e cedo em vez de rodar com o backend/scheme
  trocado.

**Nenhum dos três (iOS/Android/Dart) deriva o scheme do bundle id/applicationId
automaticamente** — os três valores são escritos explicitamente, um por um,
por jogo. Se algum dia divergirem por engano, o guard cross-flavor pega isso
via `APP_URL_SCHEME`/`expectedUrlScheme` (mas não audita o Xcode/Gradle
diretamente — é responsabilidade de quem mexer nesses arquivos manter os
três em sincronia).

## Configuração Debug/Release/Profile (iOS)

`Profile-efootball` **não tem** `baseConfigurationReference` (nenhum
`.xcconfig` próprio) — isso é intencional e espelha exatamente como o
`Profile` original do Runner (EA FC) já era antes desta fundação: só
`Debug`/`Release` usam xcconfig (`Debug.xcconfig`/`Release.xcconfig`,
incluídos por `Debug-efootball.xcconfig`/`Release-efootball.xcconfig`);
`Profile` sempre foi definido inteiramente inline em `buildSettings`, sem
arquivo de config. Não criamos `Profile-efootball.xcconfig` porque não
existiria nada de diferente pra incluir além do que já está inline.

## Firebase (Android + iOS + Dart)

**Decisão fixada** (2026-09-26): Firebase é **1 projeto único** (`fifa-queue`)
compartilhado por todos os jogos, com **1 app Android + 1 app iOS por jogo**
registrados dentro dele — nunca um projeto Firebase por jogo. Isso é
diferente do Supabase (que é 1 projeto **totalmente separado** por jogo).
Motivo: Firebase aqui só serve FCM + Crashlytics, sem Analytics/Firestore/
Auth — nada que precise de isolamento por projeto; um único console pra
gerenciar quota/billing/IAM dos 4 jogos é mais simples, e cada jogo mesmo
assim tem seu próprio service account/app id, então push de um jogo nunca
mistura com o de outro. Mesmo padrão usado no Fan Hub (Firebase
centralizado com N apps, Supabase separado por clube).

**Cada jogo precisa do próprio app registrado** dentro desse projeto Firebase
único, nunca reaproveitando o app de outro jogo:

- **Nível Dart (proteção real)**: `Firebase.initializeApp()` não usa
  `DefaultFirebaseOptions.currentPlatform` fixo — usa
  `GameFirebaseOptions.forGame(gameConfig.key)`
  (`lib/core/firebase/game_firebase_options.dart`), que despacha pro app
  Firebase certo por jogo: `ea_fc.DefaultFirebaseOptions` (gerado pelo
  FlutterFire CLI) ou `EfootballFirebaseOptions`
  (`lib/games/efootball/efootball_firebase_options.dart`, valores extraídos
  manualmente dos arquivos baixados do Firebase Console — apiKey/appId por
  jogo, nunca reaproveitados entre eles). Jogo sem app Firebase registrado
  (UFL/GOALS por enquanto) lança `UnsupportedError` explícito em vez de
  herdar options de outro jogo.
- **Nível Android (build-time) — ✅ resolvido em 2026-09-26**: os 2 apps
  Android (EA FC + eFootball) estão registrados no mesmo projeto Firebase
  `fifa-queue`; `android/app/google-services.json` já tem os dois clients.
  `flutter build apk --flavor efootball` builda normalmente.
- **Nível iOS (Dart) — ✅ resolvido em 2026-09-26**: app iOS do eFootball
  registrado no Firebase Console (mesmo projeto), `EfootballFirebaseOptions`
  já tem os valores reais dele. `GameFirebaseOptions.forGame` nunca mistura
  isso com o app do EA FC.
- **Nível iOS (arquivo nativo) — ✅ resolvido**: um `GoogleService-Info.plist`
  por bundle id, em `ios/Runner/Firebase/<PRODUCT_BUNDLE_IDENTIFIER>/`
  (`com.lucasdiogof.fifaqueue` e `com.lucasdiogof.matchqueue.efootball`).
  Os arquivos continuam **fora do git** (`.gitignore`), um por checkout.
  - O plist saiu da fase *Resources*. A build phase
    `Copy GoogleService-Info.plist` copia o do bundle id do target para o
    `.app` e **falha o build** se o arquivo não existir ou se o `BUNDLE_ID`
    dentro dele não for o do target: o eFootball não tem como sair com o
    plist do EA FC.
  - O upload de símbolos do Crashlytics usa
    `--build-configuration="${CONFIGURATION}"`; o `firebase.json` mapeia as 6
    configurações (`Debug/Release/Profile` × EA FC/eFootball) para o app certo.
  - `flutterfire configure` grava no caminho novo (`fileOutput`).
  - Regressão coberta por
    `test/games/efootball/efootball_ios_firebase_native_config_test.dart`.

### Apps Firebase registrados (2026-09-26)

Dentro do projeto **`fifa-queue`**:

| Plataforma | Bundle/package | App ID Firebase |
|---|---|---|
| Android EA FC | `com.lucasdiogof.fifaqueue` | `1:927848400584:android:440f5130571f0b4af187fd` |
| Android eFootball | `com.lucasdiogof.matchqueue.efootball` | `1:927848400584:android:7a07e89557b50579f187fd` |
| iOS EA FC | `com.lucasdiogof.fifaqueue` | `1:927848400584:ios:c43993856e4893bef187fd` |
| iOS eFootball | `com.lucasdiogof.matchqueue.efootball` | `1:927848400584:ios:f4790db0cb90c8d2f187fd` |

Se precisar registrar um app novo (UFL/GOALS no futuro): Firebase Console →
projeto `fifa-queue` → Add app → preencher package/bundle id → baixar
`google-services.json` (Android, substitui o atual, ele acumula todos os
clients) ou `GoogleService-Info.plist` (iOS, guardar à parte) → extrair
`apiKey`/`appId`/etc. pra um novo `<jogo>_firebase_options.dart` seguindo o
padrão de `efootball_firebase_options.dart` → registrar em
`GameFirebaseOptions.forGame`.

## Supabase por flavor

Cada jogo tem projeto Supabase **totalmente separado**. EA FC continua no
projeto atual; eFootball usa `env/efootball/{development,production}.json`
(nunca commitados, só os `.example.json`). Nenhum valor de fallback
hardcoded aponta pro Supabase do EA FC — `SUPABASE_URL`/
`SUPABASE_PUBLISHABLE_KEY` vêm exclusivamente do dart-define; ausentes,
o app cai no `StartupFailureApp` (tela de erro de config), nunca em um
backend default.

### Guards cross-flavor (`assertGameMatchesConfig`, mobile: `assertNativePackageMatchesGame`)

O guard original só comparava `APP_URL_SCHEME` — insuficiente sozinho (um
env com `APP_GAME`/`APP_URL_SCHEME` corretos ainda podia ter
`SUPABASE_URL` de outro jogo). Hoje `assertGameMatchesConfig` (chamado no
`bootstrap()`) faz três checagens independentes, qualquer uma barra o
boot:

1. `APP_URL_SCHEME` bate com `GameConfig.expectedUrlScheme`;
2. `APP_BACKEND_GAME` (o env se autodeclarando "sou o backend de qual
   jogo") bate com o `GameFlavorKey` resolvido — cada `env/*.json` agora
   tem essa chave explícita (`APP_BACKEND_GAME: "ea_fc"` ou `"efootball"`);
   ausente = `ea_fc` (retrocompatibilidade com os envs existentes);
3. se o jogo já tem `GameConfig.expectedSupabaseProjectRef` conhecido (só
   o EA FC por enquanto — `lteujeclnhmurcewurkg`, extraído do
   `SUPABASE_URL` real), o ref derivado do `SUPABASE_URL` carregado precisa
   bater. eFootball fica com esse campo `null` até o Supabase dele existir
   — o guard 3 simplesmente não roda pra ele ainda; guards 1 e 2 continuam
   valendo.

Além disso, **em Android/iOS** (nunca Web/desktop),
`assertNativePackageMatchesGame` compara o applicationId/bundle id
**nativo de verdade** (lido em runtime via `package_info_plus`, decidido
pelo productFlavor/xcconfig no build nativo — nenhum dart-define consegue
mentir isso) contra `GameConfig.expectedPackageIdentifiers`. É a checagem
mais forte: mesmo que TODOS os dart-defines estejam errados/trocados, o
app nativo `efootball` nunca passa se resolver `APP_GAME=ea_fc` (ou
vice-versa).

Nenhum desses guards substitui uma futura validação mais rígida do project
ref do eFootball quando o Supabase dele existir de verdade — só reduzem a
superfície de erro humano (comando de build com env/flavor trocados) até lá.

## App Links / deep links

`https://lucksrei.com/join`, `/u` continuam declarados no
`AndroidManifest.xml` **compartilhado** entre os dois flavors (ver
comentário `PENDENTE multi-game` no arquivo). Na prática isso não deve
"roubar" links do EA FC porque o `assetlinks.json` de `lucksrei.com` só
verifica o certificado/package do EA FC — o eFootball nunca fica
`autoVerify`-aprovado para esse domínio. Ainda assim, **eFootball não tem
domínio de deep link próprio decidido** e não foi registrado em nenhum
`assetlinks.json`/AASA. Antes de publicar o eFootball de verdade, mover o
bloco de App Links pra um `AndroidManifest.xml` exclusivo do flavor `eaFc`
(`android/app/src/eaFc/AndroidManifest.xml`).

## Bottom nav / Mercado

A navegação raiz atual é **Central | Times | Jogar | Mercado | Conta**
(Solicitações vive dentro da aba Times, como sub-aba com badge) — decisão de
produto de `a6504b2` (16/09), não uma regressão desta fundação. Isso não foi
alterado aqui; ver conversa/commit para decidir se isso deve mudar
independentemente do trabalho de flavors.
