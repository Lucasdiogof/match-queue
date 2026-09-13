"""
Merge dev-only script: builds tool/data/fc27_managers_candidates.json from
the two raw candidate lists (fifplay, fifauteam), deduped by normalized
name + resolved nation.

tool/data/ is gitignored (raw/derived datasets, not app code) -- this
script itself lives outside it so it's tracked and reusable for the next
reconciliation pass. Whoever runs it needs the raw txt files and
fc_nations_dump.json under tool/data/ locally first (the latter from
`npx supabase db query --linked "select id, name from public.fc_nations"`).
Its JSON output is the input tool/sync_fc_managers.dart actually imports.
Never touches the network or the database itself -- only reads/writes
local files under tool/data/.
"""

import json
import re
import unicodedata

NATION_ALIASES = {
    "holland": "Netherlands",
    "republic of ireland": "Ireland",
    "korea republic": "South Korea",
    "united states": "USA",
}


def normalize_name(name: str) -> str:
    name = unicodedata.normalize("NFKC", name).strip()
    name = re.sub(r"\s+", " ", name)
    return name


def name_key(name: str) -> str:
    decomposed = unicodedata.normalize("NFKD", name)
    ascii_only = "".join(c for c in decomposed if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", ascii_only.lower())


def load_nations():
    with open("tool/data/fc_nations_dump.json", encoding="utf-8") as f:
        rows = json.load(f)
    by_key = {}
    for row in rows:
        by_key[row["name"].strip().lower()] = row["name"]
    return by_key


def resolve_nation(raw_nation, nations_by_key):
    key = raw_nation.strip().lower()
    key = NATION_ALIASES.get(key, raw_nation).strip().lower()
    return nations_by_key.get(key)


def parse_fifplay(path, nations_by_key, unresolved):
    entries = []
    line_re = re.compile(r"^(.+?)\s+\(([^)]+)\)\s*$")
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("##"):
                continue
            m = line_re.match(line)
            if not m:
                continue
            raw_name, raw_nation = m.group(1), m.group(2)
            name = normalize_name(raw_name)
            nation = resolve_nation(raw_nation, nations_by_key)
            if nation is None:
                unresolved.add(raw_nation)
            entries.append({"name": name, "nation": nation, "raw_nation": raw_nation})
    return entries


def parse_fifauteam(path, nations_by_key, unresolved):
    entries = []
    current_nation_raw = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("##"):
                current_nation_raw = line.lstrip("#").strip()
                continue
            name = normalize_name(line)
            nation = resolve_nation(current_nation_raw, nations_by_key)
            if nation is None:
                unresolved.add(current_nation_raw)
            entries.append(
                {"name": name, "nation": nation, "raw_nation": current_nation_raw}
            )
    return entries


def main():
    nations_by_key = load_nations()
    unresolved = set()

    fifplay = parse_fifplay(
        "tool/data/fc27_managers_fifplay_raw.txt", nations_by_key, unresolved
    )
    fifauteam = parse_fifauteam(
        "tool/data/fc27_managers_fifauteam_raw.txt", nations_by_key, unresolved
    )

    merged = {}
    for entry in fifplay:
        key = (name_key(entry["name"]), entry["nation"])
        row = merged.setdefault(
            key,
            {
                "name": entry["name"],
                "nation": entry["nation"],
                "source_tags": [],
            },
        )
        if "FC27_EXPECTED_CANDIDATE" not in row["source_tags"]:
            row["source_tags"].append("FC27_EXPECTED_CANDIDATE")

    for entry in fifauteam:
        key = (name_key(entry["name"]), entry["nation"])
        row = merged.setdefault(
            key,
            {
                "name": entry["name"],
                "nation": entry["nation"],
                "source_tags": [],
            },
        )
        if "UT_LEGACY_CANDIDATE" not in row["source_tags"]:
            row["source_tags"].append("UT_LEGACY_CANDIDATE")

    candidates = sorted(merged.values(), key=lambda r: (r["name"], r["nation"] or ""))

    with open(
        "tool/data/fc27_managers_candidates.json", "w", encoding="utf-8", newline="\n"
    ) as f:
        json.dump(candidates, f, ensure_ascii=False, indent=2)
        f.write("\n")

    both = sum(1 for r in candidates if len(r["source_tags"]) == 2)
    print(f"fifplay entries: {len(fifplay)}")
    print(f"fifauteam entries: {len(fifauteam)}")
    print(f"merged candidates: {len(candidates)}")
    print(f"present in both sources: {both}")
    print(f"unresolved nation names: {sorted(unresolved)}")
    no_nation = sum(1 for r in candidates if r["nation"] is None)
    print(f"candidates with no resolved nation: {no_nation}")


if __name__ == "__main__":
    main()
