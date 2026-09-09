"""Etapa 17B-2 -- selecao deterministica de amostras de tamanho arbitrario
(500 / 2.000 / 5.000), MESMO criterio do select_wrexist_sample.py original
(40 cartas): ordenar por player_id numerico ascendente, amostragem
sistematica por stride fixo = total // N, nunca random(). Documentado antes
de rodar, reprodutivel contra o mesmo arquivo de entrada.
"""

import csv
import sys

IN_PATH = "docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_normalized.csv"


def select(n):
    with open(IN_PATH, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    rows.sort(key=lambda r: int(r["player_id"]))
    total = len(rows)
    stride = total // n
    indices = [i * stride for i in range(n)]
    sample = [rows[i] for i in indices]

    out_path = f"docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_sample{n}.csv"
    with open(out_path, "w", encoding="utf-8", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=fieldnames)
        writer.writeheader()
        for row in sample:
            writer.writerow(row)

    genders = {}
    for r in sample:
        genders[r.get("gender")] = genders.get(r.get("gender"), 0) + 1
    positions = sorted(set(r["position"] for r in sample))
    leagues = sorted(set(r["league"] for r in sample if r["league"]))
    clubs = sorted(set(r["club"] for r in sample if r["club"]))
    nations = sorted(set(r["nationality"] for r in sample))
    ratings = sorted(int(r["overall"]) for r in sample)

    print(f"N={n}  total linhas ordenadas: {total}  stride: {stride}")
    print(f"amostra escrita: {out_path} ({len(sample)} linhas)")
    print(f"gender: {genders}")
    print(f"posicoes distintas: {len(positions)} -> {positions}")
    print(f"leagues distintas: {len(leagues)}")
    print(f"clubs distintos: {len(clubs)}")
    print(f"nacoes distintas: {len(nations)}")
    print(f"rating min/max: {ratings[0]}/{ratings[-1]}")
    print()


if __name__ == "__main__":
    for n in (500, 2000, 5000):
        select(n)
