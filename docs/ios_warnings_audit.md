# Auditoria dos warnings do iOS

Feita em 2026-09-10 num Mac real: Xcode 26.5, Flutter 3.44.1 (FVM),
iPhone físico (iOS 26.6.2), Firebase real, plugins iOS via Swift Package
Manager. Nada aqui foi classificado por suposição: cada item abaixo foi
rastreado até a linha de código ou o binário que emite a mensagem.

## Método

Três caminhos de build diferentes foram executados e comparados, porque
cada um expõe um conjunto distinto de diagnóstico:

| Caminho | Produtos em | Resultado |
| --- | --- | --- |
| `xcodebuild` direto (`-derivedDataPath build/ios`) | `build/ios/Build/Products/…` | **falha** na phase do Crashlytics (Debug e Release); antes de falhar, emite 1 warning — o do "runs during every build" |
| `flutter build ios` (debug e release) | `build/ios/iphoneos/` | sucesso |
| `flutter run` no iPhone físico | `build/ios/Debug-iphoneos/` | sucesso |

A falha do primeiro caminho não é um problema deste projeto — é o que a
seção 4 explica, e foi justamente ela que revelou a fragilidade.

## 1. `[FirebaseCore][I-COR000005] No app has been configured yet.`

**Origem exata.** `FirebaseCore/Sources/FIRApp.m:257` — `+[FIRApp allApps]`
loga isso sempre que é chamado antes de existir app configurado. Quem
chama é o próprio plugin, em
`firebase_core-4.14.0/Sources/firebase_core/FLTFirebaseCorePlugin.swift:44`:

```swift
if FirebaseOptions.defaultOptions() != nil,
   FirebaseApp.allApps?["__FIRAPP_DEFAULT"] == nil
{
  FirebaseApp.configure()
}
```

Ou seja: **a mensagem é efeito colateral da própria checagem que decide
se precisa configurar**. O plugin pergunta "já existe app default?",
`allApps` responde "não" e loga, e aí o plugin configura a partir do
`GoogleService-Info.plist`.

**Quando acontece.** Esse bloco roda no inicializador estático de
`FLTFirebaseCorePlugin`, acionado por `registerWithRegistrar:`
(`GeneratedPluginRegistrant.m:61`), que o `AppDelegate` chama em
`didInitializeImplicitFlutterEngine`. Tudo isso é **nativo, antes do
`main()` do Dart existir** — nenhuma mudança em `bootstrap.dart` teria
qualquer efeito sobre esse log.

**Ordem no lado Dart, auditada e correta:**

`main.dart` → `bootstrap()` → SharedPreferences → Supabase →
`FirebaseBootstrap.initialize()` (que `await`-a `Firebase.initializeApp`)
→ `registerDependencies(firebaseAvailability: …)` → cubits → `runApp`.

- `FirebaseMessaging.instance` só é tocado em
  `notifications_module.dart:69`, dentro de uma factory preguiçosa que só
  é escolhida quando `availability == FirebaseAvailability.ready` — isto
  é, depois de `Firebase.initializeApp` ter retornado.
- `FirebaseCrashlytics.instance` só é tocado em `_wireCrashlytics()`,
  chamado depois do `await Firebase.initializeApp` na mesma função.

**Configuração duplicada?** Não. O nativo configura pelo plist e o Dart
chama `Firebase.initializeApp` com `DefaultFirebaseOptions.currentPlatform`;
os dois conjuntos de valores foram comparados campo a campo
(`API_KEY`, `GOOGLE_APP_ID`, `GCM_SENDER_ID`, `PROJECT_ID`,
`STORAGE_BUCKET`, `BUNDLE_ID`) e **batem exatamente**. Sem divergência não
há `[core/duplicate-app]`.

**Veredito: NORMAL / IGNORAR.** Nada foi alterado.

## 2. `FIRMessaging Remote Notifications proxy enabled`

Emitido por `FirebaseMessaging/Sources/FIRMessaging.m:261`. É o
comportamento **padrão e recomendado** do FlutterFire no iOS.

Auditado no projeto: o `AppDelegate.swift` é o template do Flutter puro —
não implementa `didRegisterForRemoteNotificationsWithDeviceToken`, não
define `UNUserNotificationCenter.current().delegate`, não chama
`FirebaseApp.configure()`. Quem faz esse trabalho é o
`FLTFirebaseMessagingPlugin`, que se declara
`UNUserNotificationCenterDelegate` e preserva o delegate anterior
(`FLTFirebaseMessagingPlugin.m:278-320`).

