# FIFA Queue — ponto de entrada

**Comece por aqui.** Este arquivo é o índice de continuidade do projeto. Vive
no repositório de propósito: anotação local não atravessa troca de máquina
nem de ambiente, este arquivo sim.

Estado em 2026-09-09: **Etapas 1–20 fechadas** (17-20 foram auditoria,
sem feature nova). **Etapa 20 (Store Release Readiness / Device QA)
encerrou com veredito NOT READY — CONFIG BLOCKERS**: zero bug de
código, zero bloqueio de arquitetura. O que falta é 100% credencial/
config (keystore Android + `key.properties`, setup de Xcode nunca feito
neste projeto — nem `pod install` rodou ainda —, domínio pra Privacy
Policy URL e App/Universal Links, textos e artes de listagem de loja) e
ambiente de execução (Gradle não builda nesta máquina Windows — release
E debug de APK/AAB tentados de verdade, mesmo erro de loopback nos
dois; Web compila mas não roda ao vivo no navegador de preview pelo mesmo
bloqueio de sandbox já visto na Etapa 19; iOS exige macOS). Estimativa
de completude de metadata: Google Play ~35%, App Store ~25%. Checklist
manual de Device QA criado, execução pendente de aparelho físico.
**Correção pós-fechamento**: a readiness de assinatura Android não é
uma frase só — `READY TO CREATE RELEASE KEY: SIM` (zero blocker de
código), `READY TO BUILD RELEASE NESTA MÁQUINA: NÃO` (Gradle/Windows) e
`READY FOR STORE SUBMISSION: NÃO` (keystore real + metadata faltando)
são três respostas distintas, ver seção 9 de
`release_checklist_android.md`. **Atualização 2026-09-09: primeiro AAB
de release real assinado, gerado com sucesso** — keystore real criado,
`android/key.properties` e `env/production.json` preenchidos (com
`APP_LINK_HOST=lucksrei.com`, domínio decidido, e `FIREBASE_ENABLED=true`),
um bug real de path (`storeFile` ainda no placeholder do template)
encontrado e corrigido no meio do caminho. Build rodou no terminal do
próprio usuário — nesta ferramenta de execução automatizada o Gradle
ainda bate no erro de loopback, confirmando que a limitação é do
processo que chama o Gradle, não da máquina Windows como um todo.
`READY TO BUILD RELEASE NESTA MÁQUINA` passa a **SIM** (no terminal do
usuário). **Etapa 21 (Google Play readiness + preparação pro Mac,
2026-09-09)**: auditoria do próprio AAB (assinatura real confirmada por
`META-INF/FIFAQUEU.RSA`/`Signflinger`, `POST_NOTIFICATIONS` presente no
manifest final, nenhuma flag de debug); checklist sequencial completo
de Google Play (~40% pronto, ver `docs/google_play_release.md`);
levantamento real de Data Safety (`docs/google_play_data_safety.md` —
e-mail, nome, device token, crash logs; nada de localização/contatos/
fotos/financeiro); checklist manual de Device QA Android
(`docs/android_device_qa.md`, criado, execução pendente de aparelho);
auditoria iOS + checklist de 21 passos pro Mac
(`docs/ios_release_mac.md` — `Podfile` nunca existiu, capabilities de
push/background nunca configuradas, esperado, não regressão);
`docs/deep_links.md` atualizado com o SHA-256 real do keystore de
release e o conteúdo pronto de `assetlinks.json`/
`apple-app-site-association` pra `lucksrei.com` — **nada publicado no
domínio nem no manifest**, só documentado. Zero mudança de código
Dart/nativo nesta etapa. Ver
[`handoff_etapa20.md`](handoff_etapa20.md),
[`release_checklist_android.md`](release_checklist_android.md),
[`release_checklist_ios.md`](release_checklist_ios.md) e
[`release_checklist_store_metadata.md`](release_checklist_store_metadata.md).
`flutter analyze`/`flutter test` limpos, nenhum código mudou nesta
etapa. Etapa 19 (Release QA original, mesmo veredito de ambiente) segue
em [`handoff_etapa19.md`](handoff_etapa19.md). **Fase A (bloqueadores de
lançamento) FECHADA** — exclusão
de conta, Privacy/Terms, assinatura de release e vazamento de catálogo
inativo todos corrigidos e validados ao vivo, ver
[`handoff_fase_a_launch.md`](handoff_fase_a_launch.md). **Etapa 17B/17B-2
(importação real do catálogo FC27) FECHADA — FULL IMPORT COMPLETE, READY
FOR APP QA.** O catálogo Wrexist inteiro (17.873 cartas, republicação MIT
do endpoint da EA, usado como fonte real enquanto o arquivo "oficial" da
EA não chega) está em produção via `tool/sync_fc_cards.dart` real (nunca
SQL manual): 11.160 inseridas + 6.713 atualizadas (as que já vinham dos
degraus 500/2.000/5.000/40) = 17.873 exatas, 0 falha, 53s de execução
(336 registros/s). Idempotência confirmada em escala completa (segunda
execução: 0 inserido, 17.873 atualizado, contagens idênticas). QA REST
real limpo (posição, liga, clube, rating, nação, masculino/feminino,
paginação até a última página) com usuário descartável, removido sem
resíduo. **Achado real, diagnosticado e documentado, não corrigido**: 32
linhas órfãs em `fc_clubs` (herdadas de antes do mapeamento
`club_external_id` existir, zero cartas apontando pra elas, zero impacto
em qualquer feature) — distinto do achado já conhecido dos 42 clubes
homônimos em ligas diferentes (esse continua igual, aceito). Ver
[`handoff_etapa17b2.md`](handoff_etapa17b2.md) (seção 17 tem o full
import; seções 1-16 têm o histórico da validação em escala) e
[`handoff_etapa17b.md`](handoff_etapa17b.md) (histórico mais antigo).
**Etapa 18 (validação do catálogo real dentro do app) FECHADA — READY
FOR RELEASE QA.** Auditoria pura, zero mudança de código: Squad Builder/
picker/busca/filtros testados ao vivo via REST contra as 17.873 cartas
reais (posição, anti-duplicação de carta em slot, overall/chemistry,
masculino/feminino, clube ambíguo, sem clube, nomes semelhantes — tudo
PASS, nenhuma regra nova inventada). Performance real medida (145-594ms
por busca, picker já pagina server-side, nunca carrega tudo de uma vez)
— nenhuma otimização necessária. Achado adicional: mesmo padrão dos 32
`fc_clubs` órfãos existe em menor escala em `fc_leagues` (6) e
`fc_nations` (8) — documentado, não corrigido, zero impacto. Única
pendência real: QA visual Flutter não executável neste ambiente. Ver
[`handoff_etapa18.md`](handoff_etapa18.md).
76 migrations locais = remotas, `flutter analyze` e `flutter test
test/tool` (6/6) sem issues. Edge Functions:
`process-notification-outbox` (v3, ACTIVE) e `delete-account` (v1,
ACTIVE). **Nenhum push foi feito** desta atualização — aguarda
autorização explícita.

