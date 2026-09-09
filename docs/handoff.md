# FIFA Queue — ponto de entrada

**Comece por aqui.** Este arquivo é o índice de continuidade do projeto. Vive
no repositório de propósito: anotação local não atravessa troca de máquina
nem de ambiente, este arquivo sim.

Estado em 2026-09-09: **Etapas 1–17 fechadas** (17 foi auditoria, sem
feature nova), **Fase A (bloqueadores de lançamento) FECHADA** — exclusão
de conta, Privacy/Terms, assinatura de release e vazamento de catálogo
inativo todos corrigidos e validados ao vivo, ver
[`handoff_fase_a_launch.md`](handoff_fase_a_launch.md). **Etapa 17B
(importação real do catálogo FC27) segue EM ANDAMENTO, agora sobre dado
real** — o dono do produto decidiu explicitamente promover o Wrexist
snapshot (17.873 cartas, republicação MIT do endpoint da EA) de fixture de
teste para fonte de trabalho real desta etapa, já que o arquivo "oficial"
da EA ainda não chegou. Auditoria completa + normalização + dry-run
completo (17.873/17.873 válidas, 0 inválidas) rodados e limpos nesta
sessão; sample import de 40 cartas **preparado mas bloqueado**: este
ambiente não tem `SUPABASE_SECRET_KEY` para rodar `tool/sync_fc_cards.dart`
em modo de escrita — decisão de como prosseguir (secret key vs. SQL
equivalente) pendente do dono do produto. Ver
[`handoff_etapa17b.md`](handoff_etapa17b.md), seção "2026-09-09 (sessão de
validação técnica)". 74 migrations locais = remotas, `flutter analyze` e
`dart analyze tool lib` sem issues. Edge Functions:
`process-notification-outbox` (v3, ACTIVE) e `delete-account` (v1,
ACTIVE).

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
| `handoff_etapa17b.md` | Importação real do catálogo FC27 — segurança corrigida, importer adaptado, aguardando arquivo real da EA |
| `handoff_fase_a_launch.md` | Fase A — exclusão de conta, Privacy/Terms, assinatura de release Android, disclaimer de marca, catálogo is_active revalidado |
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

- **Catálogo FC27 real ainda não importado em produção (Etapa 17B em
  andamento).** O arquivo oficial da EA continua não obtido (mesmo motivo
  de sempre — `robots.txt` proíbe mineração automatizada, precisa vir de
  download manual do usuário). **Mudança 2026-09-09**: o dono do produto
  decidiu trabalhar com o Wrexist snapshot (17.873 cartas) como fonte real
  desta etapa enquanto o arquivo da EA não chega. Importer auditado e
  adaptado (posições em colunas separadas, detailed_stats/playstyles_plus/
  raw_metadata, `--full-catalog`, `source_url` por linha); segurança do
  `is_active` aplicada em produção; auditoria + normalização + dry-run
  completo do Wrexist snapshot rodados e limpos (17.873/17.873 válidas).
  **Bloqueador atual**: sample import de 40 cartas preparado mas não
  escrito — este ambiente não tem `SUPABASE_SECRET_KEY` para rodar
  `tool/sync_fc_cards.dart` sem `--dry-run`. Decisão pendente do dono do
  produto: exportar a secret key numa sessão futura, ou aceitar um SQL
  equivalente gerado à mão (`docs/final_data/scripts/
  generate_sample_import_sql.py`, não executado) como substituto — ver
  `docs/handoff_etapa17b.md`. Nada no produto depende disso pra funcionar —
  o app roda com as 50 cartas `provider = 'LOCAL'` de dev e com catálogo
  real vazio até lá.
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
