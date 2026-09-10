# iOS — continuar o release num Mac

> **Atualizado em 2026-09-10, numa sessão real de macOS** (Xcode 26.5,
> Flutter 3.44.1 via FVM, iPhone 17 Pro Simulator / iOS 26.5). A versão
> anterior deste documento era uma auditoria 100% estática feita no
> Windows; três das conclusões dela estavam erradas e foram corrigidas
> abaixo — ver "Correções à auditoria do Windows".

## O que já foi executado neste Mac

| Etapa | Resultado |
| --- | --- |
| Flutter fixado no projeto (`fvm use 3.44.1`) | **DONE** — `.fvmrc` versionado; Dart 3.12.1 satisfaz `sdk: ^3.12.1` |
| Resolução de plugins nativos iOS | **DONE** — via Swift Package Manager (não CocoaPods; ver correções) |
| `IPHONEOS_DEPLOYMENT_TARGET` 13.0 → **15.0** | **DONE** — era bloqueio real de build (ver correções) |
| `ios/Runner/Runner.entitlements` criado | **DONE** — `aps-environment` + `applinks:lucksrei.com` |
| `CODE_SIGN_ENTITLEMENTS` ligado nas 3 configs do target Runner | **DONE** — Debug, Profile e Release |
| `UIBackgroundModes` → `remote-notification` no `Info.plist` | **DONE** |
| Build iOS real | **PASS** — `flutter build ios --simulator --debug`, Xcode build em 48s, exit 0 |
| App rodando no Simulator | **PASS** — tela de login renderiza com a marca correta |
| Ícone no springboard | **PASS** — conferido visualmente ("FIFA Queue", sem alpha no 1024×1024) |
| `flutter analyze` | **PASS** — `No issues found` (exigiu excluir `build/**`, ver correções) |
| Build phase de upload de dSYM do Crashlytics | **DONE** — hoje é a phase oficial do `flutterfire configure`; ver `ios_warnings_audit.md` |

## Correções à auditoria do Windows

1. **CocoaPods não é mais usado.** O `Podfile` nunca vai aparecer, e isso
   não é um gap: o Flutter 3.44 integra os plugins iOS por **Swift
   Package Manager**. O `Runner.xcodeproj` já vem com a integração SPM, e
   `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`
   resolve os 9 plugins (incluindo os 3 do Firebase). Os passos 3, 6 e 7
   do checklist antigo (`sudo gem install cocoapods`, `cd ios`,
   `pod install`) estão **obsoletos** — não execute.
2. **`GoogleService-Info.plist` NÃO existe neste checkout.** A auditoria
   antiga marcou como "READY (arquivo existe)"; isso era verdade só na
   máquina Windows de origem. Aqui não há nem ele, nem
   `android/app/google-services.json`, nem `lib/firebase_options.dart` —
   os três são gitignored e precisam ser gerados (ver pendências).
3. **`IPHONEOS_DEPLOYMENT_TARGET = 13.0` era um bloqueio de build.**
   `firebase_core 4.14`, `firebase_messaging 16.6` e
   `firebase_crashlytics 5.3` declaram `.iOS("15.0")` no `Package.swift`.
   Com 13.0 o SPM recusa o grafo. Subido para **15.0** nas três configs.
   Efeito de produto: o app deixa de suportar iOS 13 e 14.
4. **`flutter analyze` quebrava depois do primeiro build iOS.** Os
   checkouts do SPM caem em `build/ios/SourcePackages/` e trazem os
   testes `.dart` dos próprios plugins — 116 erros de código de
   terceiro. `build/**` foi adicionado ao `exclude` do
   `analysis_options.yaml`. Isso também consertaria o step
   `flutter analyze` do Codemagic assim que ele passar a buildar iOS.

## Pendências — só você pode resolver (conta/credencial)

