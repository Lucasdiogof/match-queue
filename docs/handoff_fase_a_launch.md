# Handoff — Fase A (bloqueadores de lançamento)

Status em 2026-09-08: **FECHADA.** Os 4 P0 reais de `docs/launch_gap_analysis.md`
(exclusão de conta, Privacy/Terms, assinatura de release, catálogo
vazando inativos) foram corrigidos e validados ao vivo contra o Supabase
de produção. O risco de marca ganhou um disclaimer (mitigação parcial —
a decisão de renomear continua pendente, é do dono do produto). Nada de
CI/CD, suíte de testes completa, analytics ou catálogo real foi tocado,
como pedido.

## 1. Auditoria inicial (antes de qualquer mudança)

Confirmado direto no código/schema remoto, não só nos handoffs:

- Exclusão de conta: **não existia** nenhuma RPC nem tela (`grep` vazio em
  `lib/` e `supabase/`).
- Privacy/Terms: **não existiam** — nenhuma rota, nenhum texto, em
  lugar nenhum do app.
- `android/app/build.gradle.kts`: `release` assinava com
  `signingConfigs.getByName("debug")`, comentário padrão do template
  Flutter ainda presente.
- `fc_players`/`fc_player_cards`: já tinham sido corrigidos na Etapa 17B
  (policy `using (is_active = true)`) — reconfirmado ao vivo via
  `pg_policies` antes de mexer em qualquer coisa: seguia correto, sem
  regressão.
- "EA SPORTS"/"Ultimate Team"/"FIFA": usados em `pubspec.yaml`
  (descrição), `android/.../AndroidManifest.xml` + `ios/Runner/Info.plist`
  + `web/manifest.json`/`index.html` (nome do app, "FIFA Queue"), e 2
  chaves de l10n (`fcAccountsPageSubtitle`,
  `fcAccountOnboardingMessage`) com "Ultimate Team". Nenhum disclaimer em
  lugar nenhum.

## Account Deletion

**Backend**: migration `20260927100000_account_deletion.sql` (aplicada).

- Três FKs que eram `RESTRICT` (e bloqueariam a exclusão pra sempre)
  viraram `SET NULL`: `game_matches.user_id`/`fc_account_id`,
  `match_search_sessions.user_id`/`fc_account_id`,
  `team_invite_links.created_by`. Motivo: são dado **histórico
  compartilhado com o time** (partidas, buscas passadas, metadado de
  convite) — apagar destruiria a visão dos outros membros; anonimizar
  preserva a integridade do time e remove o vínculo pessoal. Conferido
  antes de mudar: todo RPC de leitura que exibe esses nomes já usa
  `coalesce(display_name, '')`/subquery correlacionada — tolera null sem
  quebrar, nenhum RPC de leitura precisou mudar.
- `match_search_queue` (fila **ao vivo**, nunca histórico) não mudou de
  schema — a RPC `delete_my_account()` chama a `cancel_match_search()` já
  existente pra cada elenco do usuário antes de qualquer outra coisa,
  removendo a linha de verdade (nunca deixa "busca fantasma") e promovendo
  quem esperava na fila.
- Nova função `public.delete_my_account()` (security definer, roda como
  `auth.uid()`): cancela buscas ativas → anonimiza histórico compartilhado
  → resolve times (sai dos que é PLAYER; **dissolve** o time inteiro se
  for OWNER único; **bloqueia com FQ044** se for OWNER com outros membros,
  já que transferência de ownership não existe ainda — regra escolhida
  entre as 3 do pedido, a mais simples e segura) → deleta elencos
  (cascade limpa squads/vínculos/WL) → retorna.
- **Edge Function `delete-account`** (deployada, ACTIVE, `verify_jwt=true`
  — default seguro do Supabase, não precisou de config extra): valida o
  JWT do chamador via `auth.getUser()`, chama `delete_my_account()` com um
  client autenticado como o próprio usuário (nunca service role), e só
  depois disso — a ÚNICA etapa que precisa de privilégio — usa um client
  de service role separado pra `auth.admin.deleteUser(userId)`. Secret de
  service role nunca chega ao Flutter.

