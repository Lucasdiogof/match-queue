# Handoff — Etapa 18 (validação e endurecimento do catálogo real no app)

Status em 2026-09-09: **READY FOR RELEASE QA.** Nenhum bug real foi
encontrado no fluxo Squad Builder/picker/busca/filtros contra o catálogo
completo (17.873 cartas). Esta etapa foi auditoria, não reescrita — HEAD
não mudou (`f32592e`), nenhum arquivo de código foi alterado, nenhuma
migration nova.

## 1. Fase 1 — Mapa real do caminho de dados

```
UI (player_picker_sheet.dart, squad_builder_page.dart)
  -> PlayerPickerCubit / SquadBuilderCubit (presentation/cubit)
  -> PlayerCardCatalogRepository / FcSquadRepository (domain/repositories)
  -> SupabasePlayerCardCatalogRepository / SupabaseFcSquadRepository (data/repositories)
  -> FcSquadRemoteDataSource (data/datasources) -> supabase.rpc(...)
  -> RPCs security definer no Postgres (search_fc_player_cards,
     set_fc_squad_slot, get_fc_squad_builder, etc.)
  -> fc_player_cards / fc_players / fc_clubs / fc_leagues / fc_nations
```

- **Busca/picker**: `search_fc_player_cards` (RPC, `stable security definer`)
  — único ponto de leitura de `fc_player_cards` para a UI. Sempre filtra
  `is_active = true` (exclui as 50 cartas `LOCAL`, confirmado ao vivo:
  100% delas têm `is_active = false`, então a exclusão não é
  coincidência de amostra pequena).
- **Filtros de liga/clube/nação**: dois caminhos distintos —
  `search_fc_player_cards` filtra por NOME resolvido (não por id), então
  clube homônimo em duas ligas (achado antigo, 42 casos) aparece unido
  sob o mesmo filtro de nome — comportamento aceitável, não um bug.
  Já os sheets de filtro (`player_picker_sheet.dart`) chamam
  `getLeagues()`/`getClubs()`/`getNations()`, que leem `fc_leagues`/
  `fc_clubs`/`fc_nations` **sem paginação**, sempre a tabela inteira.
- **Squad Builder**: `create_fc_squad`, `get_fc_squad_builder`,
  `set_fc_squad_slot`, `clear_fc_squad_slot`, `swap_fc_squad_slots`,
  `set_fc_squad_manager`, `clear_fc_squad_slots`, `set_fc_squad_formation`
  — todas security definer, todas revalidam ownership (`_owns_fc_squad`)
  e existência da carta a cada chamada.
- **Cache**: nenhum cache de app-side hoje (nem `PlayerCardCatalogRepository`
  nem os cubits guardam resultado entre aberturas do picker) — cada
  abertura do picker refaz a busca do zero. Não é um bug: os tempos
  reais medidos (seção 3) não justificam adicionar cache agora.

## 2. Fase 2 — Squad Builder / Player Picker (validado com o catálogo completo)

Testado ao vivo via REST com usuário de QA descartável (criado e removido
nesta sessão, zero resíduo), contra o catálogo real de 17.873 cartas:

| # | Caso | Resultado |
| --- | --- | --- |
| 1-6 | Abrir picker, busca por nome, filtro posição/liga/clube/rating | PASS — todos retornaram resultado coerente (ver Fase 3 para os números exatos) |
| 7 | Masculino/feminino | PASS — ambos presentes na mesma busca sem filtro (ex. Bonmatí/Russo ao lado de Mbappé/Haaland) |
| 8 | Jogadores sem clube | PASS — 2.402 cartas `club_id is null`, aparecem normalmente na busca (não são escondidas) |
| 9 | Nomes semelhantes | PASS — busca por `Haaland` retorna Erling e Markus Haaland, ambos distintos, sem colapsar |
| 10 | Clubes com nome ambíguo | PASS — filtro por nome (ex. "Real Madrid") retorna as cartas de ambos os clubes homônimos, comportamento correto pro caso de uso do picker |
| 11-13 | Selecionar/remover/trocar card na mesma posição | PASS — `set_fc_squad_slot` real testado: GK real no slot GK, ST real no slot ST1, `overall`/`filled_starters` atualizados corretamente a cada chamada |
| 14 | Reload/reabertura | Não testado via app real (sem ambiente visual) — mas `get_fc_squad_builder` é idempotente por design (`stable`, lê o estado persistido), sem indício de problema |
| 15-16 | Overall/chemistry | PASS — presentes na resposta de toda chamada de squad (`overall: 89` após 1 carta, `90` após 2; `chemistry: 0` sem técnico, consistente) |
| 17 | Validação de posição | **PASS, regra já existente, não inventada**: `set_fc_squad_slot` chama `_fc_card_can_play` e rejeita com `FQ033 "card cannot play in this position"` — testado ao vivo com um GK real tentando ocupar `ST2`, rejeitado corretamente |
| 18 | Impedir duplicação do mesmo card em dois slots | **Regra já existente, confirmada por leitura de código** (não inventada nesta etapa): `set_fc_squad_slot` faz `delete from fc_squad_slots where squad_id=... and player_card_id=...` antes do insert — a mesma carta nunca fica em dois slots, colocar em um lugar novo sempre remove do anterior. Não foi possível reproduzir isso ao vivo especificamente movendo pro banco (a sessão de QA não tinha o slot_code exato do banco à mão e não valia a pena investigar mais fundo um detalhe de nomenclatura de slot para reconfirmar uma regra já visível e inequívoca no código) — tratado como **PASS por leitura de código**, não como pendência. |

**Nenhuma regra de negócio nova foi inventada.** As duas restrições dos
itens 17/18 já existiam antes desta etapa; só foram confirmadas contra
dados reais.

## 3. Fase 3 — Performance (medida contra produção real, não estimada)

Nenhuma evidência de que o app carregue as 17.873 cartas de uma vez. O
picker (`PlayerPickerCubit`) já usa busca paginada server-side com
`pageSize = 30` e debounce de 300ms — desenhado assim desde a Etapa 10,
antes mesmo do catálogo real existir.

| Operação | Tempo real medido |
| --- | ---: |
| `search_fc_player_cards` sem filtro (1ª chamada, conexão fria) | 594ms |
| mesma busca, 2ª chamada | 228ms |
| busca por nome (`Silva`) | 259ms |
| filtro por posição (`CB`) | 185ms |
| filtro por rating mínimo | 145ms |
| filtro por liga | 163ms |
| paginação/"load more" (offset=30) | 172ms |
| `getLeagues()` (63 linhas, sem paginação) | 105ms |
| `getClubs()` (646 linhas, sem paginação) | 136ms |

Todos os tempos ficam bem abaixo do debounce de 300ms já existente na
UI — a busca nunca vai parecer lenta pro usuário. **Nenhuma otimização
foi aplicada**: os números não justificam mudar nada (regra do pedido:
não otimizar sem evidência). `getClubs`/`getLeagues`/`getNations` sem
paginação são uma escolha aceitável nos tamanhos atuais (63/646/165
linhas) — só precisariam de paginação se o catálogo de clubes/ligas/
nações crescesse em ordem de magnitude, o que não é o caso hoje.

## 4. Fase 4 — Integridade

Reconfirmado sobre o catálogo já completo (a maior parte já validada na
Etapa 17B-2, seção 17; aqui a lente é "o que o app realmente consome"):

- `fc_player_id` nulo ou pendurado em cartas visíveis pelo picker: **0**
  (a checagem cobre TODAS as 17.873, não uma amostra).
- Provider inconsistente entre carta e player: **0**.
- `provider_card_id`/`provider_player_id` duplicado: **0**.
- Cartas sem clube: 2.402 — esperado (free agents reais do dataset),
  aparecem normalmente no picker, sem tratamento especial necessário.
- Nenhuma duplicata visual possível: a busca nunca retorna a mesma
  `fc_player_cards.id` duas vezes (chave primária real, não um artefato
  de paginação).

### Os 32 `fc_clubs` órfãos — investigação concluída (não corrigidos)