| # | Pendência | Como resolver |
| --- | --- | --- |
| 1 | `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist` e `android/app/google-services.json` ausentes | `dart pub global activate flutterfire_cli` + `npm i -g firebase-tools` + `firebase login` + `flutterfire configure --project=fifa-queue`. O app iOS já está registrado no projeto Firebase (`1:927848400584:ios:c43993856e4893bef187fd`, ver `firebase.json`) |
| 2 | `env/production.json` ausente (só existe o `.example.json`) | Copiar do exemplo e preencher `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `APP_LINK_HOST=lucksrei.com`, `FIREBASE_ENABLED=true` |
| 3 | Conta Apple Developer + Team no target Runner | Xcode → Runner → Signing & Capabilities → Team (deixar "Automatically manage signing" ligado na primeira vez) |
| 4 | Chave de APNs no Firebase | Apple Developer → Keys → criar chave APNs (.p8) → subir em Firebase Console → Project Settings → Cloud Messaging → iOS app |
| 5 | `apple-app-site-association` em `lucksrei.com` | Conteúdo pronto em `docs/deep_links.md`. Sem isso o Universal Link não abre o app (mas **não** quebra build nem submissão) |
| 6 | Teste em iPhone físico | Push real (APNs) não funciona no Simulator |

## Checklist operacional atualizado (nesta ordem)

1. Resolver as pendências 1 e 2 acima (Firebase + `env/production.json`).
2. Abrir **`ios/Runner.xcworkspace`** no Xcode — nunca o `.xcodeproj`.
3. Runner → Signing & Capabilities → selecionar o **Team**.
   O `Runner.entitlements` já está ligado, então o Xcode vai mostrar
   **Push Notifications**, **Background Modes → Remote notifications** e
   **Associated Domains** já preenchidos — com signing automático ele
   habilita essas capabilities no App ID sozinho. Não precisa clicar em
   "+ Capability".
4. Confirmar `Bundle Identifier` = `com.lucasdiogof.fifaqueue` e que o
   `BUNDLE_ID` dentro do `GoogleService-Info.plist` bate com ele.
5. Rodar no Simulator primeiro:
   ```bash
   fvm flutter run --dart-define-from-file=env/production.json
   ```
6. Rodar num iPhone físico e validar o push de ponta a ponta.
7. Build de release:
   ```bash
   fvm flutter build ipa --release --dart-define-from-file=env/production.json
   ```
   (`build ipa` já gera o archive; `build ios` + Product → Archive no
   Xcode também serve.)
8. Xcode → Organizer → **Validate App** → **Distribute App → App Store
   Connect**.
9. App Store Connect: grupo interno de TestFlight, convidar testadores.

## Crashlytics — upload de dSYM

**Substituído.** A phase manual que existia aqui (*Firebase Crashlytics
dSYM Upload*) foi **removida** em 2026-09-10: o `flutterfire configure`
criou a phase oficial *FlutterFire: "flutterfire upload-crashlytics-symbols"*,
que faz o mesmo de forma mais robusta, e manter as duas subia o mesmo
dSYM duas vezes.

Detalhes, guardas e o porquê de a phase rodar em toda build estão em
[`ios_warnings_audit.md`](ios_warnings_audit.md), seção 4.

## Pinos do Swift Package Manager

Os dois `Package.resolved`
(`ios/Runner.xcworkspace/xcshareddata/swiftpm/` e
`ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`)
apareceram como arquivos novos nesta sessão. Eles fazem o papel que o
`Podfile.lock` faria — fixam a versão exata do SDK nativo do Firebase.
**Devem ser commitados**, senão cada máquina/CI resolve uma versão
diferente do Firebase iOS SDK.

## Detalhe sobre `aps-environment`

O `Runner.entitlements` está com `aps-environment = development`, que é
o que o Xcode gera ao habilitar a capability. No archive de distribuição
o valor efetivo vem do provisioning profile da App Store (`production`) —
não precisa editar o arquivo. Se algum dia o push funcionar em debug mas
não em TestFlight, é aqui que se olha primeiro.

## Status

**iOS BUILDA E RODA.** O bloqueio de ENVIRONMENT (falta de macOS) está
resolvido e os gaps de configuração nativa (entitlements, background
modes, deployment target) foram fechados e versionados. O que resta é
**exclusivamente credencial/conta** — Firebase, Supabase, Apple
Developer — nada de código.