**Cascades já existentes** (não precisaram mudar): `profiles` (CASCADE de
`auth.users`), `notification_outbox`/`notification_preferences`/
`user_devices`/`user_notifications` (CASCADE de `profiles`),
`user_public_profiles` (CASCADE **direto** de `auth.users` — some junto,
confirmado por leitura do FK, não precisou de teste de runtime porque
nenhum usuário de QA tinha perfil público ativado).

**Owner edge cases — validados ao vivo** com 3 usuários reais (criados e
removidos via REST/RPC real, nunca só SQL direto, pra exercitar o
`auth.uid()` de verdade):

| Cenário | Resultado |
| --- | --- |
| A é OWNER único de um time (sem mais ninguém) | Exclusão bem-sucedida (200); time inteiro dissolvido; `auth.users`/`profiles` de A confirmados ausentes depois |
| B é OWNER de um time com C como PLAYER | Exclusão bloqueada (400, `FQ044`); time, membership de B e C, e a conta de B **inalterados** — confirmado que a transação inteira faz rollback, não fica meio-feita |

**Flutter**: `AuthRepository.deleteAccount()` (Supabase chama a Edge
Function + `signOut()` local pra encerrar o JWT órfão; Local mode limpa a
conta em memória). `AuthCubit.deleteAccount()` reaproveita o mesmo
`_run()`/`AuthState` de `signOut()` — sucesso vira `unauthenticated`
(o redirect do GoRouter tira a pessoa da tela sozinho, mesmo padrão de
sempre); falha mantém a sessão e mostra `state.failure` (nunca faz logout
como se tivesse dado certo). Novo `FQ044` mapeado em
`TeamFailureReason.soleOwnerBlocksAccountDeletion` (é uma restrição de
time, não uma categoria própria).

**UI**: `DeleteAccountPage` (`/app/profile/delete-account`) — lista as 6
consequências (elencos, escalações, participação em times, histórico,
preferências, perfil público), exige digitar a palavra de confirmação
localizada (`EXCLUIR`/`DELETE`/`ELIMINAR`) antes de habilitar o botão
destrutivo. Acessível por Perfil → "Excluir minha conta" (botão discreto
no fim da tela, não grita perigo até a pessoa realmente entrar na tela de
confirmação).

## Privacy

**Rotas**: `/privacy` e `/terms`, registradas como `alwaysPublicPaths` no
`_redirect` do GoRouter — mesmo padrão já usado por `/u/:identifier`,
acessíveis com ou sem sessão, nunca redirecionadas pro login.

**Conteúdo**: `lib/features/legal/` — texto vive como constantes Dart por
locale (`legal_content_{pt,en,es}.dart`), não como chave de l10n (ARB),
porque é prosa longa sem plural/ICU; as poucas strings de navegação ao
redor (título, botão) seguem no ARB normal. 12 seções em PT (completo,
escrito primeiro conforme pedido) + traduções completas EN/ES (não é
revisão jurídica internacional, mas também não é texto de 3 linhas):
responsável pelo app, dados coletados (detalhado: e-mail, avatar, IDs,
elencos, times, partidas, stats, push token, perfil público), provedores
(Supabase/Firebase), finalidade, armazenamento/segurança, retenção,
exclusão de conta, compartilhamento, direitos do usuário, menores,
mudanças, marca/afiliação. Placeholders explícitos e não inventados:
`[EMAIL_DE_SUPORTE]`, `[NOME/RAZÃO SOCIAL DO RESPONSÁVEL PELO APP]` — o
dono do produto preenche quando tiver esses dados reais.

**Settings**: Perfil ganhou uma seção "Sobre e legal" com 3 linhas —
Sobre, Política de Privacidade, Termos de Uso.

## Terms

Mesma arquitetura da Privacy (`terms_of_use_page.dart` +
`kTermsOfUse{Pt,En,Es}`). 14 seções: aceitação, sobre o app, conta,
conduta, matchmaking, conteúdo inserido, conteúdo de terceiros,
disponibilidade, suspensão/encerramento, propriedade intelectual,
limitação de responsabilidade, alterações, contato, marca/afiliação.