Logo, **desligar o swizzling (`FirebaseAppDelegateProxyEnabled = NO`)
quebraria o push**: não existe encaminhamento manual no projeto para
substituí-lo.

**Veredito: NORMAL / IGNORAR.** Não foi adicionada a chave, não houve
migração para integração manual.

## 3. `DEBUG_INFORMATION_FORMAT should be set to dwarf-with-dsym`

**Era real.** Estado anterior (nível de projeto):

| Config | Antes | Agora (nível do target Runner) |
| --- | --- | --- |
| Debug | `dwarf` | `dwarf-with-dsym` |
| Profile | `dwarf-with-dsym` | `dwarf-with-dsym` |
| Release | `dwarf-with-dsym` | `dwarf-with-dsym` |

**CORRIGIDO.** A chave foi posta nas 3 configurações **do target
Runner**, não no nível do projeto — assim o `RunnerTests` não é afetado.
`GCC_GENERATE_DEBUGGING_SYMBOLS` fica no default (`YES`), não precisou
mexer.

*Custo consciente:* gerar dSYM em Debug deixa o build incremental um
pouco mais lento. Foi feito porque foi pedido explicitamente; reverter é
só remover a linha das configs Debug.

## 4. Build phase do Crashlytics

**Bug real encontrado: havia DUAS phases de upload de dSYM.**

1. `Firebase Crashlytics dSYM Upload` — criada por mim numa sessão
   anterior, quando o Firebase ainda não estava configurado e o projeto
   não tinha nenhuma phase de upload.
2. `FlutterFire: "flutterfire upload-crashlytics-symbols"` — criada
   depois pelo `flutterfire configure`.

As duas apontavam para o mesmo script do Crashlytics. **A minha foi
removida**: a do FlutterFire é estritamente melhor (cobre CocoaPods, SPM
e DerivedData, e passa pelo CLI que resolve o `appId` a partir do
`firebase.json`). CORRIGIDO.

**Posição:** a phase do FlutterFire é a **última** do target, depois do
`Thin Binary` — que é onde precisa estar, porque só aí o dSYM já existe.

**Guardas (as que restaram, todas do FlutterFire/CLI), verificadas no
fonte do `flutterfire_cli 1.4.1`:**

- não roda fora do macOS (`if (!Platform.isMacOS) return;`);
- só roda se `firebase.json` tiver
  `flutter.platforms.ios.default.uploadDebugSymbols: true` — está `true`;
- **não** depende do `GoogleService-Info.plist`: o `appId`/`projectId`
  vêm do `firebase.json` e são gravados em
  `.dart_tool/flutterfire/platforms/ios/default/fifa-queue/app_id_file.json`.

**Sobre "pular Debug":** ela **não pula**. O CLI olha se existe
`App.framework.dSYM` no diretório de produtos; se existe trata como
`Release`, se não existe trata como `Debug` e ainda assim chama o script
do Crashlytics (que, em Debug, faz upload em background). É o
comportamento oficial do FlutterFire e não foi alterado — a phase manual
que pulava Debug era a minha, removida. Se o tempo de build em Debug
incomodar, o botão é `uploadDebugSymbols: false` no `firebase.json`, não
editar a phase.

**Onde ela NÃO é tolerante — e isso foi reproduzido:** se o checkout do
`firebase-ios-sdk` não estiver onde ela procura, ela **derruba o build**:

```
Exception: Could not find the Crashlytics upload symbols script at
"…/build/ios/Build/Products/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run".
** BUILD FAILED **
```

Isso acontece porque o script procura em `$BUILD_DIR/SourcePackages/…`.
Quando quem constrói é o **Flutter**, `BUILD_DIR` é `<projeto>/build/ios`
e o caminho bate. Quando é o **Xcode.app**, `BUILD_ROOT` contém
`DerivedData/` e o fallback do script resolve. O caso que quebra é um
terceiro: `xcodebuild -derivedDataPath <caminho sem "DerivedData">`, em
que nem o caminho principal nem o fallback acertam.

Nenhum dos dois fluxos reais deste projeto (`flutter build ipa` e
Product → Archive no Xcode) cai nesse caso — mas é uma mina para quem
for escrever uma lane iOS no Codemagic com `xcodebuild` direto. Ver
"Precisa follow-up".

