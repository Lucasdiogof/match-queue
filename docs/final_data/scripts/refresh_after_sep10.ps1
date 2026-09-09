$ErrorActionPreference = "Stop"
python scripts/fetch_ea_fc27.py --out output/ea_fc27_raw
python scripts/normalize_ea_fc27.py output/ea_fc27_raw/all_items.json --out output/fc27_normalized
python scripts/validate_fc27.py output/fc27_normalized/fc27_normalized.csv
python scripts/build_supabase_payloads.py output/fc27_normalized/fc27_normalized.csv --out output/supabase_payloads
Write-Host "Refresh complete. Review counts/diff before running the Dart Supabase importer."