## Trademark

Disclaimer de não afiliação (mesmo texto que aparece em Privacy e Terms,
seção final de cada uma) também exposto de forma destacada (banner) na
nova página **About** (`/app/profile/about`), acessível por Perfil →
Sobre e legal → Sobre. Não há página pública inicial/marketing ainda (o
app exige sessão pra tudo exceto `/privacy`/`/terms`/`/u/:identifier`) —
documentado como N/A, não pulado por engano.

**Rename ainda pendente** — decisão do dono do produto, não implementada
nem decidida aqui. Pontos de uso do nome "FIFA Queue" mapeados para quando
essa decisão for tomada: `pubspec.yaml` (nome do pacote + descrição),
`android/app/src/main/AndroidManifest.xml` (`android:label`),
`ios/Runner/Info.plist` (2 ocorrências, `CFBundleName`/
`CFBundleDisplayName`), `web/manifest.json` (`name`/`short_name`/
`description`), `web/index.html` (3 ocorrências), `lib/app/app.dart`
(`MaterialApp.title`), `lib/core/design_system/branding/brand_assets.dart`
(`productName`). Renomear = editar esses 8 pontos + os 2 usos de
"Ultimate Team" no l10n + regenerar ícone/nome nas lojas — não é uma
mudança de código grande, é uma decisão de produto (e possivelmente de
domínio/handle em redes) que ninguém tomou ainda.

Disclaimer reduz ambiguidade de afiliação mas **não elimina** risco de
marca registrada — registrado explicitamente aqui, não é garantia
jurídica.

## Android Signing

`android/app/build.gradle.kts`: lê `android/key.properties` (se existir)
e monta `signingConfigs.create("release")` com os 4 campos padrão
(`storeFile`/`storePassword`/`keyAlias`/`keyPassword`). Sem o arquivo,
`release` cai no debug signing **apenas para builds que não são
release-de-verdade** — um `gradle.taskGraph.whenReady` verifica se algum
task pedido contém "Release" no nome e, se sim E não houver
`key.properties`, lança `GradleException` com mensagem explicando o que
falta e apontando pro doc. `flutter run --release` sem keystore configurado
ainda funciona (não é uma build de distribuição); `flutter build
apk/appbundle --release` sem `key.properties` agora **falha alto e claro**
em vez de gerar um artefato assinado com debug em silêncio.

`android/key.properties.example` criado (placeholders, seguro pra
commitar). `.gitignore` já tinha `key.properties`/`*.jks`/`*.keystore`/
`*.p12` de uma etapa anterior — confirmado, nada novo precisou ser
adicionado. `docs/android_signing.md` documenta geração de keystore,
formato do `key.properties` e comando de build — sem senha real em lugar
nenhum.

**Não foi rodada build de release completa** (o ambiente já tem uma
limitação documentada e não relacionada a este projeto:
`Unable to establish loopback connection` do Gradle no Windows local) —
só a configuração estática foi revisada e o Kotlin DSL relido com
cuidado. Validar a build de verdade fica para quando o dono do produto
tiver acesso a um ambiente onde `flutter build apk` já funcionava antes
desta etapa.

## Catalog Security

**Achado real, reconfirmado (não hipotético)**: antes desta etapa (fix já
aplicado na Etapa 17B, só reverificado aqui por pedido explícito) —
`fc_players`/`fc_player_cards` tinham `select using (true)` pra
`authenticated`, sem filtrar `is_active`.

**Reconfirmação ao vivo nesta etapa**: `pg_policies` mostra
`fc_player_cards_select_active`/`fc_players_select_active` com
`qual = (is_active = true)` — igual à Etapa 17B, sem regressão.

**Validação PostgREST real** (usuário de QA autenticado de verdade, não
service role):

```
GET /rest/v1/fc_player_cards?is_active=eq.false&select=id&limit=5  → 200 []
GET /rest/v1/fc_players?is_active=eq.false&select=id&limit=5       → 200 []
POST /rest/v1/rpc/search_fc_player_cards {"p_limit":3}             → 200 {"items":[],"has_more":false}
```