**Antes de decidir o que vem depois, leia
[`launch_gap_analysis.md`](launch_gap_analysis.md)** (diagnóstico
original) **e [`handoff_fase_a_launch.md`](handoff_fase_a_launch.md)**
(o que já foi corrigido). Resumo da auditoria original em
[`handoff_etapa17.md`](handoff_etapa17.md). Único P0 de marca ainda em
aberto: decisão de renomear o produto (não implementada, é decisão do
dono).

---

## 1. O que o produto é

Coordena qual jogador de um grupo pode procurar partida no EA SPORTS FC /
Clubs naquele momento — um `SEARCHING` por vez, os demais numa fila que
avança sozinha — e registra o que aconteceu em campo.

Modelo central, que explica quase toda decisão de schema:

```
Usuário
├── Time (grupo social)              teams / team_members
└── Conta / Elenco ("Lucksrei")      user_fc_accounts
    ├── vínculo N:N com Times        fc_account_teams
    └── Squad / Escalação            fc_squads
        ├── formação                 fc_formations / fc_formation_slots
        ├── slots preenchidos        fc_squad_slots
        └── técnico + liga           fc_managers / fc_leagues
```

Distinções que já custaram bug quando ignoradas:

- **Time** é o grupo social do app, nunca um clube do jogo.
- **Conta** é a conta de Ultimate Team; **Squad** é uma escalação dela. Não
  são a mesma coisa e `FcAccount` nunca foi renomeado.
