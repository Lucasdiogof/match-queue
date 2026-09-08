# Handoff — Etapa 13 (Squad Builder 2.0)

Status em 2026-09-08: **fechada**. Backend aplicado (62 migrations no
remoto), Flutter completo, `flutter analyze` limpo, tudo commitado e pushado
em `origin/main`.

Nada aqui depende do catálogo FC27: funciona com as 50 cartas `LOCAL` de dev,
com catálogo vazio em produção e com o catálogo real quando ele chegar.

## Banco

| Migration | O que traz |
| --- | --- |
| `20260921100000_fc_squad_chemistry_and_reserves.sql` | overall, química, reservas (5), "limpar escalação" |
| `20260922100000_fc_squad_chemistry_breakdown.sql` | breakdown da química por fonte |
| `20260922100100_fc_chemistry_manager_name_fallback.sql` | 1ª tentativa de ligar técnico a catálogo por nome |
| `20260922100200_fc_chemistry_manager_match_fix.sql` | correção definitiva do vínculo do técnico |
| `20260922100300_snapshot_overall_chemistry.sql` | snapshot passa a congelar overall/química |

Todas aditivas: `get_fc_squad_builder` e `list_fc_squads` mantiveram
assinatura e só ganharam chaves. Nenhuma migration aplicada foi editada.

**Nota sobre 100100 → 100200.** A 100100 tentou resolver o vínculo do técnico
com uma chave única `coalesce(id, nome)` dos dois lados. Não funciona: o
técnico vem de `fc_nations`/`fc_leagues` e sempre tem id, enquanto uma carta
importada por CSV só tem nome — as chaves caem em dimensões diferentes e
nunca casam. A 100200 compara nas duas dimensões independentes. As duas estão
no histórico porque a 100100 já tinha sido aplicada; a 100200 é a que vale.

## Chemistry

**Regra: `FC_MODERN_V1`**, exposta por `public._fc_chemistry_rule_version()`.
Pesquisada, não inventada — sistema simplificado introduzido no FIFA 23 e
mantido em FC24/FC25 (fifauteam, estnn). Não há documentação FC27 confiável
hoje; por isso a regra é versionada e o algoritmo isolado em
`_fc_squad_chemistry`, trocável sem mexer em quem consome.

- Só **titulares** pontuam. Banco e reservas nunca entram — verificado.
- **Fora de posição** (nem primária nem alternativa bate com o slot): química
  0 **e** não conta para o vínculo de mais ninguém.
- Limiares, entre titulares na posição:
  - clube: 2 → +1, 4 → +2, 7 → +3
  - liga: 3 → +1, 5 → +2, 8 → +3
  - nação: 2 → +1, 5 → +2, 8 → +3
- **Técnico**: +1 se o titular compartilha nação **ou** liga com o squad —
  capado em +1 mesmo batendo os dois. O vínculo casa por id **ou** por nome,
  para funcionar com catálogo importado sem ids.
- Soma dos quatro, capada em 3 por jogador. Total 0–33.

Química é **derivada**, nunca persistida como valor editável — exceto
congelada no snapshot de uma partida, que é história e não estado.

O read model devolve, por titular: `chemistry`, `position_eligible` e
`chemistry_sources` (pontos por fonte, contagens por vínculo, e se a soma foi
capada). O Flutter só renderiza; os limiares nunca saem do backend.

**Ainda não implementado, por decisão:** Icons/Heroes (contam para qualquer
liga/nação no jogo real). A estrutura está pronta — é uma exceção por carta
dentro de `_fc_squad_chemistry`.

## Squad Builder

- **Drag & drop** para slot vazio, sobre jogador, titular ↔ titular, banco ↔
  campo. **Tap continua funcionando** e não virou caminho secundário — drag é
  adição, não substituição (item 63).
- **Swap é atômico**: uma única chamada a `swap_fc_squad_slots`, nunca
  clear+set+set.
- **Persistência por ação**, com "Salvando…/✓ Salvo" no header. Falha
  recarrega o estado autoritativo em vez de deixar a tela mentindo.
- **Banco** 7 + **reservas** 5 (11+7+5 = 23). O 5 é número de produto: a
  pesquisa não achou limite oficial público de UT para replicar.
- **Troca de formação** preservou o remap lossless das etapas anteriores e
  agora avisa antes de reposicionar.
