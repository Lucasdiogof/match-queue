# Handoff — Etapa 16 (Perfil público + compartilhamento da Escalação Principal)

Status em 2026-09-08: **backend aplicado e validado ao vivo contra o
Supabase remoto** (71 migrations locais = 71 remotas), Flutter completo,
`flutter analyze` limpo (1 info-level de estilo, nenhum erro). Nenhum teste
automatizado foi rodado (regra permanente do projeto). Nenhum commit/push
foi feito ainda nesta sessão — ver seção Git.

## Objetivo, em uma frase

Perfil público opt-in (nunca ligado por default) com link estável, mostrando
so o que o dono explicitamente liberou de uma Conta escolhida — nunca vira
rede social (sem follow, comentário, view-count ou analytics).

## Decisão de schema: só slug (sem `public_id`)

O pedido oferecia a escolha entre slug amigável e/ou um `public_id` tipo
UUID. Implementei **só slug**: simplifica sem perder nada essencial — o
próprio slug já é o link estável pedido, e manter dois identificadores para
o mesmo dono só duplicaria a lógica de troca/revogação sem ganho real. Quem
não quiser "escolher handle" ainda pode usar qualquer string de 3-24
caracteres (ex. iniciais + números).

## Database

Migration nova: `supabase/migrations/20260925100000_public_profile_sharing.sql`
(nenhuma migration antiga foi editada). Códigos novos: **FQ040** slug com
formato inválido, **FQ041** slug reservado, **FQ042** slug já em uso,
**FQ043** habilitar sem slug. `FQ025` (conta não encontrada/não é dono/
inativa) foi **reaproveitado**, mesma semântica da Etapa 9, para a validação
de `fc_account_id`.

### Tabela `user_public_profiles`

```
user_id uuid PK references auth.users(id) on delete cascade
slug text unique (case-insensitive via índice único em lower(slug))
is_enabled boolean default false
fc_account_id uuid references user_fc_accounts(id) on delete set null
show_squad / show_weekend_league / show_rivals / show_stats boolean default false
created_at, updated_at
```

RLS habilitada, **zero policy** — mesmo padrão de `game_matches`/
`user_notifications`: todo acesso passa por RPC `security definer`. `revoke
all on user_public_profiles from public, anon, authenticated` — nem o dono
consegue `select` direto, só via `get_my_public_profile_settings()`.

### RPCs e permissões

| Função | Quem executa | Papel |
| --- | --- | --- |
| `_public_profile_reserved_slugs()` | ninguém (interna) | lista de palavras reservadas |
| `check_public_profile_slug_available(p_slug)` | `authenticated` | validação em tempo real na UI |
| `get_my_public_profile_settings()` | `authenticated` | lê a própria config (upsert-safe, devolve defaults se a linha não existe) |
| `update_my_public_profile_settings(...)` | `authenticated` | upsert da própria config; valida slug (formato/reservado/unicidade) e ownership de `fc_account_id` |
| `_public_squad_card_json(card, chemistry)` | interna | serialização whitelisted do card visual |
| `get_public_profile(p_identifier)` | **`anon` e `authenticated`** | única função pública, monta o jsonb campo a campo |

`anon` só tem `execute` em `get_public_profile` — nada mais. Testado ao vivo
(ver Security).

### `get_public_profile` — comportamento linha a linha

- Busca por `lower(slug) = lower(p_identifier) and is_enabled`. Não existe
  busca por `public_id` (não implementado, ver decisão acima).
- Não encontrado OU `is_enabled = false`: **mesma resposta**
  `{"schema_version": 1, "found": false}` — nunca revela que existe mas está
  desativado (item 29, testado ao vivo).
- Conta selecionada arquivada (`is_active = false`): a função (que por isso
  **não é `stable`**, é volátil de propósito) **autolimpa**
  `user_public_profiles.fc_account_id` para `null` nessa mesma chamada —
  preferência do dono do produto por invalidar a seleção automaticamente em
  vez de esconder em silêncio. A resposta daquela chamada já sai sem seção
  de Conta/squad/stats/WL/Rivals. Testado ao vivo.
