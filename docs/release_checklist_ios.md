# Checklist de release — iOS

Auditoria 100% estática (lendo arquivos de projeto) feita no Windows —
**nenhum build real foi tentado nem poderia ser** (Xcode não existe nesta
plataforma). Nada aqui foi marcado como PASS sem execução real; tudo que
depende de rodar de fato fica como `NOT EXECUTED — REQUIRES macOS`.

## 1. Estado confirmado por leitura de arquivo

| Item | Valor / achado | Status |
| --- | --- | --- |
| Bundle identifier | `com.lucasdiogof.fifaqueue` (Runner e alvo de testes) | READY |
| `IPHONEOS_DEPLOYMENT_TARGET` | `13.0` | READY |
| `CFBundleShortVersionString` / `CFBundleVersion` | `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` — herdam de `pubspec.yaml` (`0.1.0+1`) | READY |
| `GoogleService-Info.plist` | Presente no disco, gitignored corretamente | READY (arquivo existe; **não verificado se é o real de produção ou um placeholder** — confirmar antes do archive) |
| URL scheme (`CFBundleURLSchemes`) | `com.lucasdiogof.fifaqueue` registrado — cobre a recuperação de senha | READY |
| Ícone (`AppIcon.appiconset`) | Não conferido nesta etapa (fora do escopo de arquivo de projeto simples de auditar sem Xcode); assets de ícone existem no repo | NEEDS macOS pra confirmar visualmente |
| Splash (`LaunchScreen.storyboard`) | Não conferido em detalhe — existe por padrão do template Flutter, sem customização visível auditada | NEEDS macOS pra confirmar visualmente |
| `Podfile` | **AUSENTE** — nunca foi gerado (precisa de `pod install`, que exige macOS/CocoaPods) | **MISSING — só é gerado na primeira vez que o projeto for aberto/buildado num Mac** |

## 2. Faltando — precisa ser feito no Xcode (Mac)

Nenhum destes existe hoje neste checkout, porque nunca houve uma sessão
num Mac para este projeto:

| Item | Status |
| --- | --- |
| `.entitlements` (Push Notifications, Background Modes) | **MISSING** |
| `UIBackgroundModes` (`remote-notification`) no `Info.plist` | **MISSING** |
| Capability *Push Notifications* habilitada no target Runner | **MISSING** |
| Provisioning profile / Team de desenvolvimento | **NEEDS USER INPUT** (conta Apple Developer) |
| Signing de distribuição (App Store Connect) | **NEEDS USER INPUT** |
| Associated Domains (Universal Links) | **MISSING** — mesma pendência de domínio do Android (não é gap desta etapa, é decisão de produto ainda não tomada) |
| `Podfile` + `pod install` | **MISSING** — primeiro passo obrigatório antes de qualquer build |

## 3. Checklist operacional para executar no Mac (nesta ordem)

1. Instalar Xcode + CocoaPods, abrir `ios/Runner.xcworkspace` (não o
   `.xcodeproj` isolado — plugins Flutter dependem do workspace).
2. `flutter pub get` e `cd ios && pod install` — isso gera o `Podfile`/
   `Podfile.lock` que faltam.
3. Selecionar um *Team* de desenvolvimento real no target Runner
   (Signing & Capabilities).
4. Adicionar a capability **Push Notifications** — isso cria o
   `.entitlements` automaticamente.
5. Adicionar **Background Modes → Remote notifications** (necessário
   pro FCM entregar em background).
6. Confirmar que `GoogleService-Info.plist` no projeto é o arquivo real
   de produção (não um placeholder de dev) e que o `BUNDLE_ID` dentro
   dele bate com `com.lucasdiogof.fifaqueue`.
7. Se/quando o domínio dos App/Universal Links existir: habilitar
   **Associated Domains**, adicionar `applinks:<domínio>`, publicar
   `apple-app-site-association` (passo a passo em `docs/deep_links.md`).
8. `flutter build ios --release` (ou Product → Archive no Xcode).
9. Validar o archive (Xcode Organizer → Validate App) antes de subir.
10. Upload pro App Store Connect, criar um grupo interno de TestFlight,
    convidar testadores.

## 4. Resultado desta etapa

**NOT EXECUTED — REQUIRES macOS.** Nenhum item da seção 3 pôde ser
executado neste ambiente Windows. A auditoria estática (seção 1) não
encontrou nenhuma inconsistência de configuração no que já existe — os
gaps da seção 2 são esperados (nunca houve build iOS antes), não
regressões.

## Veredito iOS

**NOT READY FOR STORE SUBMISSION — bloqueio de ENVIRONMENT (falta
macOS) e alguns itens de CONFIG que só podem ser criados dentro do
Xcode.** Zero bloqueio de código Dart/Flutter conhecido.