- `fc_players` é a identidade do atleta; `fc_player_cards` é a carta/item.
  **Squad e stats sempre referenciam a CARTA**, nunca o jogador base.
- Uma carta só é criada quando existe `provider_card_id` explícito.

## 2. Onde está o detalhe de cada etapa

| Doc | Assunto |
| --- | --- |
| `handoff_etapa7.md` | push/FCM, outbox, Edge Function |
| `etapa7_server_setup.md` | runbook de secrets/Vault/deploy |
| `handoff_etapa8_5.md` | Jogar, `game_matches`, resultados |
| `handoff_etapa9.md` | Contas/Elencos, vínculo com Times, WL/Rivals |
| `handoff_etapa10.md` | Squad Builder v1, formações, snapshot |
| `handoff_etapa11.md` | catálogo de cartas, importer |
| `handoff_etapa11_player_card_split.md` | separação `fc_players` / `fc_player_cards` |
| `handoff_etapa12.md` | gols, assistências, stats, perfil público |
| `handoff_etapa13.md` | Squad Builder 2.0, overall, química |
| `handoff_etapa14.md` | Times 2.0, dashboard esportivo, ranking |
| `handoff_etapa15.md` | Central de Notificações, eventos sociais/esportivos, correção de dedupe_key |
| `handoff_etapa16.md` | Perfil público opt-in + compartilhamento da Escalação Principal, rota `/u/:identifier` |
| `handoff_etapa17.md` | Auditoria de lançamento (sem feature nova) — índice curto |
| `handoff_etapa17b.md` | Importação real do catálogo FC27 — segurança corrigida, importer adaptado, sample de 40 escrito em produção |
| `handoff_etapa17b2.md` | Validação em escala + full import real do catálogo FC27 (17.873 cartas), idempotência, QA REST, 32 fc_clubs órfãos diagnosticados |
| `handoff_etapa18.md` | Validação do catálogo real dentro do app — Squad Builder/picker/busca/filtros contra as 17.873 cartas, performance real, sem bug encontrado |
| `handoff_etapa19.md` | Release QA — veredito NOT READY, bloqueio 100% de ambiente (Web/Android/iOS), fluxos críticos validados via REST onde possível |
| `handoff_etapa20.md` | Store Release Readiness / Device QA — veredito NOT READY (config), estimativas de metadata Play/App Store, checklist manual de device QA |
| `release_checklist_android.md` | Keystore/signing/SDK/ícones Android — o que falta, sem inventar credencial |
| `release_checklist_ios.md` | Auditoria estática iOS + checklist operacional de 10 passos para executar num Mac |
| `release_checklist_store_metadata.md` | O que existe e o que falta pra Google Play e App Store, item a item |
| `google_play_release.md` | Checklist sequencial de release Play Store (Store Listing → produção), com auditoria real do AAB assinado |
| `google_play_data_safety.md` | Levantamento real do que o app coleta, pra preencher o formulário de Data Safety |
| `android_device_qa.md` | Checklist manual de QA em device Android físico com o release real |
| `ios_release_mac.md` | Auditoria estática iOS + checklist de 21 passos pra continuar o release num Mac |
| `handoff_fase_a_launch.md` | Fase A — exclusão de conta, Privacy/Terms, assinatura de release Android, disclaimer de marca, catálogo is_active revalidado |
| `handoff_ui_refresh.md` | UI/UX refresh — shell de 5 abas com Controle central, Times público/privado + página pública, Início/Histórico com identidade própria, AppBackground/FeatureHeader |
| `handoff_gameplay_flows_refresh.md` | Gameplay flows refresh — Conta FC obrigatória antes de Time, anti-duplicação no picker, imagens de carta, overlap no campo, bottom sheet overflow, filtros hierárquicos, RivalsCard na Home |
| `android_signing.md` | Como gerar keystore e configurar `key.properties` para build de release Android |
| `launch_gap_analysis.md` | Diagnóstico completo de gaps para lançamento: features, segurança, testes, loja, marca |
| `card_provider_research.md` | pesquisa de fonte de cartas e por que cada uma foi descartada |
| `architecture.md`, `database.md`, `supabase_setup.md`, `deep_links.md`, `branding.md` | referência transversal |

