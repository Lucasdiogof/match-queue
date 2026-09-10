# Checklist de release — iOS

> **Executado em 2026-09-10 num Mac real** (Xcode 26.5, Flutter 3.44.1
> via FVM, iPhone 17 Pro Simulator / iOS 26.5). Substitui a auditoria
> estática anterior, feita no Windows. O passo a passo detalhado, com as
> correções à auditoria antiga, está em `docs/ios_release_mac.md`.

## 1. Verificado por execução real

| Item | Valor / achado | Status |
| --- | --- | --- |
| Build iOS | `flutter build ios --simulator --debug` → exit 0, Xcode build 48s | **PASS** |
| App em execução | Sobe no Simulator, tela de login com a marca correta | **PASS** |
| `flutter analyze` | `No issues found` | **PASS** |
| `flutter test` | 17 testes, todos passando | **PASS** |
| Bundle identifier | `com.lucasdiogof.fifaqueue` (Runner e RunnerTests) | **PASS** |
| `IPHONEOS_DEPLOYMENT_TARGET` | **15.0** (era 13.0; subido porque o Firebase exige 15) | **PASS** |
| `CFBundleShortVersionString` / `CFBundleVersion` | `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` ← `pubspec.yaml` (`0.1.0+1`) | **PASS** |
| URL scheme | `com.lucasdiogof.fifaqueue` — cobre a recuperação de senha | **PASS** |
| Ícone (`AppIcon.appiconset`) | Conferido no springboard; 1024×1024 sem canal alpha | **PASS** |
| Plugins nativos | 9 plugins resolvidos via **Swift Package Manager** — sem CocoaPods, sem `Podfile` | **PASS** |
| `Runner.entitlements` | Criado e ligado (`CODE_SIGN_ENTITLEMENTS`) nas 3 configs do Runner | **PASS** |
| `UIBackgroundModes` (`remote-notification`) | Presente no `Info.plist` | **PASS** |
| Upload de dSYM do Crashlytics | Build phase criada (não existia); guardas testadas, upload a confirmar no 1º archive | **PASS (parcial)** |
| Associated Domains | `applinks:lucksrei.com` no entitlements | **PASS** (falta publicar o AASA no domínio) |

## 2. Faltando — bloqueios de conta/credencial

Nenhum bloqueio de código ou de configuração nativa continua aberto.
O que resta depende de credencial que só o dono do produto tem:

| Item | Status |
| --- | --- |
| `lib/firebase_options.dart` + `GoogleService-Info.plist` + `google-services.json` | **NEEDS FIREBASE LOGIN** (`flutterfire configure --project=fifa-queue`) |
| `env/production.json` (Supabase URL + publishable key) | **NEEDS USER INPUT** |
| Team / provisioning de distribuição | **NEEDS APPLE DEVELOPER ACCOUNT** |
| Chave APNs (.p8) enviada ao Firebase | **NEEDS APPLE DEVELOPER ACCOUNT** |
| `apple-app-site-association` em `lucksrei.com` | **NEEDS WEBSITE** (não bloqueia build nem submissão) |
| Teste de push em iPhone físico | **NEEDS PHYSICAL DEVICE** |

## 3. Ordem de execução até o TestFlight

Passo a passo completo em `docs/ios_release_mac.md`, seção "Checklist
operacional atualizado". Resumo:

1. `flutterfire configure --project=fifa-queue`
2. Preencher `env/production.json`
3. Xcode (`ios/Runner.xcworkspace`) → Runner → Signing & Capabilities →
   selecionar o Team (as capabilities já vêm do entitlements versionado)
4. `fvm flutter run --dart-define-from-file=env/production.json` no
   Simulator, depois num iPhone físico
5. `fvm flutter build ipa --release --dart-define-from-file=env/production.json`
6. Organizer → Validate App → Distribute App → App Store Connect
7. TestFlight: grupo interno, convidar testadores

## Veredito iOS

**BUILDA, RODA E ANALISA LIMPO.** Os bloqueios de ENVIRONMENT e de
CONFIG nativa da auditoria anterior estão fechados e versionados.
Submissão à App Store depende agora só de credenciais — Firebase,
Supabase e Apple Developer.