- Squad: sempre `is_default and is_active` da Conta selecionada — nunca
  `game_matches.squad_snapshot` (squad é sempre o estado vivo, como pedido).
  Squad arquivado → seção `squad` fica `null`, conta continua aparecendo.
  Testado ao vivo.
- Cada sub-toggle desligado remove a seção correspondente do payload no
  **backend** — nunca é só escondido no Flutter. Testado ao vivo (toggles
  todos off → `stats`/`weekend_league`/`rivals`/`squad` todos `null`,
  `rivals_division` também sai do bloco `account` quando `show_rivals` é
  falso).
- Reaproveita `_fc_account_match_aggregate` (Etapa 12) para stats/WL/Rivals —
  mesma regra de cálculo já existente, nunca recalculada diferente.
- Weekend League usa o mesmo critério de "evento corrente" da Etapa 14
  (`is_active and now() between starts_at and ends_at`).

### Payload público — whitelist exata

```
schema_version, found,
profile: { display_name, avatar_url },
account: { name, rivals_division } | null,
stats: { matches_count, wins, losses, goals_for, goals_against, goal_diff } | null,
weekend_league: { computed: {...mesmo shape...} } | null,
rivals: { aggregate: {...mesmo shape...} } | null,
squad: {
  name, formation_code, formation_display_name,
  overall, chemistry, chemistry_rule_version,
  starters: [{ slot_code, player_name, rating, position, image_url, card_type, chemistry }]
} | null
```

Nunca sai: id de `fc_squads`/`fc_squad_slots`/`fc_player_cards`, PAC/SHO/PAS/
DRI/DEF/PHY completos, `user_id`, e-mail, dados de outra Conta que não a
selecionada. **Decisão consciente: banco NÃO entra no payload público nesta
V1** — só titulares (`slot_type = 'STARTING'`). O pedido permitia decidir;
manter só titulares mantém o payload mínimo e o card visual mais legível.
Documentado também no comentário SQL da função.

## Flutter

### Nova feature `lib/features/public_profile/`

Clean Architecture, mesmo padrão do resto do projeto (Bloc/Cubit, sem
codegen, repositório Local + Supabase):

- `domain/entities/public_sharing_settings.dart`, `public_profile.dart`
  (`PublicMatchAggregate`, `PublicSquad`, `PublicSquadStarter`).
- `domain/repositories/public_profile_repository.dart`.
- `data/datasources/public_profile_remote_data_source.dart` (4 RPCs),
  `data/models/public_profile_model.dart` (parsing), `data/repositories/`
  (`SupabasePublicProfileRepository` e `LocalPublicProfileRepository` — modo
  sem backend real guarda só a própria config local, nunca resolve perfil
  alheio, sempre `PublicProfile.notFound`).
- `presentation/cubit/sharing_settings_cubit.dart` (configuração do próprio
  perfil: `draft`/`saved` separados, `isDirty`, escrita otimista com
  rollback recarregando o estado salvo em caso de falha) e
  `public_profile_view_cubit.dart` (leitura pública, funciona sem
  `AuthRepository.currentUser`; quando há sessão, resolve `isOwner`
  comparando o slug da própria config com o identificador da rota — só
  dispara essa chamada extra quando autenticado).
- `presentation/widgets/sharing_settings_section.dart` (master switch +
  4 sub-toggles só habilitados com o master ligado, campo de slug com
  validação em tempo real debounced 500ms via
  `check_public_profile_slug_available`, seletor de Conta, copiar/
  compartilhar link, botão Salvar), `public_account_picker_sheet.dart`,
  `profile_share_card.dart`/`squad_share_card.dart` (templates visuais),
  `share_capture.dart` (`RenderRepaintBoundary` → PNG, sem backend de
  imagem externo).
- `presentation/pages/public_profile_settings_page.dart` (tela dentro do
  Perfil autenticado) e `public_profile_page.dart` (rota pública).
- `public_profile_module.dart` (DI, registrado em `app/dependencies.dart`).

### Rota pública: `/u/:identifier`

