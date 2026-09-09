"""Etapa 17B -- selecao deterministica da amostra de sample import.

Criterio (documentado ANTES de rodar o import): ordenar o CSV normalizado
por `player_id` numerico ascendente e escolher 40 linhas por amostragem
sistematica (stride fixo = total // 40), nunca random(). Isso cobre o
arquivo inteiro em vez de só os IDs mais antigos/mais novos, e produz uma
lista reprodutivel -- rodar de novo com o mesmo arquivo de entrada sempre
escolhe os mesmos 40 jogadores.
"""

import csv

IN_PATH = "docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_normalized.csv"
OUT_PATH = "docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_sample40.csv"
SAMPLE_SIZE = 40


def main():
    with open(IN_PATH, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)

    rows.sort(key=lambda r: int(r["player_id"]))
    total = len(rows)
    stride = total // SAMPLE_SIZE
    indices = [i * stride for i in range(SAMPLE_SIZE)]
    sample = [rows[i] for i in indices]

    with open(OUT_PATH, "w", encoding="utf-8", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=fieldnames)
        writer.writeheader()
        for row in sample:
            writer.writerow(row)

    print(f"total linhas ordenadas: {total}")
    print(f"stride: {stride}")
    print(f"amostra escrita: {OUT_PATH} ({len(sample)} linhas)")
    print()
    print("player_id | name | position | overall | league | nationality")
    for row in sample:
        print(
            f"{row['player_id']} | {row['name']} | {row['position']} | "
            f"{row['overall']} | {row['league']} | {row['nationality']}"
        )

    positions = sorted(set(r["position"] for r in sample))
    leagues = sorted(set(r["league"] for r in sample if r["league"]))
    nations = sorted(set(r["nationality"] for r in sample))
    ratings = sorted(int(r["overall"]) for r in sample)
    print()
    print(f"posicoes distintas na amostra: {len(positions)} -> {positions}")
    print(f"ligas distintas na amostra: {len(leagues)}")
    print(f"nacoes distintas na amostra: {len(nations)}")
    print(f"rating min/max na amostra: {ratings[0]}/{ratings[-1]}")


if __name__ == "__main__":
    main()
