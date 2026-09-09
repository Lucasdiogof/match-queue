# Handoff — FC27 Data, snapshot 2026-09-08

Objetivo: integrar o catálogo FC27 ao Fut Manager **sem redesenhar a arquitetura existente**.

## Estado confirmado
- `fc_players` e `fc_player_cards` já estão separados.
- O importer local já aceita CSV/JSON genérico e resolve `provider_player_id -> fc_player_id`.
- O catálogo oficial atual da EA mostra 20.689 itens base de lançamento.
- A EA diz explicitamente que a tabela base é Gold/Silver/Bronze de lançamento e exclui Heroes/Icons/Campaign.
- 21 Hall of FUT já foram revelados e devem entrar como cartas especiais separadas, nunca como novos `fc_players`.
- A EA anunciou atualização do database em 2026-09-10; o primeiro refresh após essa data é obrigatório antes de considerar o snapshot “release candidate”.

## O que fazer
1. Leia `sources/source_manifest.json` e `schema/supabase_mapping.json`.
2. NÃO altere migrations/schema sem necessidade concreta.
3. Use `scripts/fetch_ea_fc27.py` para tentar o Drop API oficial.
4. Se EA retornar 403, NÃO contorne. Registre o bloqueio e rode de um ambiente permitido.
5. Normalize com `scripts/normalize_ea_fc27.py`.
6. Valide e compare o total com a página oficial. Hoje: 20.689.
7. Faça `--dry-run` do `tool/sync_fc_cards.dart` usando o arquivo normalizado/mapeamento.
8. Só depois de dry-run perfeito, execute o import real.
9. Para base EA use um provider explícito como `EA_FC27_RATINGS`.
10. `provider_player_id` = EA player id.
11. Para item base, use `card_type='BASE_LAUNCH'` (ou o valor canônico equivalente já aceito pelo schema).
12. Hall of FUT: provider/item separado e `card_type='HALL_OF_FUT'`; 21 linhas estão em `data/hall_of_fut_21.csv`.
13. `player_roles`: não inventar. Persistir `[]/null` até fonte player-specific confiável.
14. `potential`: não inventar; EA ratings não fornece.
15. `AcceleRATE`: se vier de FCData ou cálculo, mantenha provenance distinto de EA.
16. Após 2026-09-10, rode refresh e gere diff de IDs/ratings/clubes/atributos antes de marcar produção pronta.
17. Não delete registros ausentes num run parcial; só desative missing após run completo e validado.

## Critérios de aceite
- 20.689 (ou o novo total oficial pós-10/09) registros base reconciliados com a EA.
- IDs externos únicos.
- zero player sem nome/overall/posição.
- GK sem stats outfield misturados.
- `fc_player_cards.fc_player_id` resolvido quando há `provider_player_id`.
- special cards não duplicam identidade base.
- logs de inserted/updated/skipped/failed.
- nenhum dado faltante fabricado.