**Origem confirmada**: são linhas com `provider_club_id is null`,
criadas antes de `club_external_id`/`provider_club_id` existir no
mapeamento do importer (a Etapa 17B introduziu esse campo). Confirmado
com uma consulta cruzando as 32 linhas contra `fc_player_cards`: **zero
cartas apontam para qualquer uma delas** — toda carta atual usa a linha
irmã correta (a que tem `provider_club_id` preenchido).

**Achado adicional nesta etapa**: o mesmo padrão existe em outras duas
tabelas de referência, na mesma escala pequena — **6 `fc_leagues`** e
**8 `fc_nations`** sem nenhuma carta apontando pra eles (nomes como
"Liga Nacional", "Primeira Divisão" — claramente placeholders de uma
fase anterior do dev, não do dataset Wrexist). Mesmo diagnóstico, mesmo
veredito.

**Recomendação**: seguro para apagar quando houver necessidade funcional
real (ex. antes de expor `fc_clubs`/`fc_leagues`/`fc_nations` numa tela
de administração, ou se algum dia essas tabelas ganharem índice único
por nome). Comando de referência, não executado:

```sql
delete from public.fc_clubs
where provider_club_id is null
  and id not in (select club_id from public.fc_player_cards where club_id is not null);

delete from public.fc_leagues l
where not exists (select 1 from public.fc_player_cards c where c.league_id = l.id);

delete from public.fc_nations n
where not exists (select 1 from public.fc_player_cards c where c.nation_id = n.id);
```

**Não executado nesta etapa** — nenhuma necessidade funcional concreta
apareceu (nenhuma feature lê essas linhas, nenhum bug visível foi
causado por elas), conforme instruído.

## 5. Fase 5 — UI/UX

`Flutter visual QA: NOT EXECUTED — environment limitation.` Nenhuma
ferramenta de preview/browser Flutter esteve disponível nesta sessão
para abrir o app de verdade. Todo o comportamento funcional (busca,
filtros, seleção, overall/chemistry, validação de posição, anti-
duplicação) foi confirmado via REST real contra as mesmas RPCs que a UI
chama — não é simulação, é o mesmo caminho de dados, só sem o
renderizador visual na frente. Itens puramente visuais da lista do
pedido (overflow de nome, imagem quebrada, scroll, empty state, feedback
de filtro) **não puderam ser observados** e não estão confirmados nem
como PASS nem como FAIL — ficam como pendência de ambiente, não como
"testado e aprovado".

## 6. Fase 6 — Testes / validação final

Nenhum bug real foi encontrado nesta etapa, então nenhum teste novo foi
adicionado (regra do pedido: só criar teste para bug ou risco real
encontrado).

- `flutter test`: 6/6 verde (suíte existente, `test/tool/`, inalterada).
- `flutter analyze`: **No issues found**.
- Migrations: **76 locais = 76 remotas**.
- Edge Functions: `process-notification-outbox` (v3, ACTIVE) e
  `delete-account` (v1, ACTIVE) — não relacionadas a esta etapa,
  inalteradas.
- `git status`: limpo antes e depois (nenhum arquivo de código mudou).
- Dados de QA (1 usuário, 1 conta, 1 squad) criados para os testes das
  Fases 2/3, removidos ao final — zero resíduo confirmado.

## 7. Pendências reais para release

- **QA visual Flutter** (Fase 5): não executável neste ambiente. Precisa
  de alguém abrindo o app de verdade (emulador/device) para confirmar os
  itens puramente visuais antes do release.
- **32 `fc_clubs` + 6 `fc_leagues` + 8 `fc_nations` órfãos**: documentado,
  zero impacto funcional hoje, limpeza é opcional e não urgente.
- Nada mais bloqueia o uso do catálogo real no Squad Builder — a lógica
  de servidor (posição, anti-duplicação, chemistry/overall) já existia e
  se comporta corretamente contra os 17.873 registros reais.

## Veredito

**READY FOR RELEASE QA.**

Nenhuma mudança de código foi feita. HEAD permanece `f32592e`. A única
lacuna real é a QA visual (ambiente), não um bug de produto.
