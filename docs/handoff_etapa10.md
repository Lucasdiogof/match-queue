# Handoff — Etapa 10 (Squad Builder)

Status em 2026-09-08: **Etapa 10 funcionalmente fechada.** Backend aplicado
(52 migrations no remoto), camada Flutter completa, `flutter analyze` limpo,
tudo commitado e pushado em `origin/main`.

Vale como registro de continuidade — anotação local não atravessa
troca de conta nem de máquina, este arquivo sim.

## Modelo

```
Usuário
└── FcAccount (Elenco: "Lucksrei")     user_fc_accounts
    └── FcSquad (Escalação: "Principal")   fc_squads
        ├── formação           fc_formations / fc_formation_slots
        ├── slots preenchidos  fc_squad_slots
        └── técnico + liga     fc_managers / fc_leagues
```

`FcAccount` continua sendo a CONTA e não foi renomeado. A formação pertence
ao squad, nunca ao elenco.

## Decisões que valem lembrar

- **Catálogo de formações no banco, não em Dart.** 29 formações, 319 slots.
  Corrigir uma coordenada ou adicionar formação da FC 27 é update de linha,
  não release de loja. As RPCs validam contra essas tabelas, então o client
  nunca inventa slot.
- **Só slots PREENCHIDOS viram linha.** Slot vazio é ausência de linha; a
  grade de 11 vem do catálogo no read model. Evita 18 linhas por squad para
  manter sincronizadas e torna a troca de formação um remapeamento pequeno.
- **Troca de formação é lossless por construção.** Quatro passadas: mesmo
  slot_code → mesma posição → slot elegível mais próximo → slot livre mais
  próximo ignorando elegibilidade. Como toda formação tem 11 titulares, a
  última passada sempre acha vaga. Preferimos jogador visivelmente fora de
  posição a jogador sumindo em silêncio. Validado indo e voltando entre
  linhas de 3, 4 e 5 defensores sem perder nenhuma das 18 cartas.
- **Snapshot server-side, imutável.** `game_matches.squad_snapshot` (jsonb) é
  escrito no nascimento da partida a partir do estado persistido — o Flutter
  não envia escalação. Guarda id + nome + rating + posição de cada carta, para
  o histórico continuar legível mesmo se a Etapa 11 reimportar o catálogo e
  trocar ids. Validado: editar o squad depois não muda a partida.
- **Squad é pessoal.** RLS por dono do elenco. Nem companheiro de time nem
  admin do time enxergam. Confirmado com dois usuários e com `anon`.
- **Squad é opcional.** `fc_squad_id` nullable em sessão, fila e partida.
  Buscar sem squad continua funcionando; partidas antigas ficam com null e
  não há backfill.
- **`account_squad_id` foi removido** de `game_matches`. Era o gancho criado
  na Etapa 8.5 para este momento, nunca foi escrito por nenhum caminho de
  código (sempre null), e manter dois nomes parecidos convidaria a bug.

## Códigos de erro novos

FQ029 squad inexistente/de outro usuário · FQ030 nome inválido · FQ031
formação inválida · FQ032 slot inválido · FQ033 carta não joga na posição ·
FQ034 squad em uso numa busca ativa. **FQ014 continua livre.**

## Dados de desenvolvimento

`20260917100500_seed_dev_card_catalog.sql` insere 50 cartas, 24 técnicos, 10
nações e 6 ligas com `provider = 'LOCAL'` e nomes de jogador/técnico
inventados. Não são cartas oficiais e a UI diz isso no picker. Limpar na
Etapa 11 é `delete from public.fc_player_cards where provider = 'LOCAL'` (e
equivalentes).

## O contrato da Etapa 11

Basta uma implementação de `PlayerCardCatalogRepository` que cumpra:

```dart
searchCards(PlayerCardQuery)  getCard(id)
searchManagers({nationId, query})  getNations()  getLeagues()
```

`PlayerCardQuery` já declara rating/liga/clube/nação/versão mesmo que hoje só
`query`/`position`/paginação sejam usados — para a assinatura (e a UI) não
mudarem depois. Nada acima do repositório sabe de onde vieram os dados.

## Pendências conscientes

- **Química, PlayStyles, preço e overall do squad**: fora de escopo.
- **Reservas** (os 5 além do banco de 7): só titulares + banco na V1.
- **Drag-and-drop**: tap-to-swap resolve no mobile; drag ficou como bônus não
  implementado.
- **Gols/assistências por jogador**: o snapshot já viabiliza, mas é etapa
  futura.
- **Compartilhar squad** entre usuários: não implementado.
- **`weekend_league_event_model.dart`** segue órfão desde a Etapa 9 —
  candidato à faxina final.
- **Revisão de traduções, QA visual, testes automatizados e hardening**:
  concentrados na etapa final, conforme a regra de execução atual.

## Coisas específicas pra não esquecer

- `dart format .` quebra neste repo; usar `dart format lib`.
- Mensagens de commit são em INGLÊS, imperativas, sem prefixo `feat:`/`fix:`.
- `.agents/` e `skills-lock.json` são tooling untracked e **nunca** entram em
  commit — sempre commitar com caminhos explícitos, nunca `git add -A`.
- `gen-l10n` gera parâmetros na ordem declarada em `@placeholders`. Já
  causou bug de troca silenciosa aqui: conferir a assinatura gerada antes de
  chamar (aconteceu de novo com `squadSummaryLabel`, pego e corrigido).
