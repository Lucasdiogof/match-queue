# Handoff — Etapa 14 (Times 2.0)

Status em 2026-09-08: **fechada**. Backend aplicado (63 migrations no
remoto), Flutter completo, `flutter analyze` limpo, tudo commitado e pushado
em `origin/main`.

Nada aqui depende do catálogo FC27: leaderboards usam `snapshot_player_key` /
`player_name` congelados na partida, com `player_card_id` opcional.

## Backend

Uma migration: `20260923100000_team_sports_dashboard.sql`.

| Função | Papel |
| --- | --- |
| `_team_ranking_min_matches()` | mínimo de partidas para ranquear (5) |
| `_team_player_leaderboard(...)` | artilharia/assistências, privada |
| `get_team_player_leaderboard(...)` | lista completa, exige membership |
| `get_team_sports_dashboard(team_id)` | resumo + ranking + leaderboards + WL + Rivals + atividade numa chamada |

Nenhuma migration aplicada foi editada. Nenhum índice novo: os que a
agregação usa já existiam (`fc_account_teams_team_idx`,
`game_matches_fc_account_mode_status_idx`,
`game_match_player_stats_match_idx`).

**Dedupe** — o risco central. Uma busca de uma Conta pode tocar vários Times
(`match_search_session_teams`), então qualquer caminho `game_matches →
search_session → session_teams` multiplicaria a mesma partida. Aqui isso
nunca acontece: o vínculo com o Time é sempre um `EXISTS` sobre
`fc_account_teams`, que filtra sem multiplicar linha. Validado contra a
contagem crua no banco.

**Autorização** — só membro lê (`is_team_member`, FQ012); `anon` bloqueado
por falta de grant. OWNER não ganha privilégio nenhum sobre stats alheias:
administrar o Time não é editar resultado de ninguém. Padrão preservado:
`security definer`, `search_path=''`, identificadores qualificados, grants
explícitos, nada profilático para `service_role`. Nenhum código FQ novo foi
preciso.

**Escopo** — a partida entra no Time quando a Conta que jogou está vinculada
a ele **e** o dono dela ainda é membro. Conta não vinculada nunca vaza; quem
saiu do Time some do dashboard (sem hall histórico).

## Team Summary

`matches`, `wins`, `losses`, `win_rate`, `goals_for`, `goals_against`,
`goal_difference`, `registered_player_goals`, `registered_assists`,
`members_count`, `accounts_count`.

Só `FINISHED` com `result` entra em W/L — cancelada/abandonada não conta.
Placar só soma onde existe: vitória sem placar entra no record e **não**
fabrica gol. `goals_for` (placar) e `registered_player_goals` (registro
individual) são fontes diferentes e não precisam bater — regra da Etapa 12
preservada. `win_rate` é `null` sem partidas, nunca 0.

## Ranking

Por **usuário**, não por Conta. Quem tem várias Contas vinculadas ao Time vê
as duas somadas, com dedupe garantido por partida.

Ordenação, sem pontuação mágica:

```
elegível (matches >= 5) DESC
win_rate DESC
wins DESC
matches DESC
display_name ASC
```

Abaixo do mínimo o membro **aparece igual**, marcado como "amostra pequena" e
posicionado depois dos elegíveis. Membro sem partida continua na lista, com
"Sem partidas". Tocar num membro abre o perfil público existente — nenhuma
tela duplicada.

## Player Leaderboards

Agrupados por **(Conta, carta)**, nunca por carta sozinha: a mesma carta em
duas Contas são duas linhas, porque o gol tem dono. Versões diferentes da
mesma pessoa (Gold vs TOTS) também não se consolidam — a chave é a carta;
`fc_players` permitirá agrupar depois, quando houver decisão de produto.

Ordenação: gols DESC, assistências DESC, nome ASC (invertido no de
assistências), igual à Etapa 12. Gols registrados entram mesmo em partida sem
placar. Sem imagem, placeholder próprio — nunca bloqueia a lista.

## Weekend League

Por Conta, no evento corrente. Record manual manda na exibição de W/L e é
marcado como tal, mas **nunca** fabrica gol ou assistência — validado.

Decisão do "qual evento": usa o evento ativo agora
(`weekend_league_events` com `is_active` e dentro da janela). Sem evento
ativo, o record cai para as partidas de WL da Conta sem recorte de evento.

