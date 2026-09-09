# Assinatura de release Android

Antes desta etapa (Fase A), o `buildTypes.release` do app assinava com a
**chave de debug** — a Play Store rejeita isso, e qualquer APK gerado assim
nunca poderia ser publicado. Corrigido: `android/app/build.gradle.kts`
agora lê `android/key.properties` (nunca versionado — ver `.gitignore`) e
falha claramente numa build de release se esse arquivo não existir. Builds
de debug (`flutter run`, `flutter build apk --debug`) continuam
funcionando sem ele.

## 1. Gerar o keystore (uma vez, guardar para sempre)

```bash
keytool -genkey -v -keystore fifaqueue-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fifaqueue
```

Vai pedir uma senha do keystore e uma senha da chave (podem ser iguais) e
alguns dados de identificação (nome, organização, etc. — podem ser
simples, não aparecem para o usuário final).

**Guarde o arquivo `.jks` e as duas senhas em local seguro fora do
repositório** (gerenciador de senhas, cofre da organização). Perder esse
arquivo significa não conseguir mais publicar atualizações do mesmo app na
Play Store — não há como recuperar ou gerar de novo com o mesmo
"fingerprint".

## 2. Criar `android/key.properties`

Copie o exemplo e preencha com os valores reais:

```bash
cp android/key.properties.example android/key.properties
```

```properties
storePassword=<senha do keystore>
keyPassword=<senha da chave>
keyAlias=fifaqueue
storeFile=/caminho/absoluto/para/fifaqueue-release.jks
```

`storeFile` aceita caminho absoluto (recomendado, evita ambiguidade sobre
a partir de onde o Gradle resolve caminhos relativos).

Este arquivo **nunca deve ser commitado** — já está no `.gitignore` (assim
como `*.jks`/`*.keystore`/`*.p12`).

## 3. Validar o SHA-1/SHA-256 do certificado (opcional aqui, obrigatório antes de configurar App Links)

Só é necessário quando o Android App Links ou algum SDK que peça
fingerprint do certificado (ex. Google Sign-In, se um dia for adotado)
exigir. Não bloqueia gerar o AAB/APK:

```bash
keytool -list -v -keystore fifaqueue-release.jks -alias fifaqueue
```

Peça a senha do keystore quando solicitado. A saída mostra `SHA1:` e
`SHA256:` — é isso que vai num eventual `assetlinks.json` (ver
`docs/deep_links.md`) ou no painel do Firebase (Project Settings →
seu app Android → "Add fingerprint"), se o Firebase precisar dele pra
algum recurso (Dynamic Links, Google Sign-In — não usado hoje).

## 4. Rodar a build de release

Sempre com `--dart-define-from-file`, como qualquer outra build deste
projeto (sem isso o app builda mas fica sem `SUPABASE_URL`/chave e
falha em runtime, não é específico de release):

```bash
flutter build appbundle --release --dart-define-from-file=env/production.json
```

ou, para um APK direto (útil pra instalar num device de teste, a Play
Store pede AAB):

```bash
flutter build apk --release --dart-define-from-file=env/production.json
```

Sem `key.properties`, qualquer uma dessas duas falha imediatamente com uma
mensagem explicando o que falta — de propósito, para nunca sair um artefato
assinado com a chave de debug sem ninguém perceber.

`env/production.json` ainda não existe neste checkout (só o
`.example.json`) — copie e preencha com a URL/chave publicável do
projeto Supabase de produção antes de rodar o build real.

## Ambiente de CI/CD

Quando existir pipeline de CI (Fase B, não implementado ainda), o
`key.properties` (ou o `.jks` + as 3 senhas separadamente) precisa vir de
secrets do CI, nunca do repositório. Fora de escopo desta etapa.
