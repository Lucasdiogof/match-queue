# Deep links — `/join/:inviteCode`

O convite por link é uma feature central do FIFA Queue. A rota já existe e o
fluxo de "convite pendente" já é persistido; o que falta é apenas a
infraestrutura de domínio/hosting, que depende de um domínio definido.

## Estado atual (atualizado 2026-09-09 — domínio decidido)

| Item | Situação |
| --- | --- |
| Rota `/join/:inviteCode` | Implementada (`AppRoutes.joinTeam`) |
| Acesso sem autenticação | Permitido pelo `redirect` do go_router |
| Persistência do convite pendente | `LocalPendingInviteRepository` (TTL de 24h) |
| Retomada após login | `PendingInviteListener` no `builder` do `MaterialApp.router` |
| URLs sem `#` no Web | `usePathUrlStrategy()` via import condicional |
| Callback de recuperação de senha | `com.lucasdiogof.fifaqueue://auth-callback` registrado no Android e no iOS |
| `APP_LINK_HOST` | **`lucksrei.com`** — já configurado em `env/production.json`. O código já usa esse valor (`InviteLinkBuilder`, `PublicProfileLinkBuilder`, `AuthRedirects`) sempre que presente; o que falta é só a configuração nativa (manifest/entitlements) e publicar os dois arquivos `.well-known/*` no domínio |
| Android App Links | **NEEDS WEBSITE + CONFIG NATIVA** — conteúdo pronto abaixo, nada publicado ainda |
| iOS Universal Links | **NEEDS WEBSITE + macOS** — conteúdo pronto abaixo, nada publicado ainda; capability configurada no Xcode (ver `docs/ios_release_mac.md`, passo 14) |

## Fluxo

```
abre /join/X7K2P9
        │
        ├── autenticado ──► JoinTeamPage ──► BottomSheet do convite
        │
        └── não autenticado
                 │
                 ├── PendingInviteCubit.capture(code)   (SharedPreferences)
                 ├── usuário vai para /login
                 ├── autenticação concluída
                 ├── PendingInviteListener detecta a transição
                 └── go('/join/X7K2P9') ──► BottomSheet do convite
```

## O que falta configurar, agora que `lucksrei.com` está decidido

`APP_LINK_HOST=lucksrei.com` já está em `env/production.json` — o
código Dart (`InviteLinkBuilder`, `PublicProfileLinkBuilder`,
`AuthRedirects`) já passa a gerar `https://lucksrei.com/join/...` e
`https://lucksrei.com/u/...` automaticamente em builds que usem esse
env file, **sem precisar de mudança de código**. O que falta é 100%
config nativa (manifest Android / capability iOS) e publicação no
domínio — nenhum dos dois foi feito, por instrução explícita de não
publicar nada sem autorização.

### Web

O `usePathUrlStrategy()` já está ativo, então `https://lucksrei.com/join/X7K2P9`
cai direto na rota. O servidor de `lucksrei.com` precisa de um
*fallback* para `index.html` em qualquer path (SPA rewrite) — depende
de onde o Web for hospedado (fora do escopo desta etapa).

### Android (App Links)

**Fingerprint real do keystore de release** (extraído de
`fifaqueue-release.jks`, seguro de publicar — não é segredo, é
justamente o que vai no `assetlinks.json`):

```
SHA256: 19:42:BA:9C:AA:7D:A8:A9:2E:E7:DA:25:21:6B:DE:AD:CF:13:B4:48:8B:55:FA:DC:75:4D:A5:B6:E5:AF:E1:3A
```

1. Publicar em `https://lucksrei.com/.well-known/assetlinks.json`
   (**NEEDS WEBSITE**, não publicado ainda):

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.lucasdiogof.fifaqueue",
    "sha256_cert_fingerprints": [
      "19:42:BA:9C:AA:7D:A8:A9:2E:E7:DA:25:21:6B:DE:AD:CF:13:B4:48:8B:55:FA:DC:75:4D:A5:B6:E5:AF:E1:3A"
    ]
  }
}]
```

2. Adicionar em `android/app/src/main/AndroidManifest.xml`, dentro da
   `<activity>` principal (**MISSING**, não adicionado ainda — mudança
   de código, fora do escopo desta auditoria):

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="lucksrei.com" android:pathPrefix="/join" />
    <data android:scheme="https" android:host="lucksrei.com" android:pathPrefix="/u" />
</intent-filter>
```

### iOS (Universal Links)

1. Publicar em `https://lucksrei.com/.well-known/apple-app-site-association`
   (sem extensão, servido como `application/json`, **NEEDS WEBSITE**,
   não publicado ainda):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "<TEAM_ID>.com.lucasdiogof.fifaqueue",
        "paths": ["/join/*", "/u/*"]
      }
    ]
  }
}
```

`<TEAM_ID>` só existe depois de configurar a conta Apple Developer no
Mac (ver `docs/ios_release_mac.md`, passo 9) — **NEEDS APPLE
DEVELOPER**.

2. Habilitar a capability *Associated Domains* no target Runner e
   adicionar `applinks:lucksrei.com` — passo 14 de
   `docs/ios_release_mac.md`, **NEEDS macOS**.

Nada foi publicado no domínio nem adicionado ao manifest/entitlements
nesta sessão — só documentado, por instrução explícita.


## Recuperação de senha

Esse é o único deep link que já funciona ponta a ponta hoje, porque não
depende de domínio: usa um scheme próprio derivado do bundle id.

`AuthRedirects.passwordReset` escolhe o destino:

| Plataforma | `redirectTo` |
| --- | --- |
| Web sem `APP_LINK_HOST` | `<origin>/reset-password` |
| Web com `APP_LINK_HOST` | `https://<host>/reset-password` |
| Android / iOS | `com.lucasdiogof.fifaqueue://auth-callback` |

O scheme está registrado em dois lugares:

- `android/app/src/main/AndroidManifest.xml` — `intent-filter` com
  `android:scheme="com.lucasdiogof.fifaqueue"` e `android:host="auth-callback"`.
- `ios/Runner/Info.plist` — `CFBundleURLTypes`.

No mobile quem processa a URL é o próprio `supabase_flutter` (via
`app_links`), não o go_router: ele troca o código pela sessão e emite
`AuthChangeEvent.passwordRecovery`. O `AuthCubit` transforma isso em
`AuthState.isPasswordRecovery` e o `redirect` do router força
`/reset-password`.

Na Web o caminho é duplo de propósito: o evento de recuperação leva à tela,
mas a própria URL de redirect já **é** `/reset-password`, então mesmo que o
evento não chegue o usuário cai na tela certa com a sessão válida.

Todos os redirects precisam estar na allowlist de *Authentication → URL
Configuration* do Supabase — ver [`supabase_setup.md`](supabase_setup.md).
