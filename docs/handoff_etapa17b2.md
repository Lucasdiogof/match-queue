# Handoff — Etapa 17B-2 (validação em escala intermediária do import FC27)

Status em 2026-09-09 (atualizado após a credencial ficar disponível):
**veredito READY FOR FULL IMPORT** (seção 16) — os degraus 500/2.000/5.000
rodaram de verdade contra o Supabase de produção via `tool/
sync_fc_cards.dart`, idempotência real confirmada nos três, validação
profunda no banco e QA REST real todas limpas. O full import dos ~17.873
**não foi executado**, por proibição explícita do pedido que motivou esta
retomada — aguarda autorização separada.

Histórico: esta etapa começou bloqueada por `SUPABASE_SECRET_KEY`/
`SUPABASE_SERVICE_ROLE_KEY` ausentes do ambiente (seções 1-14, veredito
original **B — NOT READY**). Tudo que não dependia de escrita real foi
executado até o fim naquele momento: auditoria completa do arquivo
inteiro (17.873 linhas), seleção determinística e dry-run limpo dos três
degraus, implementação e medição de batching no importer (double HTTP
local), e a suíte de testes automatizados (primeira do repositório). A
seção 15 documenta a retomada real; a seção 16 tem o veredito atual.

## 1. Baseline no início desta etapa

HEAD/`origin/main` em `48ca678`, 74/74 migrations locais = remotas,
`dart analyze tool lib` limpo, árvore limpa (exceto
`docs/final_data/_misplaced_review/`, intocada, não relacionada a esta
etapa). Dataset: `docs/final_data/data/wrexist_snapshot_normalized/
fc27_cards_normalized.csv`, provider `WREXIST_EA_FC27_SNAPSHOT`,
`game_version=FC27`. Amostra de 40 cartas já em produção desde a sessão
anterior (não tocada nesta etapa).

## 2. Auditoria completa do arquivo (17.873 linhas) — Parte 1

Script: `docs/final_data/scripts/audit_etapa17b2_full.py` (sem rede, sem
escrita). Números reais medidos:

| Métrica | Valor |
| --- | ---: |
| Total de linhas | 17.873 |
| `Men's Football` / `Women's Football` | 16.228 / 1.645 |
| `player_id` distintos (0 duplicado) | 17.873 |
| Nomes distintos (case-insensitive) | 17.732 |
| Nomes com 2+ linhas (homônimos reais, não bug) | 128 nomes / 269 linhas |
| Linhas que `--dry-run` rejeitaria | 0 |
| Cards que seriam produzidos | 17.873 |
| Clubes / ligas / nações distintos | 572 / 57 / 157 |
| **Clubes com o MESMO NOME em 2+ ligas distintas** | **42** |
| GK / linha | 2.014 / 15.859 |
| Rating min/max/média | 47 / 91 / 66,84 |
| Rating < 50 | 114 |
| Rating > 90 | 4 (Salah, Mbappé, Putellas, Bonmatí) |
| Sem `club` (free agent) | 2.402 |
| Sem `overall`/`position`/`league`/`nation`/`source_url` | 0 em todos |
| `provider_card_id` duplicado | 0 |
| `card_type` distintos | `BASE_LAUNCH` (100%) |

Distribuição de posição: `CB` 3.252, `ST` 2.476, `CM` 2.219, `GK` 2.014,
`RB` 1.394, `CDM` 1.376, `LB` 1.335, `CAM` 1.034, `LM` 1.058, `RM` 978,
`RW` 373, `LW` 364.

### Achado real confirmado em escala (era só 1 caso numa amostra de 40)

