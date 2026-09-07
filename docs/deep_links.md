# Deep links — `/join/:inviteCode`

O convite por link é uma feature central do FIFA Queue. A rota já existe e o
fluxo de "convite pendente" já é persistido; o que falta é apenas a
infraestrutura de domínio/hosting, que depende de um domínio definido.

## Estado atual (Etapa 1)

| Item | Situação |
| --- | --- |
| Rota `/join/:inviteCode` | Implementada (`AppRoutes.joinTeam`) |
| Acesso sem autenticação | Permitido pelo `redirect` do go_router |
| Persistência do convite pendente | `LocalPendingInviteRepository` (TTL de 24h) |
| Retomada após login | `PendingInviteListener` no `builder` do `MaterialApp.router` |
| URLs sem `#` no Web | `usePathUrlStrategy()` via import condicional |
| Android App Links | **Pendente** — depende do domínio |
| iOS Universal Links | **Pendente** — depende do domínio |

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

## O que configurar quando o domínio existir

Defina `APP_LINK_HOST` no arquivo de environment correspondente e siga os
passos abaixo.

### Web

O `usePathUrlStrategy()` já está ativo, então `https://<host>/join/X7K2P9`
cai direto na rota. O servidor precisa de um *fallback* para `index.html`
em qualquer path (SPA rewrite).

### Android (App Links)

1. Publicar `https://<host>/.well-known/assetlinks.json` com o SHA-256 do
   certificado de assinatura e o `applicationId` `com.fifaqueue.app`.
2. Adicionar em `android/app/src/main/AndroidManifest.xml`, dentro da
   `<activity>` principal:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="<host>" android:pathPrefix="/join" />
</intent-filter>
```

### iOS (Universal Links)

1. Publicar `https://<host>/.well-known/apple-app-site-association` (sem
   extensão, servido como `application/json`) com o App ID
   `<TEAM_ID>.com.fifaqueue.app` e o path `/join/*`.
2. Habilitar o capability *Associated Domains* no target Runner e adicionar
   `applinks:<host>`.

Nada disso foi adicionado ainda porque o domínio ainda não foi decidido e
arquivos de configuração apontando para um host inexistente só criariam
ruído.
