# FC27 FINAL PACK — 2026-09-08

Este pacote encerra a pesquisa de fontes e o desenho do pipeline de importação do FC27 para o Fut Manager.

## Conclusão

**Pesquisa/mapeamento: 100% concluído para o estado público disponível em 2026-09-08.**

Isso não significa que a EA terminou de publicar a base final: a própria página oficial informa que certos detalhes podem mudar na atualização de **10/09/2026**. Portanto, este é um snapshot auditável de 08/09 + uma rotina de refresh pronta.

### Números atuais
- EA oficial: **20.689** resultados no catálogo de ratings.
- Escopo EA: itens Gold/Silver/Bronze de lançamento; Heroes, Icons e Campaign Items ficam fora.
- FUT Forge: **20.689** jogadores — cross-check de cobertura.
- FCData: **20.710** cards.
- Diferença conhecida: **21 Hall of FUT** revelados, mantidos em camada de carta/item separada.

## Arquivos

- `sources/source_manifest.json` — verdade operacional das fontes/campos.
- `sources/source_matrix.csv` — comparação rápida.
- `sources/external_dataset_refs.json` — referências de snapshots externos, com warnings.
- `schema/fc27_normalized_schema.json` — contrato provider-neutral.
- `schema/supabase_mapping.json` — mapping para `fc_players` / `fc_player_cards`.
- `scripts/fetch_ea_fc27.py` — fetch bulk oficial, sem bypass.
- `scripts/normalize_ea_fc27.py` — normalização de EA JSON.
- `scripts/validate_fc27.py` — validação bloqueante.
- `scripts/build_supabase_payloads.py` — gera payloads locais; não toca Supabase.
- `scripts/refresh_after_sep10.*` — pipeline de refresh.
- `data/hall_of_fut_21.csv` — 21 specials já revelados.
- `legacy_samples/` — os CSVs antigos de 45 players / 280 cards, preservados só para histórico.
- `FINAL_HANDOFF.md` — instrução pronta para implementar/rodar no repo.

## Regra de ouro
Valor ausente permanece ausente. Nada é estimado só para “encher coluna”.

## Limites atuais
- `player_roles`: ainda sem fonte player-specific confiável no payload oficial auditado.
- `potential`: não existe no EA ratings API.
- PlayStyles/PlayStyles+ foram observados no Drop API/snapshot público, mas devem ser tratados como provisórios até o refresh pós-10/09.
- AcceleRATE aparece em FCData; manter provenance separado quando não vier diretamente da EA.
