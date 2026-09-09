# Checklist de release — Android

Auditoria estática + tentativa real de build (`flutter build apk --release`
e `flutter build appbundle --release`) em 2026-09-09. Nenhuma credencial foi
inventada — o que falta fica documentado como template, sem valor real.

## 1. Assinatura de release

`android/key.properties` **não existe** (correto: nunca é versionado, ver
`.gitignore`). Sem ele, `android/app/build.gradle.kts` lança exceção de
propósito em qualquer build de release (`gradle.taskGraph.whenReady`) —
não deixa sair um artefato assinado com a chave de debug em silêncio.

Template já versionado, sem valores reais (`android/key.properties.example`,
confirmado tracked no git, com `CHANGE_ME` nos campos de senha):

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=fifaqueue
storeFile=/absolute/path/to/fifaqueue-release.jks
```

Passo a passo completo (geração do keystore, `keytool`, validação de
SHA-1/SHA-256, onde colocar o arquivo) documentado em
`docs/android_signing.md` — não duplicado aqui.

| Item | Status |
| --- | --- |
| `android/key.properties.example` (template) | **READY** — já existe no repo, versionado, sem credencial real |
| `key.properties` (arquivo real) | **MISSING** — precisa ser gerado numa máquina de confiança, nunca commitado |
| Keystore (`.jks`/`.keystore`) | **MISSING** — mesmo motivo |
| `storePassword` / `keyPassword` / `keyAlias` / `storeFile` | **NEEDS USER INPUT** — dependem do keystore gerado |
| `signingConfigs["release"]` no Gradle | **READY** — já lê de `key.properties` quando existir, sem mudança de código necessária |

## 2. Identificação e versão

| Item | Valor atual | Status |
| --- | --- | --- |
| `applicationId` | `com.lucasdiogof.fifaqueue` | READY |
| `versionName` / `versionCode` | `0.1.0+1` (via `pubspec.yaml` → `flutter.versionName`/`versionCode`) | READY para uma primeira submissão; versionCode precisa subir a cada release seguinte |
| `namespace` | `com.lucasdiogof.fifaqueue` | READY |

## 3. SDK e compatibilidade

| Item | Valor | Status |
| --- | --- | --- |
| `minSdk` | `flutter.minSdkVersion` (herdado do Flutter SDK, hoje 21+ conforme a versão instalada) | READY |
| `targetSdk` / `compileSdk` | `flutter.targetSdkVersion` / `flutter.compileSdkVersion` | READY |
| `ndkVersion` | `flutter.ndkVersion` | READY |
| Java/Kotlin | `sourceCompatibility`/`targetCompatibility` = 17 | READY |
| Core library desugaring | Habilitado (`isCoreLibraryDesugaringEnabled = true`) — necessário pra `flutter_local_notifications` usar `java.time` em SDKs baixos | READY |

## 4. ProGuard / R8

Nenhum `proguard-rules.pro` existe; `isMinifyEnabled`/`isShrinkResources`
não estão definidos no bloco `release` (default `false` do template
Flutter). **Não é bloqueio** — minificação é otimização opcional, não
exigida pelas lojas. Se ativada no futuro, testar bem (Firebase/Supabase
costumam precisar de regras de keep específicas).

| Item | Status |
| --- | --- |
| ProGuard/R8 | **MISSING (opcional)** — não configurado, não bloqueia release |

## 5. Firebase / notificações

| Item | Status |
| --- | --- |
| `android/app/google-services.json` | **READY** — presente no disco, gitignored corretamente |
| `POST_NOTIFICATIONS` | **READY** — contribuída automaticamente pelo `AndroidManifest.xml` do pacote `firebase_messaging` 16.6.0 (confirmado lendo o manifest do plugin no pub cache); não precisa ser declarada de novo no manifest do app |
| Prompt de permissão em runtime (Android 13+) | **READY** — `FirebaseMessaging.instance.requestPermission()` já é chamado no fluxo de ativação de notificações |
| Canal de notificação (`queue_alerts`, `app_updates`) | **READY** — criados antes do primeiro push, ver `firebase_bootstrap.dart` |

## 6. Deep links / App Links

| Item | Status |
| --- | --- |
| Custom scheme (`com.lucasdiogof.fifaqueue://auth-callback`) | READY — funciona ponta a ponta hoje (recuperação de senha) |
| App Links (`https://<domínio>/join/...`) | **MISSING — NEEDS USER INPUT** (domínio ainda não decidido, pendência de produto desde a Etapa 1, não desta etapa). Passo a passo já documentado em `docs/deep_links.md`. |
| SHA-256 do certificado de assinatura (necessário só quando os App Links forem configurados, pra publicar `assetlinks.json`) | **NEEDS USER INPUT** — depende do keystore de release existir primeiro |

## 7. Ícones e splash

| Item | Status |
| --- | --- |
| Ícone adaptativo (`mipmap-anydpi-v26/launcher_icon.xml` + foreground/background) | **READY** — presente e referenciado corretamente no manifest (`android:icon="@mipmap/launcher_icon"`) |
| Ícones legados (`mipmap-*dpi/launcher_icon.png`) | READY |
| Splash (`launch_background.xml`, variantes light/dark, Android 12+) | READY — inclui variantes `drawable-night*` e `android12splash.png` |

## 8. Resultado da tentativa real de build (2026-09-09)

```
$ flutter build apk --release --dart-define-from-file=env/development.json
FAILURE: Build failed with an exception.
* What went wrong:
java.io.IOException: Unable to establish loopback connection
Gradle task assembleRelease failed with exit code 1

$ flutter build appbundle --release --dart-define-from-file=env/development.json
FAILURE: Build failed with an exception.
* What went wrong:
java.io.IOException: Unable to establish loopback connection
Gradle task bundleRelease failed with exit code 1
```

**Classificação: ENVIRONMENT.** O erro ocorre no início da execução do
Gradle (antes até da própria checagem de `key.properties` do projeto
rodar) — é o daemon do Gradle falhando ao abrir uma conexão loopback TCP
nesta máquina Windows, não um problema de configuração do projeto nem de
código Dart/Flutter. `flutter build web --release` (que não usa Gradle)
compila sem problema no mesmo ambiente, o que corrobora que o gargalo é
específico do Gradle nesta máquina.

## 9. Veredito Android

**NOT READY FOR STORE SUBMISSION — bloqueios de CONFIG (keystore ausente)
e de ENVIRONMENT (Gradle não builda nesta máquina).** Zero bloqueio de
código. Quando o keystore existir E o build rodar numa máquina/CI onde o
Gradle funcione, o caminho já está pronto — nenhuma mudança de código é
esperada.
