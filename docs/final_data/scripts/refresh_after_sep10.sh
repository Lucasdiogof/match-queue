#!/usr/bin/env bash
set -euo pipefail
python3 scripts/fetch_ea_fc27.py --out output/ea_fc27_raw
python3 scripts/normalize_ea_fc27.py output/ea_fc27_raw/all_items.json --out output/fc27_normalized
python3 scripts/validate_fc27.py output/fc27_normalized/fc27_normalized.csv
python3 scripts/build_supabase_payloads.py output/fc27_normalized/fc27_normalized.csv --out output/supabase_payloads
echo "Refresh complete. Review counts/diff before running the Dart Supabase importer."