Deliberadamente **não** foi adicionada guarda para tornar a falta do
checkout não-fatal: isso trocaria um build quebrado e visível por um
release publicado sem símbolos, em silêncio.

**Sobre "roda em toda build":** é **intencional**. O caminho do dSYM
depende do conteúdo do build, então declarar um output faria o Xcode
**pular** a phase quando o arquivo já existisse — quebrando o upload em
builds seguintes. Não foi inventado output.

O que foi feito, e é a outra remediação que o próprio Xcode sugere na
mensagem: `alwaysOutOfDate = 1` na phase, equivalente a desmarcar
*"Based on dependency analysis"*. **Não muda o comportamento** (já
rodava toda build) e declara a intenção explicitamente. CORRIGIDO.

> Atenção de manutenção: rodar `flutterfire configure` de novo regenera
> essa phase e pode remover o `alwaysOutOfDate`. Se o warning voltar, é
> só isso.

## 5. `... is located outside of the allowed root paths`

**A mensagem não é "Static file" — é "Stale file".** Isso muda o
diagnóstico inteiro.

**Origem exata:** o binário `llbuild`
(`Xcode.app/Contents/SharedFrameworks/llbuild.framework/Versions/A/llbuild`).
A string completa é `Stale file '<path>' is located outside of the
allowed root paths.` e faz parte da rotina de **remoção de arquivos
obsoletos** do motor de build. A string não existe em nenhum outro lugar
do Xcode 26.5 (verificado com busca em ASCII e UTF-16 no bundle inteiro).

**Mecanismo, verificado por reprodução:** num build com
`-derivedDataPath build/ios` e produtos em
`build/ios/Build/Products/Debug-iphoneos/`, o llbuild **apagou** os
mesmos arquivos do Firebase sem reclamar:

```
note: Removed stale file '…/Build/Products/Debug-iphoneos/FirebaseRemoteConfigInterop.o'
note: Removed stale file '…/Build/Products/Debug-iphoneos/FirebaseMessaging.o'
note: Removed stale file '…/Build/Products/Debug-iphoneos/FirebaseCrashlytics.o'
```

Ou seja: a limpeza funciona quando os produtos estão **dentro** da raiz
que o llbuild tem permissão de mexer. O warning aparece quando estão
fora dela.

E é exatamente o que acontece com `flutter run` no iPhone físico: em
dispositivos CoreDevice (iOS 17+) o Xcode **lança** o app mas não o
constrói, então o Flutter escreve
`CONFIGURATION_BUILD_DIR=<projeto>/build/ios/Debug-iphoneos` no
`ios/Flutter/Generated.xcconfig`
(`flutter_tools/lib/src/ios/xcode_build_settings.dart:204-208`). Esse
diretório fica fora das raízes de DerivedData que o llbuild pode podar —
então, no build seguinte, em vez de apagar os artefatos obsoletos do
Firebase, ele avisa, um por arquivo.

Por que só os do Firebase: são dezenas de produtos SPM separados
(`Firebase*.o`, `Firebase_*.bundle`) e o conjunto muda entre formatos de
build, então são justamente eles que ficam obsoletos.

**O que NÃO é a causa** (as três hipóteses do enunciado, descartadas):

- **SSD externo**: o caminho é relativo ao projeto. Mover para o disco
  interno reproduziria igual. **Não mova o projeto.**
- **User Script Sandboxing**: já está `NO`, e a mensagem nem vem do
  sandbox — vem do coletor de arquivos obsoletos.
- **Input paths da phase do Crashlytics**: a phase que tinha `inputPaths`
  era a minha, que já foi removida; a do FlutterFire não declara
  nenhum. O warning é anterior e independente das phases.

**Impacto: nenhum.** O llbuild simplesmente deixa de coletar lixo dentro
de `build/`, que é descartável e gitignored. Não afeta binário, assinatura
nem archive.

**Veredito: NORMAL / IGNORAR.** Se o volume de mensagens incomodar, o
remédio correto é `flutter clean` (ou `rm -rf build/ios`) — nunca mexer
em configuração de segurança do Xcode.

## 6 e 7. Logs de runtime

Nenhuma dessas strings existe no nosso código, nos plugins Flutter do
projeto, no SDK do Firebase nem no engine do Flutter (verificado por
busca direta nos fontes e no binário do engine). Todas vêm de frameworks
do próprio iOS.