Escolhida `/u/` (curta, sem colidir com `/app/*` nem `/join/:code`) em vez
de `/public/:identifier`. Registrada como `GoRoute` **fora** do
`StatefulShellRoute` autenticado, em `app/router/app_router.dart`.
`AppRouter._redirect` ganhou uma checagem
`AppRoutes.isPublicProfileLocation(location)` que retorna `null`
**antes** de qualquer outra regra (inclusive antes de `authState.isResolved`)
— mesmo tratamento de `/join/:inviteCode`: a página renderiza imediatamente,
sem esperar a sessão resolver e sem jamais redirecionar para `/login`. Um
usuário autenticado que abre a mesma rota (do próprio perfil ou de outro)
navega normalmente — se for o dono, `PublicProfileViewCubit` resolve
`isOwner` e a página mostra o CTA extra "Editar compartilhamento".

### Link builder e deep link

`PublicProfileLinkBuilder` (`lib/core/platform/public_profile_link_builder.dart`)
espelha `InviteLinkBuilder`: `APP_LINK_HOST` configurado > origin atual no
Web > só o slug (mobile sem host configurado — nunca inventa URL HTTPS
falsa). **Universal links nativos completos (Apple App Site Association
hospedado, App Links verificados no Android) não foram implementados** — já
esperado e aceito pelo pedido ("documente isso como já esperado/aceito"). O
deep link do app abrindo a mesma rota `/u/:identifier` já é suficiente: quem
recebe o link e tem o app instalado com esquema configurado abre direto na
tela; sem isso, abre no navegador (que já funciona sem login, ver Web).

### Settings — Perfil → Compartilhamento

Nova linha "Compartilhamento" no `ProfilePage`
(`_NavRow` com `Icons.share_outlined`) levando a `/app/profile/sharing`.
Master switch "Perfil público" com os 4 sub-toggles (Escalação Principal/
Weekend League/Division Rivals/Estatísticas gerais) **desabilitados
visualmente enquanto o master está desligado** (a seção inteira de
sub-toggles some, não só fica cinza — evita o usuário achar que configurou
algo que não vai valer). Indicador `AppBadge` "Perfil público: Ativo/
Inativo". Seletor de Conta pública via `showPublicAccountPickerSheet`
(reaproveita `FcAccountsCubit` já carregado na raiz do app, nenhuma
chamada nova). Campo de slug com feedback em tempo real (Disponível/Em uso/
Verificando/Inválido). Botão "Copiar link" (feedback via `SnackBar`
discreto) e "Compartilhar" (usa o `ShareService`/`share_plus` já existente
no projeto — nenhuma dependência nova).

### CTAs de atalho

