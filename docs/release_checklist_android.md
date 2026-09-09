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

Três perguntas distintas, três respostas distintas — não misturar:

**READY TO CREATE RELEASE KEY: SIM.** Zero bloqueio de código. O
`signingConfig` de release já existe, a guarda contra assinatura
silenciosa com a chave de debug já existe (`gradle.taskGraph.whenReady`),
`android/key.properties.example` já existe sem credencial real, e
`key.properties`/`*.jks`/`*.keystore` já estão gitignored (raiz e
`android/`). Gerar o keystore com `keytool` e preencher `key.properties`
com senha real é uma dependência **operacional** do usuário (só ele deve
escolher/digitar as senhas) — não é um blocker de readiness do projeto.

**Atualização 2026-09-09 — keystore real gerado, `env/production.json`
criado, AAB de release produzido com sucesso.** O dono do produto gerou
o keystore, preencheu `android/key.properties` e `env/production.json`,
e rodou `flutter build appbundle --release` no próprio terminal (fora
desta ferramenta de execução). Achado real no meio do caminho: o
`storeFile` ficou com o valor placeholder do template
(`/absolute/path/to/fifaqueue-release.jks`) — corrigido pro caminho
real (`C:/Users/Computador/fifaqueue-release.jks`, barras normais;
Java properties trata `\` como escape, então caminho absoluto do
Windows precisa ir com `/` ou `\\`). Depois da correção, o build passou
de `validateSigningRelease` e gerou
`build/app/outputs/bundle/release/app-release.aab` (~65 MB, confirmado
no disco) — **assinado com a release key de verdade**, não a de debug
(o próprio `validateSigningRelease` só passa validando o keystore
informado).

`env/production.json` real já existe com `FIREBASE_ENABLED: true`
(corrigido em relação ao `.example.json`, que traz `false` — push real
depende disso, ver auditoria de `env/production.json` desta sessão) e
`APP_LINK_HOST: "lucksrei.com"` — **domínio decidido**, o que desbloqueia
(quando alguém for implementar) o Privacy Policy URL público e os
App/Universal Links, pendentes desde a Etapa 1. Nenhuma dessas duas
integrações foi implementada nesta sessão (fora de escopo, não pedido)
— só o valor da variável de ambiente já existe pronto pra quando forem.

**READY TO BUILD RELEASE NESTA MÁQUINA (terminal do usuário): SIM,
confirmado.** Achado importante: o bloqueio `Unable to establish
loopback connection` reconfirmado nas Etapas 19/20 e nesta sessão **é
específico do processo que invoca o Gradle, não do Windows como um
todo** — no terminal do próprio usuário o Gradle sobe e builda
normalmente; quando esta ferramenta de execução (sandboxed) tenta o
mesmo comando, o erro de loopback ainda aparece. Ou seja: a máquina
funciona, o ambiente sandboxed desta sessão de automação é que não.

**READY FOR STORE SUBMISSION: AINDA NÃO**, mas o maior bloqueio caiu.
Falta: `env/production.json` real (o build de sucesso usou
`--dart-define-from-file` com um dos arquivos existentes — confirmar
que é o de produção antes de qualquer upload real), Device QA num
aparelho físico com este AAB, e o setup de metadata da Play Console
(`docs/release_checklist_store_metadata.md`, ~35% pronto).