Zero linha inativa vaza; o picker (`search_fc_player_cards`) continua
funcionando sem erro (retorna vazio porque não há catálogo real ainda —
todas as 50 cartas `LOCAL` são inativas — não por causa de nenhum bug).

## Validation

QA feito com 3 usuários reais + 1 usuário extra pra catálogo, todos
criados via signup real (REST), nunca só inserção direta no banco — pra
exercitar `auth.uid()`/RLS de verdade. **Cleanup confirmado**: 0 usuários
e 0 times residuais (`select count(*) ... where email like 'qa-%'` → 0
nas duas rodadas).

| # | Checagem | Resultado |
| --- | --- | --- |
| 1 | Usuário exclui a própria conta | ✅ 200, `auth.users`/`profiles` confirmados ausentes |
| 2 | Usuário não exclui outra conta | ✅ RPC roda só sobre `auth.uid()`, sem parâmetro de id — inalcançável por construção |
| 3 | Owner único não destrói time de terceiros | ✅ bloqueado com FQ044, nada mutado (rollback confirmado) |
| 4 | Perfil público some | ✅ garantido por `ON DELETE CASCADE` direto de `auth.users` (não testado em runtime — nenhum QA user tinha perfil público ativo) |
| 5 | `auth.users` some | ✅ confirmado por query direta pós-exclusão |
| 6 | Sessão limpa | ✅ `signOut()` local após a Edge Function confirmar sucesso; listeners de sessão já existentes (Teams/FcAccounts/etc.) limpam o resto sozinhos |
| 7 | Privacy abre sem login | ✅ `alwaysPublicPaths`, mesmo padrão de `/u/:identifier` |
| 8 | Terms abre sem login | ✅ idem |
| 9 | Release config não usa debug key silenciosamente | ✅ validado estaticamente (sem build real, ver seção acima) |
| 10 | `key.properties` fora do git | ✅ já estava no `.gitignore`; confirmado |
| 11 | Inativos não vazam via PostgREST | ✅ REST real, `is_active=eq.false` → 0 linhas |
| 12 | Ativos continuam legíveis pelo caminho esperado | ✅ `search_fc_player_cards` responde sem erro (vazio por falta de catálogo real, não por bug) |

`flutter analyze`: **No issues found**. `dart format lib tool`: 8 arquivos
formatados (só os novos desta etapa).

## Git

Commits (todos em `origin/main`), sem trailer de coautoria:

1. Migration de exclusão de conta + Edge Function `delete-account`
2. Flutter: `AuthRepository.deleteAccount()` + `DeleteAccountPage` + rota + seção no Perfil
3. Privacy Policy + Termos de Uso (conteúdo PT/EN/ES + rotas públicas)
4. Disclaimer de não afiliação (About page + seções de marca em Privacy/Terms)
5. Assinatura de release Android (build.gradle.kts + key.properties.example + doc)
6. Atualização dos docs de lançamento (`launch_gap_analysis.md`, `handoff_etapa17.md`, `handoff.md`, este arquivo)

Migrations: 74 (73 + `20260927100000_account_deletion.sql`) locais =
remotas, confirmado por `supabase migration list`. Edge Functions:
`process-notification-outbox` (v3, ACTIVE) + `delete-account` (v1,
ACTIVE, `verify_jwt=true`).

## Remaining P0

Nenhum dos 4 P0 técnicos originais continua aberto. O único item da lista
original de risco de marca (item 5) que segue **verdadeiramente em
aberto** é a decisão de renomear ou não o produto — não é algo que este
automação decide sozinha, é decisão do dono do produto, com o disclaimer
como mitigação temporária já em produção.

Fora do P0 (não tocado nesta etapa, de propósito): CI/CD, suíte de testes
automatizados, analytics/crash reporting reais, QA visual, push em device
físico, catálogo FC27 real (Etapa 17B, aguardando arquivo). Fica pra Fase
B, não iniciada.