- **Limpar escalação** apaga só os slots, com confirmação — nunca o squad.

## Picker

Contextual ao slot: conhece posição do slot, primária e alternativas.
Resultados priorizam compatíveis sem esconder o resto, badge mostra as
posições que a carta aceita, e o filtro **Compatíveis** restringe a quem
realmente joga ali. Catálogo vazio devolve estado vazio, nunca erro técnico.

## Card UI

Card do campo mostra rating, posição, nome, química individual e marca fora
de posição. Sem imagem, cai num fallback próprio — nada de arte oficial
inventada. O detail sheet exibe só os campos que existem; quando o dataset
real chegar com PlayStyles, roles, pé preferido e afins, eles aparecem
sozinhos.

## Conta / Jogar

A Conta lidera com **Escalação Principal** (nome, formação, OVR, química,
quantos titulares faltam) e uma ação Editar/Montar. Squads extras ficam atrás
de uma ação secundária — a tela é da conta, não um gerenciador de squads. O
Jogar mostra o mesmo resumo, trocando o OVR pela contagem enquanto a
escalação está incompleta.

**Matchmaking nunca é bloqueado** por escalação incompleta, química baixa ou
falta de técnico.

## Compatibility

- **Snapshots**: `squad_overall`, `squad_chemistry` e
  `chemistry_rule_version` entram **só nos novos**. Partida antiga não tem as
  chaves e quem lê trata a ausência. Confirmado imutável: editar o squad
  depois da partida não altera o snapshot.
- **Etapa 12** (gols, assistências, stats, WL/Rivals) não foi tocada.
- **Catálogo vazio** não quebra nada.
- Cartas `LOCAL` seguem só no caminho de dev.
- `game_matches` continua fechada a select direto (RLS) — o snapshot chega ao
  app pelas RPCs, nunca por leitura direta.

## Validação

Feita pontualmente, como manda a regra de execução:

- 26 checagens de química/overall: total sempre 0–33, por jogador 0–3, soma
  por jogador == total, breakdown (capado) == número mostrado, banco e reserva
  sem efeito, fora de posição zerado, overall = média dos titulares, squad
  vazio com overall `null`.
- 7 checagens focadas no técnico: +1 por jogador, cap respeitado, remover o
  técnico desfaz o bônus.
- Swap: troca correta, persiste no banco relendo, campo↔banco, nada perdido.
- Snapshot: gravado com os três campos novos e imutável após edição.
- Dados de QA removidos: 0 usuários, 0 squads, 0 partidas, catálogo dev
  intacto (50 cartas).

## Git

```
bf1c724  Lead with one main lineup on the account and in Jogar
c0762ac  Show why each starter has the chemistry it has
a7a4cf0  Explain each starter's chemistry and fix the manager link
22b6388  Show squad overall/chemistry, add drag and drop, reserves and card details
5338c82  Compute squad overall and chemistry server-side, add reserve slots
```

## Pendências

Adiadas conscientemente:

- **Icons/Heroes** na química (estrutura pronta, exceção não escrita).
- **PlayStyle+ vs PlayStyle** separados — só quando o provider informar.
- **Roles** não influenciam lógica de formação.
- **"Outras versões"** no detail sheet: `PlayerCard.player` existe, a query
  não foi escrita (item 58 pedia só preparar).
- **Histórico** não exibe OVR/química da partida ainda; o snapshot já carrega.
- **Catálogo FC27** continua fora — WeFUT/FUTBIN/FUT.GG/FUTWIZ/SoFIFA seguem
  recusados (ver `docs/card_provider_research.md`).
- Revisão linguística PT/EN/ES, QA visual, testes automatizados e hardening
  seguem para a etapa final.

## Não esquecer

- `dart format .` quebra neste repo; usar `dart format lib`.
- Commits em inglês, imperativos, sem prefixo `feat:`/`fix:`.
- Sempre caminhos explícitos, nunca `git add -A`.
- `gen-l10n` respeita a ordem de `@placeholders`; conferir a assinatura
  gerada antes de chamar.
- Matchmaking mudou de assinatura na Etapa 12: `request_match_search`
  (`p_fc_account_id`, `p_fc_squad_id`, `p_game_mode`) e
  `report_match_found_and_start_game(p_fc_account_id)` — **sem `p_team_id`**.