## Rivals

Por Conta: divisão atual, partidas, W/L e aproveitamento, só
`DIVISION_RIVALS`. A divisão é **informação, não posição** — o domínio não
modela ordem oficial entre divisões, então nenhum ranking é inventado a
partir dela.

## Activity

Derivada das partidas concluídas que já existem — nenhuma tabela de eventos
nova. Um tipo só hoje, `MATCH_RESULT`: quem, com que Conta, modo, resultado,
placar quando houver e o artilheiro daquela partida. Limite 20. Nada de fila,
busca ou expiração.

## Flutter

- `TeamSportsDashboard`, `TeamSportsSummary`, `TeamMemberSportsStats`,
  `TeamPlayerLeaderboardEntry`, `TeamWeekendLeagueEntry`, `TeamRivalsEntry`,
  `TeamSportsActivity`.
- `TeamSportsCubit`: **um** cubit para a tela toda, não um por seção — tudo
  vem da mesma chamada e muda junto.
- `TeamDetailPage` ganhou header com resumo discreto, seções de resumo,
  ranking, artilharia, assistências, WL, Rivals e atividade, com
  pull-to-refresh. Carrega **só ao entrar no Time**; a lista de Times
  continua leve.
- Status operacional (Realtime) preservado e nunca misturado com stats.

## Validation

32 checagens pontuais, todas verdes:

- partida nunca duplica por a Conta estar vinculada a 2 Times (conferido
  contra contagem crua em SQL);
- Conta não vinculada não entra;
- usuário com 2 Contas soma corretamente;
- record manual de WL não fabrica gol nem mexe na artilharia;
- resultado sem placar conta em W/L;
- placar ausente não fabrica `goals_for`;
- gols individuais sem placar entram na artilharia;
- mesma carta em Contas diferentes não é fundida;
- membro de outro Time não lê o dashboard; `anon` bloqueado; artilharia
  também exige membership;
- usuário removido deixa de aparecer e sai dos totais;
- ordenação do ranking e mínimo de amostra;
- atividade só com evento esportivo;
- Time novo: resumo zerado sem quebrar, artilharia vazia.

Dados de QA removidos: 0 usuários, 0 times, 0 partidas, 0 stats.

## Git

```
e412615  Show a team's sporting record, ranking and leaderboards
43ab5fb  Aggregate a team's sporting record without double counting
c6c769a  Describe blocked sources by what they block, not by crawler name
```

63 migrations locais = 63 remotas.

## Pendências

Adiadas conscientemente:

- **Histórico temporal do vínculo Conta↔Time.** `fc_account_teams` só tem
  `created_at`, então o dashboard reflete as Contas vinculadas **agora**,
  inclusive para partidas anteriores ao vínculo. Um vínculo com validade
  exigiria versionar a tabela; sem demanda concreta, não vale a complexidade.
- **Conta arquivada**: continua contando enquanto o vínculo com o Time
  existir — o histórico esportivo não é apagado em silêncio. Se aparecer
  necessidade de separar "ativa" de "arquivada" no dashboard, é um filtro
  novo, não uma mudança de dado.
- **Hall histórico** de ex-membros: fora de escopo (item 58).
- **Empates**: o domínio é WIN/LOSS e nenhum DRAW foi inventado.
- **Consolidar versões da mesma pessoa** na artilharia: depende de decisão de
  produto sobre `fc_players`.
- **Paginação** da artilharia além do "ver tudo" (limite 100 na RPC).
- Revisão linguística PT/EN/ES, QA visual, testes automatizados e hardening
  seguem para a etapa final.

## Não esquecer

- `dart format .` quebra neste repo; usar `dart format lib`.
- Commits em inglês, imperativos, sem prefixo `feat:`/`fix:` e **sem
  qualquer rodapé de autoria** — o trabalho é do dono do repositório.
- Commitar sempre com caminhos explícitos.
- `gen-l10n` respeita a ordem de `@placeholders`; conferir a assinatura
  gerada antes de chamar.
- Matchmaking (Etapa 12): `request_match_search(p_fc_account_id,
  p_fc_squad_id, p_game_mode)` e
  `report_match_found_and_start_game(p_fc_account_id)` — **sem `p_team_id`**.