**42 clubes têm o mesmo nome em duas ligas diferentes** no arquivo inteiro
(times masculino/feminino homônimos: Arsenal, Real Madrid, FC Barcelona,
Bayern München, Juventus, etc. — lista completa no output do script de
auditoria). Isso **não quebra** o importer real da mesma forma que
quebrava o gerador de SQL de debug (que usava uma subquery que falhava com
"more than one row returned"): `tool/sync_fc_cards.dart` resolve clube por
nome via `GET ... &limit=1`, então nunca lança exceção. O problema real é
mais sutil e **silencioso**: `fc_clubs` não tem índice único por nome, e
`upsertByName` sempre reaproveita a PRIMEIRA linha que encontrar — então
para os 42 clubes homônimos, `fc_clubs.league_id` fica gravado com a liga
de QUALQUER QUE FOR PROCESSADA PRIMEIRO (não determinístico entre corridas,
depende da ordem de leitura do arquivo), e a segunda liga nunca ganha sua
própria linha de clube. Isso **não corrompe `fc_player_cards`** (cada carta
grava seu próprio `league_id` resolvido pela LIGA DA PRÓPRIA LINHA, não
pelo clube) — o dado que o picker mostra continua correto. O que fica
ambíguo é só `fc_clubs.league_id` para esses 42 nomes, uma coluna que hoje
não é lida por nenhuma feature do app (confirmar antes de usá-la em algo
novo). **Achado registrado, não corrigido**: corrigir exigiria decidir se
`fc_clubs` passa a ser único por `(name, league_id)` em vez de só `name`
— mudança de schema/design que cabe ao dono do produto decidir, não a este
automação sem indicação explícita de que é uma corrupção que bloqueia
alguma feature real hoje.

Coberto por teste automatizado (`test/tool/sync_fc_cards_dry_run_test.dart`,
primeiro caso) que documenta o comportamento observável em `--dry-run`
(clube homônimo colapsa para 1 distinto).

## 3. Degraus 500 / 2.000 / 5.000 — Parte 2

Seleção determinística: `docs/final_data/scripts/select_wrexist_sample_n.py`
— mesmo critério do `select_wrexist_sample.py` original (40 cartas):
ordenar por `player_id` numérico ascendente, amostragem sistemática com
stride fixo (`total // N`), nunca `random()`. Critério documentado no
próprio script ANTES de rodar.

| N | stride | gênero (M/F) | posições | ligas | clubes | nações | rating |
| --- | ---: | --- | ---: | ---: | ---: | ---: | --- |
| 500 | 35 | 453/47 | 12/12 | 52 | 310 | 81 | 47-90 |
| 2.000 | 8 | 1.839/161 | 12/12 | 55 | 541 | 120 | 47-91 |
| 5.000 | 3 | 4.625/375 | 12/12 | 57 | 570 | 128 | 47-91 |

Arquivos: `docs/final_data/data/wrexist_snapshot_normalized/
fc27_cards_sample{500,2000,5000}.csv` (versionados — dono do produto já
autorizou versionar todo dado deste projeto).

**Dry-run do importer real (`tool/sync_fc_cards.dart`) contra os três —
100% limpo nos três tamanhos:**

```
N=500:   lidos=500,   validos=500,   invalidos=0, cards=500,   players=500
N=2.000: lidos=2.000, validos=2.000, invalidos=0, cards=2.000, players=2.000
N=5.000: lidos=5.000, validos=5.000, invalidos=0, cards=5.000, players=5.000
```

Zero inválida, zero falha de parse, cobertura GK+linha e M+F confirmada
nos três.

**Import real (sem `--dry-run`) — BLOQUEADO nos três degraus.**
`SUPABASE_SECRET_KEY`/`SUPABASE_SERVICE_ROLE_KEY` ausentes do ambiente
desta sessão (confirmado: `echo $SUPABASE_SECRET_KEY` vazio). Sem
credencial, `tool/sync_fc_cards.dart` recusa rodar em modo de escrita —
comportamento correto do script, não um bug. **Consequência em cascata,
declarada explicitamente**: passos 4 (validação direto no banco), 5
(idempotência real, 2ª execução) e 6 (picker via REST contra dado novo)
do pedido original **não puderam ser executados para nenhum dos três
degraus** — não porque foram pulados, mas porque não há caminho de escrita
disponível nesta sessão. Isso é o blocker central desta etapa, igual ao
já registrado em `handoff_etapa17b.md` para a amostra de 40 (que usou o
caminho alternativo de SQL manual, autorizado explicitamente pelo dono do
produto naquela sessão — **essa mesma saída não foi usada aqui de
propósito**: o pedido desta etapa é explícito que o gerador de SQL nunca
substitui o importer real para os degraus 500/2.000/5.000).