- `FcAccountDetailPage` ganhou `_ShareAccountRow` ("Compartilhar esta
  Conta"), navegando para `/app/profile/sharing?fcAccountId=<id>` — o
  parâmetro pré-seleciona a Conta E liga o master switch no **draft** (nunca
  salva sozinho; o usuário ainda aperta "Salvar").
- `SquadBuilderPage` ganhou uma ação "Compartilhar escalação" no menu
  "mais" (`_showActions`), navegando para
  `/app/profile/sharing?fcAccountId=<id>&showSquad=1` — mesma lógica:
  oferece habilitar o compartilhamento e o toggle de squad, nunca ativa
  sozinho.
- `SharingSettingsCubit.applyPreselect` é o método que aplica isso no draft
  depois do `load()` inicial.

### Card visual compartilhável

`ProfileShareCard` (avatar, nome, Conta, badges de Rivals/WL/record) e
`SquadShareCard` (nome, formação, OVR, química total, chips de titulares
com rating/posição/imagem/química individual — **banco não incluído nesta
V1**, mesma decisão da RPC). Ambos têm fallback visual (`Icons.person` em
círculo) quando falta `image_url` — nunca quebra layout, testado
mentalmente com `imageUrl: null` (dataset dev sem imagens de carta).
`ShareCapture.captureBoundary` converte o widget (envolvido em
`RepaintBoundary`) em PNG via `RenderRepaintBoundary.toImage`, 100% no
Flutter, sem backend de imagem externo.

`ShareService` (já existente, usado pelo convite) ganhou `shareImage(bytes,
{fileName, text})`, usando `XFile.fromData(...)` do `share_plus` — no
mobile abre a folha de compartilhamento nativa com a imagem (que já inclui
"Salvar" como uma das opções do sistema, então não construí um botão
"Salvar" separado). No Web, o `share_plus` tenta a Web Share API com
arquivo; quando o navegador não suporta, a chamada lança e a UI mostra um
aviso pedindo desculpa (`publicProfileShareImageError`) — **não implementei
download de arquivo separado no Web** por simplicidade (pedido permitia
"se for simples"; a Web Share API já cobre os navegadores modernos mais
comuns, e adicionar um caminho de download via `dart:html` só para
navegadores sem suporte não parecia valer a complexidade extra agora).

### QR code

**Não implementado.** O pedido deixava explicitamente opcional ("só
implemente se houver um pacote leve trivial de adicionar; não bloqueie a
etapa por causa disso") — não há pacote de QR já no projeto, e adicionar
uma dependência nova só para isso ficou para decisão futura do dono do
produto.

## Revogação — comportamento validado ao vivo

- Desativar (`is_enabled = false`): próxima leitura já retorna `found:
  false` — testado ao vivo.
- Trocar/regenerar o slug: o slug antigo para de resolver imediatamente
  (mesma resposta de not-found), o novo já resolve na mesma chamada —
  testado ao vivo.
- Nenhum cache/TTL foi adicionado em nenhuma camada (RPC direta, sem
  `cache-control` custom) — a fonte é sempre a tabela atual, então não há
  janela de revogação atrasada a documentar.

## Segurança — os 11 casos críticos, executados de verdade contra o Supabase remoto (`lteujeclnhmurcewurkg`), com dados temporários removidos ao final

Usuários/contas/squads de teste (`qa-etapa16-a@example.com`,
`qa-etapa16-b@example.com` e dependências) foram criados via SQL direto,
exercitados e **completamente removidos** ao final — confirmado por
`select count(*) from auth.users where email like 'qa-etapa16-%'` = 0.

1. **`anon` não lê `profiles`/`user_fc_accounts`/`fc_squads` direto** —
   verde. Chamada REST real com a `SUPABASE_PUBLISHABLE_KEY` do
   `env/development.json` contra as 3 tabelas devolveu `42501 permission
   denied` nas 3, com a mensagem de grant faltante citando exatamente
   `anon`.
2. **`anon` só executa a RPC pública** — verde. Mesma chamada REST anônima
   para `rpc/get_public_profile` respondeu `200` com o payload esperado;
   `user_public_profiles` também devolveu `42501` para `anon`.
3. **`is_enabled=false` e identificador inexistente são indistinguíveis** —
   verde. Ambos retornaram exatamente `{"found": false, "schema_version":
   1}`, byte a byte.
4. **Perfil habilitado retorna exatamente a whitelist** — verde. Payload
   completo capturado com squad/stats/rivals/weekend_league todos
   populados; nenhum campo fora da lista documentada apareceu (sem id de
   carta, sem stats detalhados, sem `user_id`).
5. **Usuário não seta `fc_account_id` de outro usuário** — verde. Chamada
   de `update_my_public_profile_settings` pelo usuário B com o
   `fc_account_id` do usuário A levantou `FQ025` imediatamente.
6. **Squad de Conta diferente nunca aparece** — verde por construção (a
   query de squad sempre filtra por `fc_account_id = v_account.id`, a
   própria Conta selecionada) e confirmado no payload capturado (só a carta
   do squad da Conta selecionada apareceu).
7. **Cada sub-toggle desligado remove o campo/seção** — verde. Com os 4
   toggles desligados, `stats`/`weekend_league`/`rivals`/`squad` saíram
   `null` e `rivals_division` saiu do bloco `account`.
8. **Desativar invalida a próxima leitura** — verde (seção Revogação).
9. **Trocar/regenerar o slug invalida o antigo** — verde (seção Revogação).
10. **Conta/squad arquivado não vaza dado desatualizado** — verde. Conta
    arquivada: `account` virou `null` e a coluna `fc_account_id` foi
    autolimpa na mesma chamada (confirmado relendo a linha depois). Squad
    arquivado (com a Conta ainda ativa): só `squad` virou `null`, `account`
    continuou aparecendo normalmente.
11. **Página pública abre sem sessão** — verde por construção: o `_redirect`
    do `GoRouter` devolve `null` para qualquer `/u/*` antes de checar
    `authState.isResolved`, e `get_public_profile` tem `grant execute to
    anon` de fato confirmado na chamada REST anônima do item 2.

Validações extras feitas no mesmo lote: formato de slug inválido → `FQ040`;
slug reservado (`admin`) → `FQ041`; slug já em uso por outro usuário
(case-insensitive, `QA_FINAL_SLUG` vs `qa_final_slug`) → `FQ042`.

## Git

Nenhum commit feito ainda nesta sessão — a implementação inteira (migration
+ Flutter + l10n + docs) está pronta na árvore de trabalho, aguardando
autorização explícita para commitar/pushar (regra permanente do projeto).
Migration `20260925100000_public_profile_sharing.sql` já está **aplicada no
Supabase remoto** (`npx supabase db push` sem erro,
`npx supabase migration list` confirma **71 locais = 71 remotas**).
`flutter analyze`: limpo (1 info-level de estilo em `app_routes.dart`,
nenhum erro/warning). `dart format lib` aplicado (7 arquivos formatados).

## Pendências conscientes / fora de escopo

- **Universal links nativos completos** (Apple App Site Association
  hospedado, App Links verificados no Android): não implementado, aceito
  pelo próprio pedido — depende de infraestrutura externa (domínio +
  hospedagem do arquivo de verificação) que não existe hoje no projeto. O
  deep link do app abrindo a rota `/u/:identifier` cobre o suficiente.
- **QR code**: não implementado, opcional por decisão explícita do pedido —
  nenhum pacote leve de QR já estava no projeto.
- **Download de imagem separado no Web** quando a Web Share API não tem
  suporte a arquivo: não implementado — a UI mostra um aviso nesse caso, em
  vez de um segundo caminho via `dart:html`.
- **Banco (reservas) no payload/card público**: fora desta V1 — só
  titulares. Estrutura da RPC já isola isso num único trecho
  (`slot_type = 'STARTING'`), fácil de estender se um dia for pedido.
- **Follow/comentário/view-count/analytics**: deliberadamente NÃO
  implementados — fora do escopo por decisão de produto explícita no
  pedido original ("nunca virar rede social").
- **`public_id`/handle alternativo tipo UUID**: não implementado — decisão
  consciente de simplificar para só slug (ver seção Database).
- Revisão linguística profunda PT/EN/ES, QA visual e suíte de testes
  automatizados seguem para a etapa final, conforme a regra de execução do
  projeto.

## Fechamento contra o critério do dono do produto

- Perfil opt-in (`is_enabled` default `false`) — ✅.
- Identificador estável (slug, link não muda ao trocar de Conta pública,
  só o conteúdo) — ✅.
- `anon` abre o perfil permitido sem acessar tabela privada nenhuma — ✅,
  testado ao vivo (itens 1-2).
- Conta pública escolhível, com validação de ownership — ✅, testado ao
  vivo (item 5).
- Toggles respeitados por stats/WL/Rivals/squad, no backend — ✅, testado
  ao vivo (item 7).
- Squad sempre atual, nunca snapshot de partida — ✅, por construção
  (query direta em `fc_squads`/`fc_squad_slots`, nunca
  `game_matches.squad_snapshot`).
- Link copiável/compartilhável — ✅ (`ShareService` reaproveitado).
- Revoke funciona (desativar, trocar slug, Conta/squad arquivado) — ✅,
  testado ao vivo (itens 8-10).
- Private/not-found indistinguíveis — ✅, testado ao vivo (item 3), byte a
  byte idêntico.
- Web funciona sem login — ✅, por construção (`_redirect` libera `/u/*`
  incondicionalmente).
- Imagem compartilhável funciona (mobile via share sheet nativo; Web via
  Web Share API quando suportada) — ✅, com fallback de aviso documentado
  quando a plataforma não suporta.
- Catálogo FC27 vazio não quebra o layout — ✅: sem carta real, o squad de
  desenvolvimento usa as 50 cartas `LOCAL`; sem squad nenhum, a seção
  inteira de squad simplesmente não aparece (`squad: null`), sem erro.

**A Etapa 16 fecha** pelo critério acima. Não avancei para nenhuma outra
etapa.
