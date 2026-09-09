"""Etapa 17B -- pre-processamento do snapshot Wrexist FC27.

Le FC27_male_players_reconciled.csv + FC27_female_players.csv (unica fonte
de trabalho autorizada nesta etapa -- ver docs/handoff_etapa17b.md), deriva
uma coluna `provider_card_id` = "<player_id>:BASE" e `card_type` =
"BASE_LAUNCH" por linha (a fonte representa base de carta UT de lancamento,
um unico tier por jogador, sem item id proprio -- decisao de identidade
registrada em docs/handoff_etapa17b.md, secao Etapa 17B) e escreve um CSV
combinado normalizado para tool/sync_fc_cards.dart consumir.

NUNCA inventa um id a partir de nome/rating/indice -- deriva SOMENTE do
`player_id` real que a fonte fornece. NUNCA acessa rede.

Escreve em docs/final_data/data/wrexist_snapshot_normalized/ (caminho
rastreado pelo git, ao contrario de docs/final_data/output/ que esta no
.gitignore -- ver achado documentado no handoff).
"""

import csv
import os

MALE_PATH = "docs/final_data/data/wrexist_snapshot/FC27_male_players_reconciled.csv"
FEMALE_PATH = "docs/final_data/data/wrexist_snapshot/FC27_female_players.csv"
OUT_DIR = "docs/final_data/data/wrexist_snapshot_normalized"
OUT_PATH = os.path.join(OUT_DIR, "fc27_cards_normalized.csv")


def load_rows(path):
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader), reader.fieldnames


def main():
    male_rows, male_fields = load_rows(MALE_PATH)
    female_rows, female_fields = load_rows(FEMALE_PATH)

    all_fields = list(male_fields)
    for field in female_fields:
        if field not in all_fields:
            all_fields.append(field)

    out_fields = all_fields + ["provider_card_id", "card_type"]

    os.makedirs(OUT_DIR, exist_ok=True)
    written = 0
    seen_ids = set()
    with open(OUT_PATH, "w", encoding="utf-8", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=out_fields, restval="")
        writer.writeheader()
        for rows in (male_rows, female_rows):
            for row in rows:
                player_id = row["player_id"]
                if not player_id:
                    continue
                if player_id in seen_ids:
                    raise SystemExit(
                        f"player_id duplicado entre arquivos: {player_id}"
                    )
                seen_ids.add(player_id)
                row = dict(row)
                row["provider_card_id"] = f"{player_id}:BASE"
                row["card_type"] = "BASE_LAUNCH"
                writer.writerow(row)
                written += 1

    print(f"linhas male: {len(male_rows)}")
    print(f"linhas female: {len(female_rows)}")
    print(f"linhas escritas (combinado, normalizado): {written}")
    print(f"player_id distintos: {len(seen_ids)}")
    print(f"arquivo de saida: {OUT_PATH}")


if __name__ == "__main__":
    main()