## 4. Batch/chunk no importer real — Parte 3

### Auditoria do comportamento anterior

Antes desta etapa, `tool/sync_fc_cards.dart` fazia **1 request HTTP por
linha** para `fc_players` e `fc_player_cards`, mais até 3 requests extras
por linha para resolver clube/liga/nação por nome (`GET` sempre, mesmo
quando o nome já tinha sido resolvido antes na mesma execução — **sem
nenhum cache**). Para o catálogo completo (17.873 linhas, 572 clubes/57
ligas/157 nações distintos), isso significava dezenas de milhares de
requests redundantes.

### Mudanças implementadas

1. **Cache em memória por nome** (`_SupabaseAdmin._nameCache`, chave
   `table:name`) — elimina `GET`s repetidos para o mesmo clube/liga/nação
   dentro da mesma execução. Sem mudança de contrato de escrita.
2. **Upsert em lote** (`--batch-size=N`, default `500`) — `fc_players` e
   `fc_player_cards` agora são enviados em arrays (`POST` com
   `Prefer: resolution=merge-duplicates`) em vez de 1 request por linha.
   `fc_player_id` de cada carta é resolvido depois do POST em lote de
   `fc_players` retornar (`return=representation`), casando por
   `provider_player_id` — nunca por posição no array (seguro mesmo que o
   Postgres reordene a resposta).
