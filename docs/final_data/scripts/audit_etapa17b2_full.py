"""Etapa 17B-2 -- auditoria completa do arquivo inteiro (17.873 linhas) antes
dos degraus 500/2.000/5.000. Sem rede, sem escrita -- so leitura do CSV
normalizado e reproducao das mesmas regras de validacao de
tool/sync_fc_cards.dart (playerName + primaryPosition obrigatorios; carta
real exige rating; sem provider_card_id nem provider_player_id => invalida).
"""

import csv
from collections import Counter, defaultdict

IN_PATH = "docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_normalized.csv"


def main():
    with open(IN_PATH, encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    total = len(rows)
    male = [r for r in rows if r.get("gender") == "Men's Football"]
    female = [r for r in rows if r.get("gender") == "Women's Football"]
    other_gender = total - len(male) - len(female)
    print(f"total linhas: {total}")
    print(f"gender values distintos: {Counter(r.get('gender') for r in rows)}")
    print(f"male (heuristico): {len(male)}  female (heuristico): {len(female)}  outro/vazio: {other_gender}")

    player_ids = [r["player_id"] for r in rows]
    dup_ids = Counter(player_ids)
    dup_id_count = sum(1 for k, v in dup_ids.items() if v > 1)
    print(f"player_id distintos: {len(dup_ids)}  duplicados: {dup_id_count}")

    names = [r["name"].strip().lower() for r in rows if r.get("name")]
    dup_names = Counter(names)
    dup_name_groups = {k: v for k, v in dup_names.items() if v > 1}
    print(f"nomes distintos (case-insensitive): {len(dup_names)}  nomes com 2+ linhas: {len(dup_name_groups)}  total de linhas nesses grupos: {sum(dup_name_groups.values())}")

    would_reject = 0
    reject_reasons = Counter()
    for r in rows:
        name = (r.get("name") or "").strip()
        pos = (r.get("position") or "").strip()
        overall = (r.get("overall") or "").strip()
        card_id = (r.get("provider_card_id") or "").strip()
        player_id = (r.get("player_id") or "").strip()
        if not name or not pos:
            would_reject += 1
            reject_reasons["sem name ou position"] += 1
            continue
        has_card_id = bool(card_id)
        if has_card_id and not overall:
            would_reject += 1
            reject_reasons["card_id presente mas sem rating"] += 1
            continue
        if not has_card_id and not player_id:
            would_reject += 1
            reject_reasons["sem card_id e sem player_id"] += 1
            continue
    print(f"linhas que o importer (--dry-run) rejeitaria: {would_reject}")
    for reason, count in reject_reasons.items():
        print(f"  - {reason}: {count}")

    cards_produced = sum(1 for r in rows if (r.get("provider_card_id") or "").strip())
    print(f"cards que seriam produzidos (fc_player_cards): {cards_produced}")

    clubs = set(r["club"] for r in rows if r.get("club"))
    leagues = set(r["league"] for r in rows if r.get("league"))
    nations = set(r["nationality"] for r in rows if r.get("nationality"))
    print(f"clubs distintos: {len(clubs)}  leagues distintos: {len(leagues)}  nations distintos: {len(nations)}")

    club_leagues = defaultdict(set)
    for r in rows:
        club = r.get("club")
        league = r.get("league")
        if club:
            club_leagues[club].add(league or "")
    multi_league_clubs = {c: ls for c, ls in club_leagues.items() if len(ls) > 1}
    print(f"clubs com o MESMO NOME aparecendo em 2+ ligas distintas: {len(multi_league_clubs)}")
    for c, ls in sorted(multi_league_clubs.items())[:30]:
        print(f"  - {c}: {sorted(ls)}")
    if len(multi_league_clubs) > 30:
        print(f"  ... e mais {len(multi_league_clubs) - 30}")

    positions = Counter(r.get("position") for r in rows)
    print(f"distribuicao de posicao: {dict(positions)}")

    ratings = [int(r["overall"]) for r in rows if (r.get("overall") or "").strip()]
    print(f"rating min/max/avg: {min(ratings)}/{max(ratings)}/{sum(ratings)/len(ratings):.2f}")
    rating_buckets = Counter((v // 10) * 10 for v in ratings)
    print(f"rating por faixa de 10: {dict(sorted(rating_buckets.items()))}")

    gk_count = sum(1 for r in rows if r.get("position") == "GK")
    print(f"GK: {gk_count}  outfield: {total - gk_count}")

    missing_overall = sum(1 for r in rows if not (r.get("overall") or "").strip())
    missing_position = sum(1 for r in rows if not (r.get("position") or "").strip())
    missing_club = sum(1 for r in rows if not (r.get("club") or "").strip())
    missing_league = sum(1 for r in rows if not (r.get("league") or "").strip())
    missing_nation = sum(1 for r in rows if not (r.get("nationality") or "").strip())
    missing_source_url = sum(1 for r in rows if not (r.get("source_url") or "").strip())
    print(f"registros sem overall: {missing_overall}, sem position: {missing_position}, sem club: {missing_club}, sem league: {missing_league}, sem nation: {missing_nation}, sem source_url: {missing_source_url}")

    extreme_low = [r["name"] for r in rows if (r.get("overall") or "").strip() and int(r["overall"]) < 50]
    extreme_high = [r["name"] for r in rows if (r.get("overall") or "").strip() and int(r["overall"]) > 90]
    print(f"rating < 50: {len(extreme_low)}  rating > 90: {len(extreme_high)}")
    if extreme_high:
        print(f"  exemplos rating>90: {extreme_high[:10]}")

    gk_speed_present = sum(1 for r in rows if r.get("position") == "GK" and (r.get("gk_diving") or "").strip())
    print(f"GK com gk_diving preenchido: {gk_speed_present}/{gk_count}")

    card_types = Counter(r.get("card_type") for r in rows)
    print(f"card_type distintos: {dict(card_types)}")

    dup_card_ids = Counter(r["provider_card_id"] for r in rows if (r.get("provider_card_id") or "").strip())
    dup_card_id_count = sum(1 for k, v in dup_card_ids.items() if v > 1)
    print(f"provider_card_id duplicado: {dup_card_id_count}")


if __name__ == "__main__":
    main()
