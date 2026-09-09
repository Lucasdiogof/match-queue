# iOS — continuar o release num Mac

Auditoria 100% estática, feita no Windows — nenhum build real foi
tentado nem poderia ser (Xcode não existe nesta plataforma). Este
documento existe pra o dono do produto (ou outra sessão, já num Mac)
seguir sem precisar reaudittar nada.

## Estado confirmado por leitura de arquivo (2026-09-09)

| Item | Valor / achado | Status |
| --- | --- | --- |
| Bundle identifier | `com.lucasdiogof.fifaqueue` (Runner e alvo de testes) | READY |
| `IPHONEOS_DEPLOYMENT_TARGET` | `13.0` | READY |
| `CFBundleShortVersionString`/`CFBundleVersion` | `$(FLUTTER_BUILD_NAME)`/`$(FLUTTER_BUILD_NUMBER)` — herdam do `pubspec.yaml` (`0.1.0+1`) | READY |
| `GoogleService-Info.plist` | Presente no disco, gitignored | READY (arquivo existe; **confirmar no Mac que é o real de produção**, não um placeholder) |
| URL scheme (`CFBundleURLSchemes`) | `com.lucasdiogof.fifaqueue` — cobre recuperação de senha | READY |
| `Runner.xcworkspace` | **Existe** (gerado pelo `flutter create`, não depende de CocoaPods) | READY |
| `ios/Podfile` | **AUSENTE** — nunca foi gerado (só é criado pela primeira execução de `pod install`, que exige macOS/CocoaPods) | **MISSING — normal, primeiro passo no Mac** |
| `.entitlements` (Push, Background Modes) | **AUSENTE** | **MISSING — criado pelo Xcode ao habilitar a capability** |
| `UIBackgroundModes` no `Info.plist` | **AUSENTE** | **MISSING — mesma causa** |
| Ícone (`AppIcon.appiconset`) | Gerado por `flutter_launcher_icons` (mesmo pipeline do Android) — não conferido visualmente | NEEDS macOS pra confirmar visualmente |
| Splash | Gerado por `flutter_native_splash` — mesma fonte do Android | NEEDS macOS pra confirmar visualmente |

**Sobre o `Podfile` ausente**: não é uma corrupção nem uma perda de
configuração — este projeto simplesmente nunca teve uma sessão de
desenvolvimento num Mac. `pod install` vai **gerar** o `Podfile` (não
sobrescrever um customizado, porque não existe nenhum ainda) — seguro
de rodar sem risco de perder personalização alguma.

## Checklist operacional (nesta ordem exata)

1. Instalar uma versão do Flutter compatível — mesma major/minor usada
   no Windows (`3.44.x`) pra evitar diferença de `minSdk`/comportamento
   entre plataformas. Confirmar com `flutter --version`.
2. Instalar Xcode (App Store) — versão compatível com
   `IPHONEOS_DEPLOYMENT_TARGET = 13.0` (qualquer Xcode recente serve).
3. Instalar CocoaPods (`sudo gem install cocoapods` ou via Homebrew).
4. `git clone` (ou `git pull` se o repo já existir no Mac) —
   confirmar que está em `origin/main` no HEAD desta etapa.
5. `flutter pub get` na raiz do projeto.
6. `cd ios`.
7. `pod install` — isso **gera** o `Podfile`/`Podfile.lock` que faltam
   hoje. Primeira vez pode demorar (baixa todos os pods do Firebase).
8. Abrir **`ios/Runner.xcworkspace`** no Xcode — nunca o
   `.xcodeproj` isolado (plugins Flutter dependem do workspace).
9. No target **Runner** → Signing & Capabilities: selecionar um
   **Team** de desenvolvimento Apple real (**NEEDS APPLE DEVELOPER
   ACCOUNT**).
10. Confirmar `Bundle Identifier` = `com.lucasdiogof.fifaqueue` (já
    está correto no projeto, só confirmar que não mudou ao abrir no
    Xcode).
11. Signing & Capabilities → deixar "Automatically manage signing"
    ligado numa primeira tentativa (mais simples) ou configurar
    provisioning manual se a conta exigir.
12. **+ Capability → Push Notifications** — isso cria o
    `.entitlements` automaticamente.
13. **+ Capability → Background Modes** → marcar **Remote
    notifications** (necessário pro FCM entregar em background).
14. **+ Capability → Associated Domains** → adicionar
    `applinks:lucksrei.com` (ver seção "App Links/Universal Links"
    abaixo — o domínio já está decidido).
15. Confirmar que `GoogleService-Info.plist` no projeto é o arquivo
    real de produção e que `BUNDLE_ID` dentro dele bate com
    `com.lucasdiogof.fifaqueue` (abrir o arquivo, checar o campo
    `BUNDLE_ID`).
16. Testar no Simulator primeiro (`flutter run` sem `--release`, mais
    rápido pra achar erro de configuração), depois num iPhone físico
    real conectado (**NEEDS PHYSICAL DEVICE** pra validação completa).
17. Quando o app abrir e funcionar:
    ```bash
    flutter build ios --release --dart-define-from-file=env/production.json
    ```
18. No Xcode: **Product → Archive**.
19. No Organizer, depois do archive: **Validate App** (contra a conta
    Apple Developer configurada).
20. **Distribute App → App Store Connect** (upload).
21. No App Store Connect: criar um grupo interno de **TestFlight**,
    convidar testadores, aguardar processamento do build.

## Blockers específicos deste checklist

| Blocker | Categoria |
| --- | --- |
| Precisa de um Mac com Xcode | ENVIRONMENT |
| Precisa de conta Apple Developer (paga, ~$99/ano) + Team configurado | APPLE DEVELOPER |
| Provisioning/signing de distribuição | APPLE DEVELOPER |
| Confirmar `GoogleService-Info.plist` real vs. placeholder | CONFIG (rápido de resolver no Mac) |
| Validação visual de ícone/splash | NEEDS macOS |
| Teste em device físico real | NEEDS PHYSICAL DEVICE |

## Status

**NOT EXECUTED — REQUIRES macOS.** Auditoria estática completa, zero
inconsistência encontrada no que já existe. Os gaps (Podfile,
entitlements, capabilities) são esperados — nunca houve sessão iOS
antes — não são regressão.
