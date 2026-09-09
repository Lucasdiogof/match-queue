# Data

`hall_of_fut_21.csv` contém somente os 21 Hall of FUT já revelados/listados em 08/09/2026.

O pacote **não chama os CSVs legados de dataset completo**:
- `legacy_samples/fc27_players_45_legacy.csv` = 45 registros.
- `legacy_samples/fc27_cards_280_legacy.csv` = 280 registros.

O catálogo base completo deve ser regenerado a partir da EA com `scripts/fetch_ea_fc27.py`
num ambiente onde o endpoint público responda. Isso evita distribuir como “atual” um snapshot de 28/08
que já está atrás da página oficial de 08/09 e da atualização anunciada para 10/09.