| Log | Origem | Impacto | Ação |
| --- | --- | --- | --- |
| `FlutterView implements focusItemsInRect…` | UIKit reclamando da view do engine do Flutter | Nenhum — só desabilita um cache de foco linear | Nenhuma (é do engine, não nosso) |
| `fopen failed for data file: errno = 2` | Framework do iOS tentando abrir um cache que ainda não existe; **não** está no engine do Flutter (confirmado no binário) nem no nosso código | Nenhum — o arquivo é recriado | Nenhuma |
| `nw_protocol_instance_set_output_handler…` | Network.framework, ruído de URLSession (Supabase/Firebase) | Nenhum | Nenhuma |
| `variant selector cell index number could not be found` | CoreText, seleção de glifo/emoji | Nenhum | Nenhuma |
| `usermanagerd.xpc invalidated` | Daemon do sistema encerrando conexão XPC | Nenhum | Nenhuma |
| `RBSServiceErrorDomain Client not entitled` | RunningBoard: o app pede info de assertion que não tem entitlement para ler; universal em build de debug | Nenhum | Nenhuma |
| `elapsedCPUTimeForFrontBoard…` | Mesma família (RunningBoard/FrontBoard) | Nenhum | Nenhuma |
| `RTIInputSystemClient valid sessionID` | Sistema remoto de entrada de texto (teclado) | Nenhum | Nenhuma |
| `UIKeyboard snapshot warning` | UIKit tirando snapshot do teclado antes de renderizar | Nenhum | Nenhuma |

**Veredito: todos NORMAL / IGNORAR.** Nenhuma linha de código foi
alterada por causa deles.

## 8. "Update to recommended settings"

**Não aplicado, e não deve ser.** O item de maior peso que o Xcode
oferece nesse pacote é `ENABLE_USER_SCRIPT_SANDBOXING = YES`, que é
**incompatível com Flutter**. Duas evidências de primeira mão, do próprio
SDK do Flutter 3.44.1:

- o template iOS fixa `ENABLE_USER_SCRIPT_SANDBOXING = NO` nas três
  configurações
  (`flutter_tools/templates/xcode/ios/custom_application_bundle/Runner.xcodeproj.tmpl/project.pbxproj`);
- a ferramenta emite, textualmente: *"ENABLE_USER_SCRIPT_SANDBOXING is
  enabled. Flutter is unable to rebuild the Flutter app when sandboxing
  is enabled."*

Isso acontece porque o `xcode_backend` escreve em
`FLUTTER_APPLICATION_PATH/build`, fora do `SRCROOT` (`ios/`) — exatamente
o que o sandbox proíbe.

O resto do pacote (flags de warning do Clang, `LOCALIZATION_PREFERS_
STRING_CATALOGS`, bump do `LastUpgradeCheck`) é diff sem benefício
concreto para este projeto, e o `ALWAYS_SEARCH_USER_PATHS` que costuma
aparecer já está `NO`.

**Veredito: NORMAL / IGNORAR.** Deixar o aviso do Xcode em pé é mais
seguro do que aplicá-lo.

## Resumo

### CORRIGIDO

| Item | O que era |
| --- | --- |
| Phase duplicada de upload de dSYM | Duas phases subindo o mesmo símbolo; a minha, redundante, foi removida |
| `DEBUG_INFORMATION_FORMAT` em Debug | Era `dwarf`; agora `dwarf-with-dsym` nas 3 configs do target Runner |
| Warning "runs during every build" | `alwaysOutOfDate = 1` na phase do FlutterFire — declara a intenção sem inventar output |

### NORMAL / IGNORAR

`I-COR000005` · swizzling do FIRMessaging · "Stale file … allowed root
paths" · todos os logs de runtime do iOS · "Update to recommended
settings".

### PRECISA FOLLOW-UP

| Item | Por quê |
| --- | --- |
| Lane iOS no Codemagic | Se for usar `xcodebuild` direto (em vez de `flutter build ipa`), a phase do Crashlytics quebra o build — ver seção 4. Decidir por `flutter build ipa` na CI |
| Push real de ponta a ponta no iPhone físico | Fora do escopo desta auditoria de warnings; é o teste que ainda não foi feito |
| `apple-app-site-association` em `lucksrei.com` | Associated Domains está configurado no app, falta o lado do servidor (`docs/deep_links.md`) |