3. **Dedup intra-lote por `provider_player_id`**: um `POST` em array com
   `ON CONFLICT` falha se a MESMA chave de conflito aparecer duas vezes no
   mesmo array (Postgres: *"ON CONFLICT DO UPDATE command cannot affect
   row a second time"*). O dataset atual tem 0 `player_id` duplicado
   (confirmado na auditoria), então isso não seria disparado por este
   arquivo — mas uma fonte futura com várias cartas por jogador (Gold/TOTW/
   Icon) poderia repetir o mesmo jogador dentro do mesmo lote. Corrigido
   deduplicando `chunkPlayerRows` por `provider_player_id` antes do POST
   (última ocorrência vence — mesmo dado em todo caso neste dataset).
   Sem `--full-catalog`, comportamento de desativação preservado
   inalterado.
4. Removidos `upsertFcPlayer`/`upsert` (as versões antigas de 1
   linha/request), agora mortos — o único caminho de escrita é
   `upsertBatch`.

`dart analyze tool lib test` limpo depois de todas as mudanças. Dry-run
dos três degraus (500/2.000/5.000) re-executado depois da mudança —
resultado idêntico ao antes (batching só afeta o modo de escrita; dry-run
nunca toca rede).

### Medição real de 2 tamanhos de batch (100 vs 500), contra um double local

Como não há credencial real para medir contra o Supabase de verdade,
implementei `tool/perf/measure_batch_size.dart`: um servidor HTTP local
(`HttpServer.bind(loopback)`) que imita o contrato mínimo do PostgREST
(GET por nome, POST em array com `Prefer: return=representation`), sem
nenhuma rede externa nem credencial real (`SUPABASE_SECRET_KEY` fake só
para o `_SupabaseAdmin` aceitar rodar em modo escrita contra o double).
Mede **contagem real de requests HTTP** emitidos pelo importer real, não
uma simulação separada da lógica de produção.

| N | batch=1 (requests / ms) | batch=100 (requests / ms) | batch=500 (requests / ms) |
| --- | ---: | ---: | ---: |
| 500 | 1.025 / 1.627 | 35 / 1.194 | 27 / 1.150 |
| 2.000 | 4.025 / 3.385 | 65 / 1.580 | 33 / 1.490 |
| 5.000 | 10.025 / 5.017 | 125 / 1.570 | 45 / 1.355 |

**Contagem de requests cai de ~2N+1 (sem lote) para uma constante pequena**
(cresce só com o número de clubes/ligas/nações NOVOS, não com N) a partir
de batch=100, e cai ainda mais em batch=500. **Ressalva honesta sobre o
tempo em ms**: essas medições são contra `loopback` (latência ~0), então
não são um proxy real de throughput contra o Supabase de produção (que
tem 50-150ms de round-trip típico) — o benefício real do batching em
produção é MAIOR do que essas 1-5 segundos sugerem, porque cada request
eliminado economiza um round-trip de rede real, não só overhead de
processo local. Escolhi manter o default em **500** porque (a) é
estritamente melhor que 100 em número de requests nos três tamanhos
medidos, (b) não há nenhum limite de payload do PostgREST sendo
disputado nesse tamanho de lote para as colunas deste schema, e (c) um
lote maior significa menos "pontos de retomada" em caso de falha de rede
no meio do full import — troca aceita, documentada, não arbitrária.
`--batch-size=N` continua exposto na CLI para o dono do produto ajustar
se quiser, sem precisar de nova mudança de código.

### Teste de batching contra rede real de verdade: BLOQUEADO por ambiente (achado extra, distinto da credencial)

Uma versão desse mesmo harness rodando **dentro do test runner do Flutter**
(`flutter test`, subprocesso `Process.run` filho comunicando por loopback
com um `HttpServer` no processo pai) falhou consistentemente com
`SocketException errno=10057` ("socket não conectado") neste ambiente
Windows, mesmo com sandbox desabilitado. Rodando o MESMO código como um
script Dart direto (`dart run tool/perf/measure_batch_size.dart`, sem
passar pelo test runner do Flutter) funcionou sem problema. **Isso é uma
segunda limitação de ambiente, independente da ausência de
`SUPABASE_SECRET_KEY`**: um teste automatizado de batching via loopback
dentro de `flutter test`/`package:test` não é confiável nesta máquina —
por isso o teste ficou como script standalone (`tool/perf/
measure_batch_size.dart`), não como parte da suíte de testes automatizados
formal (`test/`). Documentado para não ser confundido com bug de lógica.

## 5. Relações e dedup (Parte 4)

- `fc_players`: sem duplicidade indevida no dataset (0 `player_id`
  duplicado); `provider_player_id` = `player_id` da fonte, confirmado
  100% coerente na auditoria original (Etapa 17B) e reconfirmado nos três
  degraus via dry-run (players distintos == cards em todos).
- `fc_player_cards`: `fc_player_id` resolvido no flush do lote (ver seção
  4); nenhuma carta `LOCAL` entra neste import — `--provider` é sempre
  `WREXIST_EA_FC27_SNAPSHOT`, nunca `LOCAL`, em todos os comandos rodados
  nesta etapa.
- Clubes: achado dos 42 homônimos coberto na seção 2 — regra de resolução
  por nome **não foi alterada** (decisão do dono do produto pendente,
  não é corrupção que bloqueia o app hoje).

## 6. Idempotência (Parte 5)

**Não pôde ser testada em produção** nesta etapa (nenhuma escrita real
aconteceu, ver seção 3). O que FOI validado, com escrita real contra o
double local (`tool/perf/measure_batch_size.dart` e a suíte de testes):
reimportar o mesmo lote duas vezes contra o double NÃO duplica
clube/liga/nação por nome (o cache + `upsertByName` continuam resolvendo
pela linha já existente na segunda chamada). Isso valida a LÓGICA de
idempotência do código, mas não é o mesmo que confirmar contra o schema e
os índices únicos reais do Supabase de produção — essa confirmação real
segue pendente do mesmo blocker de credencial.

## 7. Picker via REST (Parte 6)

**BLOQUEADO** — depende de dado novo escrito em produção (degraus
500/2.000/5.000), que não aconteceu nesta etapa. A validação REST contra
as 40 cartas já existentes (feita na sessão anterior, `handoff_etapa17b.md`)
continua válida para aquele dado, mas não foi refeita aqui porque nada
novo foi escrito para validar.

## 8. Flutter (Parte 7)

**Flutter visual QA: NOT EXECUTED — environment limitation.** Nenhuma
ferramenta de preview/browser rodando um Flutter real esteve disponível
nesta sessão para abrir o app e navegar no picker. Nenhum teste de widget
foi usado como substituto de confirmação visual.

## 9. Testes automatizados (Parte 8)

Confirmado antes de decidir onde colocar: **este repositório não tinha
nenhuma suíte de teste antes desta etapa** (`test/` não existia). Nível
escolhido: Dart puro via `flutter_test` (já é dev dependency do projeto;
não há pacote `test` standalone declarado), rodando `tool/sync_fc_cards.dart`
via subprocesso em `--dry-run` contra fixtures JSON temporárias — mais
fiel ao comportamento real do script do que extrair funções privadas para
testar em isolamento, e não exige nenhuma credencial.

**6 testes** em `test/tool/sync_fc_cards_dry_run_test.dart`, todos verdes
(`flutter test test/tool` — 6/6 passam):

1. Clube com o mesmo nome em duas ligas conta como 1 distinto no dry-run
   (documenta o achado da seção 2).
2. `gk_speed` ausente em todas as linhas de goleiro não invalida a carta.
3. Linha com identidade de jogador + carta resolve `fc_player_id`
   (players == cards, player-only == 0).
4. Linha sem `provider_card_id` nem `provider_player_id` é inválida
   (nunca inventa id sintético).
5. Male e female coexistem na mesma rodada sem se afetarem.
6. Reimport do mesmo arquivo produz exatamente o mesmo resultado de
   parsing (determinismo do dry-run).

**Não incluído na suíte formal** (ver seção 4): o teste de contagem de
requests HTTP por tamanho de lote — falha de ambiente (loopback dentro do
test runner), não de lógica — ficou como script standalone
`tool/perf/measure_batch_size.dart`, rodável fora do `flutter test`.

**Não testável sem credencial real** (fica pendente, não fingido):
reimport não duplica em produção (índices únicos reais), filtros críticos
do picker via RPC real.

## 10. Segurança (Parte 9)

RLS não foi tocada nesta etapa. Nenhuma secret foi impressa, logada,
commitada ou hardcoded em nenhum arquivo — todo comando que precisaria da
secret real foi bloqueado antes de qualquer tentativa de uso. As duas
policies `is_active = true` de `fc_players`/`fc_player_cards` (corrigidas
na Etapa 17B original) não foram alteradas. Nenhuma carta com
`provider=LOCAL` foi tocada por nenhum comando desta etapa.

## 11. Performance (Parte 10)

| Escala | Dry-run | Import 1 | Import 2 | Inserts | Updates | Skips | Errors | Reg/s |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 500 | OK, 500/500 válidas | **BLOQUEADO** (sem credencial) | BLOQUEADO | — | — | — | — | — |
| 2.000 | OK, 2.000/2.000 válidas | BLOQUEADO | BLOQUEADO | — | — | — | — | — |
| 5.000 | OK, 5.000/5.000 válidas | BLOQUEADO | BLOQUEADO | — | — | — | — | — |
| 17.873 (full) | OK, 17.873/17.873 válidas (Etapa 17B) | não autorizado ainda | — | — | — | — | — | — |

Dry-run puro (parse-only, sem rede) é rápido em todos os tamanhos: ~1,0-1,2s
para 500/2.000/5.000, ~1,4s para o arquivo inteiro (17.873 linhas) — não é
o gargalo. **O gargalo real é a escrita de rede**: com o design antigo (1
request/linha), o full import faria ~35.746+ requests sequenciais só para
`fc_players`+`fc_player_cards`, mais requests de clube/liga/nação; com
batch=500 e o cache de nomes, esse número cai para uma fração pequena
(extrapolando a tabela da seção 4, a ordem de grandeza para 17.873 linhas
com batch=500 seria dezenas de requests, não dezenas de milhares). **Essa
extrapolação é baseada em medição real contra um double local, não em
suposição teórica pura** — mas o número final contra o Supabase de
produção real (latência de rede real, não loopback) **não foi medido**
nesta etapa, porque não há credencial para medir contra o ambiente real.
Maior risco para o full import: nenhuma medição contra o Supabase real
ainda existe — a extrapolação da seção 4 é a melhor evidência disponível,
mas o número final de duração real só será conhecido rodando de verdade.

## 12. Cleanup (Parte 11)

Nenhuma tentativa quebrada ficou no banco (nenhuma escrita real foi
tentada). Dados corretos já em produção (amostra de 40 antiga) não foram
tocados. Nenhum usuário de QA foi criado nesta etapa (não chegou a essa
parte). Arquivos temporários: o harness de medição
(`tool/perf/measure_batch_size.dart`) foi promovido de rascunho
(`.scratch_perf/`, removido) para ferramenta versionada com propósito
documentado; os três CSVs de amostra (500/2.000/5.000) e os dois scripts
de auditoria/seleção novos (`audit_etapa17b2_full.py`,
`select_wrexist_sample_n.py`) ficam versionados — dado de projeto de
resenha, já autorizado pelo dono do produto a versionar por inteiro.

## 13. Estimativa para o full import (17.873 registros)

Com o design ANTIGO (1 request/linha): impraticável de estimar com
confiança sem medição real contra produção, mas a ordem de grandeza seria
de dezenas de milhares de requests sequenciais — risco real de timeout/
rate-limit do Supabase, e de o processo levar dezenas de minutos a horas
dependendo da latência de rede real.

Com o design NOVO (cache de nomes + batch=500): a extrapolação da tabela
da seção 4 sugere uma fração pequena de requests (formato aproximado:
~2 × (17.873/500) + clubes/ligas/nações novos ≈ 70-150 requests totais),
o que tornaria o full import rápido mesmo contra latência de rede real
(segundos a poucos minutos, não horas) — **mas isso é extrapolação, não
medição direta contra produção**, e deve ser tratado como estimativa, não
garantia, até um degrau real rodar com credencial disponível.

## 15. Retomada 2026-09-09 — credencial disponibilizada, degraus reais executados

`SUPABASE_SECRET_KEY` ficou disponível no ambiente. Antes de rodar qualquer
coisa, o baseline do banco já mostrava **6.713 cartas `WREXIST_EA_FC27_SNAPSHOT`**
— comparação exata (id a id) confirmou que esse número bate **perfeitamente**
com a união dos quatro conjuntos (`sample40 ∪ sample500 ∪ sample2000 ∪
sample5000` = 6.713, zero diferença nos dois sentidos). Ou seja: **os
degraus 500/2.000/5.000 já tinham sido executados de verdade contra
produção antes desta sessão começar a medir** (fora desta sessão, sem
commit de código associado — rodar o importer não muda arquivo nenhum).
Não houve como capturar a duração/contagem da PRIMEIRA execução real —
registrado como limitação, não inventado.

### O que esta sessão mediu de verdade

Para não aceitar "já está lá" como prova de nada, rodei os três degraus
**de novo**, com `tool/sync_fc_cards.dart` real, cronometrando cada um.
Isso serve dois propósitos ao mesmo tempo: confirma idempotência real
E dá uma medição de performance genuína contra o Supabase de produção,
já que o custo de rede de uma linha é o mesmo seja ela INSERT ou UPDATE.

| N | resultado | inseridos | atualizados | falhas | duração real | reg/s |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 500 | limpo | 0 | 500 | 0 | 25,78s | 19,4 |
| 2.000 | limpo | 0 | 2.000 | 0 | 42,27s | 47,3 |
| 5.000 | limpo | 0 | 5.000 | 0 | 43,13s | 116,0 |

Nenhum erro HTTP, nenhum timeout, nenhum rate-limit, nenhum retry
disparado em nenhum dos três. Throughput cresce com N porque o custo fixo
(resolver nomes de clube/liga/nação novos, aquecer o cache) se dilui —
em 5.000 registros já são tocados 570 dos 572 clubes distintos do arquivo
inteiro, então o cache já está quase saturado antes do fim.

### Validação profunda pós-import (SQL direto, não REST)

| Checagem | Resultado |
| --- | --- |
| Total `WREXIST_EA_FC27_SNAPSHOT` em `fc_player_cards` | 6.713 (== união esperada) |
| `fc_players` provider `WREXIST_EA_FC27_SNAPSHOT` | 6.713 (1:1 com as cartas) |
| Cartas com `fc_player_id` nulo | 0 |
| Cartas com `fc_player_id` "pendurado" (sem player correspondente) | 0 |
| Cartas cujo player tem provider diferente da carta | 0 |
| `provider_card_id` duplicado | 0 |
| `game_version` fora de `FC27` | 0 |
| Cartas `is_active = false` | 0 (nenhuma desativação rodou, sem `--full-catalog`) |
| Cartas sem clube (free agent) | 926 — esperado, não é bug (dataset inteiro tem 2.402 sem clube) |
| Cartas sem liga/nação/rating | 0 / 0 / 0 |
| GK sem `gk_speed` | 770/770 (100%) — comportamento já documentado (fonte não traz esse campo; a correção antiga evitou crash, nunca inventou valor) |
| Cartas `LOCAL` (tabela inteira) | 50 — inalteradas, conjunto disjunto do `WREXIST` |

### QA REST real (usuário temporário, limpo ao final)

Criado `qa17b2-fc27@fifaqueue.test` via `/auth/v1/signup`, chamado
`search_fc_player_cards` via REST com o token real, depois `delete from
auth.users` (cascata limpou profile). Resíduo pós-limpeza: **0** em
`auth.users` e `profiles`.

| Teste | Resultado |
| --- | --- |
| Busca sem filtro (ordenado por rating desc) | ok — Bonmatí/Mbappé (91) no topo, ordem correta |
| Busca por nome (`Mbapp`) | 1 resultado |
| Filtro por posição (`GK`) | 10/10 resultados são `GK` |
| `p_min_rating=85` | 50 resultados, mínimo real = 85 |
| `p_max_rating=50` | 50 resultados, máximo real = 50 |
| Filtro por liga (`Premier League`) | 50 resultados (capado pelo limite pedido) |
| Filtro por clube (`Arsenal`) | 20 resultados |
| Filtro por nação (`Brazil`) | 50 resultados |
| Paginação (`offset=0` vs `offset=10`) | 0 sobreposição de ids entre páginas |
| Masculino e feminino | ambos aparecem sem filtro nenhum (Bonmatí/Russo junto com Mbappé/Haaland) |
| Provider vazando | **zero** `LOCAL` nas amostras lidas via RPC (a prova definitiva é estrutural: os 50 `LOCAL` e as 6.713 `WREXIST` são conjuntos disjuntos, confirmado por SQL direto — a amostra via REST é so confirmação adicional, limitada a 100 linhas por chamada por causa do teto do próprio RPC, `least(p_limit, 100)`) |

Nenhum usuário/dado de QA ficou para trás.

### Flutter

`Flutter visual QA: NOT EXECUTED — environment limitation.` (sem mudança
desde a rodada anterior; REST real cobriu a validação funcional pedida
nesta retomada.)

### Nada no importer foi alterado

Nenhum bug real foi encontrado nesta retomada — os três degraus e as duas
execuções (a que já existia + a que rodei agora) se comportaram
exatamente como o dry-run e a auditoria já previam. `tool/sync_fc_cards.dart`
continua sem mudança de código desde a seção 4. `flutter analyze`,
`dart format tool lib test` e `flutter test test/tool` (6/6) seguem
limpos.

### Estimativa revisada para o full import (17.873), agora com medição real

Com os números reais de 5.000 (116 reg/s, já com a maior parte do cache
de clube/liga/nação aquecida): extrapolação simples dá **~17.873/116 ≈
154s (~2,5 min)**. Essa extrapolação tende a ser **pessimista**: aos
5.000 registros o dataset já expôs 570 dos 572 clubes distintos, 57/57
ligas e 128/157 nações do arquivo inteiro — a maior parte do custo de
"nome novo, sem cache" já foi paga; os ~12.873 registros restantes devem
bater cache com mais frequência, então o full import real tende a rodar
em menos de 154s, não mais. Ainda é extrapolação, não medição do full
import em si — mas agora apoiada em três pontos de dado reais contra
produção, não só um double local.

## 14. Veredito (histórico desta seção, mantido — ver seção 16 para o veredito atual)

**B — NOT READY FOR FULL IMPORT** *(válido no momento em que foi escrito;
revisto na seção 16 abaixo, após a credencial ficar disponível)*.

**Blocker exato**: `SUPABASE_SECRET_KEY` (ou o fallback legado
`SUPABASE_SERVICE_ROLE_KEY`) precisa estar no ambiente (Project Settings
-> API keys -> secret key no painel do Supabase) para `tool/
sync_fc_cards.dart` rodar em modo de escrita. Sem isso, nenhum dos três
degraus (500/2.000/5.000) pôde escrever de verdade em produção — e sem
escrita real, idempotência real, validação direto no banco e picker REST
contra dado novo não puderam ser confirmados, mesmo com auditoria,
dry-run e batching todos limpos e prontos.

**O que já está pronto para quando a credencial existir** (não precisa
refazer): auditoria completa do arquivo (17.873/17.873 válidas), seleção
determinística e dry-run limpo dos três degraus, batching implementado e
com número de requests medido contra um double local (não arbitrário),
42 clubes homônimos documentados como achado (não bloqueante), suíte de
testes automatizados nova (6/6 verde), zero regressão em `dart analyze`/
`flutter analyze`.

**Próximo passo, quando a credencial existir**: rodar
`dart run tool/sync_fc_cards.dart --file=docs/final_data/data/
wrexist_snapshot_normalized/fc27_cards_sample500.csv --map=docs/
final_data/schema/wrexist_ea_cards_map.json
--provider=WREXIST_EA_FC27_SNAPSHOT --game-version=FC27` (sem
`--dry-run`), validar direto no banco, rodar de novo para confirmar
idempotência real, só então subir para 2.000 e 5.000 na mesma ordem, e só
então pedir autorização explícita para o full import dos ~17.873.

*(Este passo já foi executado — ver seção 15/16.)*

## 16. Veredito atual (2026-09-09, pós-retomada com credencial disponível)

**READY FOR FULL IMPORT.**

Todos os critérios foram atendidos com o importer real, contra produção:

- os três degraus (500/2.000/5.000) existem em produção, confirmados por
  comparação exata id-a-id (não estimativa);
- idempotência real confirmada nos três (reimportados nesta sessão: 0
  inserido, 100% atualizado, 0 falha, em todos);
- performance real medida contra o Supabase de produção (não só double
  local): 19–116 registros/s, crescente com N, sem erro/timeout/retry;
- zero corrupção estrutural: `fc_player_id` sempre resolvido, zero FK
  pendurada, zero provider incoerente, zero `provider_card_id` duplicado;
- provider correto (`WREXIST_EA_FC27_SNAPSHOT`) em 100% das linhas;
- zero carta `LOCAL` misturada (conjuntos disjuntos, confirmado por SQL
  direto sobre a tabela inteira, não amostra);
- QA REST real passou (busca livre, nome, posição, rating min/max, liga,
  clube, nação, paginação sem sobreposição, masculino e feminino
  coexistindo, sem vazamento de provider) com usuário temporário limpo ao
  final, zero resíduo.

**Não bloqueante, documentado**: a duração da PRIMEIRA execução real dos
três degraus não foi capturada por esta sessão (já estava feita quando a
sessão começou a medir o baseline) — os números de performance acima vêm
da segunda execução (idempotente), que é uma medição igualmente válida de
custo de rede real, já que o importer faz o mesmo trabalho de rede numa
linha seja ela INSERT ou UPDATE.

**Import completo dos ~17.873 registros NÃO foi executado nesta tarefa**,
por proibição explícita do pedido. Aguardando autorização separada do
dono do produto.