## 3. Ambiente

- Supabase project ref **`lteujeclnhmurcewurkg`**, região `sa-east-1`.
- CLI só por **`npx supabase`** (não há binário no PATH). Comandos usados:
  `npx supabase migration list`, `db push`, `db query --linked -f arquivo.sql`.
- `env/development.json` (SUPABASE_URL + PUBLISHABLE_KEY) é **gitignored** —
  precisa ser fornecido em qualquer checkout novo.
- Também gitignored e necessários para build mobile: `lib/firebase_options.dart`,
  `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`.
- Bundle/application ID: `com.lucasdiogof.fifaqueue`.

## 4. Convenções do repositório

- **Commits em inglês**, imperativos, sem prefixo `feat:`/`fix:` e **sem
  qualquer rodapé de autoria**. O trabalho é do dono do repositório.
- **Nunca `git add -A`** — sempre caminhos explícitos.
- **`dart format .` quebra neste repo** — usar `dart format lib`.
- **Nunca editar migration já aplicada.** Correção é migration nova.
- Padrão de segurança em toda RPC: `security definer`, `search_path = ''`,
  identificadores qualificados, grants explícitos, nada profilático para
  `service_role`.
- Códigos de erro no namespace `FQxxx`, hoje até **FQ043**. **FQ014 está
  livre e não deve ser usado sem necessidade real.**

## 5. Armadilhas que já causaram bug aqui

- **`gen-l10n` respeita a ordem de `@placeholders`** — conferir a assinatura
  gerada antes de chamar. Já houve troca silenciosa de argumentos duas vezes.
- **`.order()` do postgrest-dart é DESCENDENTE por padrão.** Sempre passar
  `ascending: true` explicitamente. Já inverteu "meus times" e a lista de
  membros.
- **Assinaturas de matchmaking mudaram na Etapa 12** e não têm mais
  `p_team_id`:
  `request_match_search(p_fc_account_id, p_fc_squad_id, p_game_mode)` e
  `report_match_found_and_start_game(p_fc_account_id)`.
- **`game_matches` é fechada a select direto (RLS)** — ler sempre por RPC.
- **Dedupe multi-time**: uma busca de uma Conta toca N Times. Nunca agregar
  por `game_matches → search_session → session_teams` (duplica). Usar sempre
  `EXISTS` sobre `fc_account_teams`.
- **`pg_cron`** aceita intervalo em segundos só até 59.
- **`supabase db query`** injeta um comentário no fim do SQL, o que quebra
  blocos `DO $$...$$` — usar `-f arquivo`.
- **`ea.com/robots.txt`** tem reserva de direitos explícita contra scraping/
  mineração automatizada de dados — nada deve bater em `drop-api.ea.com`
  automaticamente, mesmo que a requisição técnica funcione (200 OK). Dado
  precisa vir de download manual do usuário. Ver `docs/handoff_etapa17b.md`.
- **`tool/sync_fc_cards.dart`**: um `--map` que sobrescreve `primary_position`
  sem também sobrescrever `alternative_positions` cai num default obsoleto
  em silêncio (sempre zero alternativas) — corrigido na Etapa 17B pra
  detectar isso e usar fallback seguro, mas vale conferir o dry-run report
  ("linhas com posicoes alternativas") ao escrever um mapeamento novo.

## 6. O que está pendente

**Bloqueado por dado externo:**

