# Data handoff — integrate FC27 official data package

Use this package with the existing FC data architecture. Do not redesign the database.

## Existing contract to preserve
- `fc_players` = canonical real-player identity/base record.
- `fc_player_cards` = specific Ultimate Team item/card records.
- Existing importer: `tool/sync_fc_cards.dart`.
- `provider_player_id` and `provider_card_id` are different identities.
- A player with no real `provider_card_id` must NOT create a fake card row.

## Steps
1. Run `python3 tools/fetch_fc27_official.py --out data` from this package (or port the collector to Dart without changing semantics).
2. Validate with `python3 tools/validate_fc27_outputs.py data/processed/fc27_players.csv data/processed/fc27_cards.csv`.
3. Feed `data/processed/fc27_players.csv` into the existing `fc_players` path of `tool/sync_fc_cards.dart`.
4. Do not generate card ids from player ids. `fc27_cards.csv` from the official-only pull is intentionally header-only.
5. When a card-specific enrichment file is later approved, run `tools/build_base_cards_from_enrichment.py` to generate card rows only for records with explicit card ids.
6. Preserve `source`, `source_url`, `source_updated_at` and `raw_payload`.
7. Upserts must be idempotent.
8. Never replace a known real FC27 value with FC26 carry-over. If a career-mode fallback is intentionally introduced, put it in a separate field/source label and make it opt-in.
9. Re-run the official collector after EA's scheduled 2026-09-10 database/PlayStyles update and diff before applying changes.

## Acceptance checks
- no duplicate nonblank `provider_player_id`;
- all player names nonblank;
- overall in 1..99;
- gender is male/female/unknown, never guessed male;
- no card row with blank `provider_card_id` or `provider_player_id`;
- no `provider_card_id == provider_player_id` rule is introduced;
- raw pages stay untouched under `data/raw`;
- importer remains restartable/idempotent;
- output counts and source timestamp are logged.
