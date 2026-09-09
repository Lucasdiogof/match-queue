import csv
import json
from collections import Counter, defaultdict

PATH = "docs/final_data/data/wrexist_snapshot/FC27_male_players_reconciled.csv"
PATH_FEMALE = "docs/final_data/data/wrexist_snapshot/FC27_female_players.csv"


def audit(path, label):
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    total = len(rows)
    player_ids = Counter(r["player_id"] for r in rows)
    dup_ids = {k: v for k, v in player_ids.items() if v > 1}

    id_mismatch = 0
    for r in rows:
        pid = r.get("player_id")
        spid = r.get("source_player_id")
        if pid != spid:
            id_mismatch += 1

    positions = Counter(r["position"] for r in rows)
    ratings = Counter(int(r["overall"]) for r in rows if r.get("overall"))
    clubs = set(r["club"] for r in rows if r.get("club"))
    leagues = set(r["league"] for r in rows if r.get("league"))
    nations = set(r["nationality"] for r in rows if r.get("nationality"))

    null_counts = defaultdict(int)
    important_fields = [
        "player_id", "name", "position", "overall", "club", "league",
        "nationality", "preferred_foot", "source_url",
    ]
    for r in rows:
        for field in important_fields:
            if not r.get(field):
                null_counts[field] += 1

    missing_overall_or_pos = sum(
        1 for r in rows if not r.get("overall") or not r.get("position")
    )
    game_club_present = sum(1 for r in rows if r.get("game_club_id"))
    source_url_present = sum(1 for r in rows if r.get("source_url"))
    scraped_at_values = set(r.get("scraped_at") for r in rows)
    data_version_values = set(r.get("data_version") for r in rows)
    game_versions_seen = set(r.get("data_version") for r in rows)

    rating_min = min(ratings) if ratings else None
    rating_max = max(ratings) if ratings else None
    out_of_range = sum(c for v, c in ratings.items() if v < 0 or v > 99)

    print(f"=== {label} ({path}) ===")
    print(f"total linhas: {total}")
    print(f"player_id distintos: {len(player_ids)}")
    print(f"player_id duplicados: {len(dup_ids)} -> {list(dup_ids.items())[:5]}")
    print(f"player_id != source_player_id: {id_mismatch}")
    print(f"posicoes distintas: {len(positions)} -> {positions.most_common()}")
    print(f"rating min/max: {rating_min}/{rating_max}, fora de 0-99: {out_of_range}")
    print(f"clubes distintos: {len(clubs)}")
    print(f"ligas distintas: {len(leagues)}")
    print(f"nacoes distintas: {len(nations)}")
    print(f"linhas sem overall ou sem position: {missing_overall_or_pos}")
    print(f"game_club_id presente: {game_club_present}/{total}")
    print(f"source_url presente: {source_url_present}/{total}")
    print(f"scraped_at valores distintos: {scraped_at_values}")
    print(f"data_version valores distintos: {data_version_values}")
    print("nulos por campo importante:")
    for field in important_fields:
        print(f"  {field}: {null_counts[field]}")
    print()
    return rows


rows_male = audit(PATH, "male_players_reconciled")
rows_female = audit(PATH_FEMALE, "female_players")

# cross-check player_id overlap between male and female (should be disjoint)
male_ids = set(r["player_id"] for r in rows_male)
female_ids = set(r["player_id"] for r in rows_female)
overlap = male_ids & female_ids
print(f"overlap player_id male/female: {len(overlap)}")

# sample header diff vs male_players (non-reconciled) and community_pack_input
with open("docs/final_data/data/wrexist_snapshot/FC27_male_players.csv", encoding="utf-8") as f:
    header_plain = next(csv.reader(f))
with open(PATH, encoding="utf-8") as f:
    header_reconciled = next(csv.reader(f))
with open("docs/final_data/data/wrexist_snapshot/FC27_community_pack_input.csv", encoding="utf-8") as f:
    header_pack = next(csv.reader(f))

print()
print("colunas so em reconciled (nao em male_players):", set(header_reconciled) - set(header_plain))
print("colunas so em male_players (nao em reconciled):", set(header_plain) - set(header_reconciled))
print("colunas so em community_pack_input:", set(header_pack) - set(header_reconciled))