- **Arquivo "oficial" da EA continua não obtido** — mesmo motivo de
  sempre (`robots.txt` proíbe mineração automatizada, precisa vir de
  download manual do usuário). Não bloqueia nada: o dono do produto
  decidiu em 2026-09-09 promover o Wrexist snapshot de fixture de teste a
  fonte de trabalho real (ver item resolvido abaixo), então isso deixou
  de ser blocker de produto — só fica registrado caso o arquivo da EA
  apareça um dia e vire uma segunda fonte a reconciliar.

**Resolvido em 2026-09-09 (Etapa 17B/17B-2, FECHADA):**

- **Catálogo FC27 real (Wrexist snapshot, 17.873 cartas) importado em
  produção por completo.** Importer auditado e adaptado (posições em
  colunas separadas, detailed_stats/playstyles_plus/raw_metadata,
  `--full-catalog`, `source_url`, cache de nomes, upsert em lote); 3
  degraus (500/2.000/5.000) validados em escala com credencial real,
  depois full import autorizado e executado via `tool/sync_fc_cards.dart`
  (11.160 inseridas + 6.713 atualizadas = 17.873, 0 falha, 53s/336
  reg/s), idempotência confirmada em escala completa, QA REST real
  limpo. Catálogo pronto para uso normal no app. Achado não-bloqueante
  documentado: 32 linhas órfãs em `fc_clubs` (sem carta nenhuma
  apontando pra elas, herdadas de antes do `club_external_id` existir) —
  não corrigido, sem impacto em nenhuma feature. Ver
  `docs/handoff_etapa17b2.md` (seção 17 para o full import; seções 1-16
  para o histórico completo da validação em escala).
- **Fontes de carta descartadas** (FUT.GG, FUTBIN, FUTWIZ, WeFUT, SoFIFA,
  fcratings): todas por `robots.txt` ou ToS. Razão de cada uma em
  `card_provider_research.md`. Não reabrir a pesquisa.

**Por limitação de ambiente:**

- Push em device Android físico e APNs/iOS nunca foram confirmados
  visualmente (Gradle falha neste Windows; iOS precisa de Mac). O caminho de
  envio já foi exercitado de verdade contra o FCM.
- Web Push adiado (depende de VAPID + service worker + domínio).

**Adiado por decisão de produto:**

- Química: Icons/Heroes (estrutura pronta, exceção não escrita).
- Artilharia: consolidar versões da mesma pessoa (Gold vs TOTS) — depende de
  decisão sobre `fc_players`.
- `fc_account_teams` sem histórico temporal: dashboards refletem vínculos
  atuais.
- Hall histórico de ex-membros; empates (o domínio é WIN/LOSS).
- `weekend_league_event_model.dart` órfão desde a Etapa 9.
- **Renomear o produto** (risco de marca por citar "FIFA"/"EA SPORTS FC"/
  "Ultimate Team") — disclaimer de não afiliação já em produção como
  mitigação (Fase A), mas a decisão de rename em si segue do dono do
  produto. Pontos de uso mapeados em `docs/handoff_fase_a_launch.md`.

**Para a etapa final:**

- Revisão linguística PT/EN/ES, QA visual, suíte de testes automatizados e
  hardening — deliberadamente concentrados no fim, conforme a regra de
  execução atual (construir até 100%, validar pontualmente).

## 7. Regra de execução atual

Foco em funcionalidade: commits e push frequentes, sem parar a cada bloco
para QA, sem rodar suíte completa, sem build completo, sem revisão profunda
de tradução. Validar **pontualmente** apenas migrations, RPCs críticas,
integridade de dados e bugs bloqueantes. Uma checagem de `flutter analyze` no
fechamento basta.

## 8. Como retomar

1. `git pull` e conferir que `main` está sincronizado.
2. `npx supabase migration list` — local e remoto devem bater (63).
3. Ler o `handoff_etapa*.md` da etapa mais recente relevante.
4. Confirmar que `env/development.json` existe (senão, nada que fale com o
   Supabase roda).
5. `flutter analyze` antes de começar, para partir de uma base verde.
