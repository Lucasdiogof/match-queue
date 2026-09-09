"""Etapa 17B -- gera o SQL do sample import (40 cartas), espelhando
EXATAMENTE o contrato de upsert de tool/sync_fc_cards.dart (mesmas chaves
de conflito, mesmos campos, is_active sempre true, last_synced_at =
now()).

Motivo de gerar SQL em vez de rodar `dart run tool/sync_fc_cards.dart`
sem --dry-run: este ambiente de execucao nao tem SUPABASE_SECRET_KEY (nem
SUPABASE_SERVICE_ROLE_KEY) no ambiente -- so a chave publica (anon) esta em
env/development.json, que nunca teve a secret key (proposital, nunca deve
ir para o client). O unico acesso de escrita disponivel nesta sessao e
`npx supabase db query --linked -f arquivo.sql`, que usa a autenticacao de
login do CLI, nao a service role key do PostgREST. Documentado como
limitacao de ambiente no handoff, nao como mudanca de design do importer --
tool/sync_fc_cards.dart continua sendo o caminho oficial quando a secret
key estiver disponivel.

NUNCA gera DELETE. NUNCA desativa nada (equivalente a rodar sem
--full-catalog).
"""

import csv


IN_PATH = "docs/final_data/data/wrexist_snapshot_normalized/fc27_cards_sample40.csv"
OUT_PATH = "docs/final_data/data/wrexist_snapshot_normalized/sample_import.sql"
PROVIDER = "WREXIST_EA_FC27_SNAPSHOT"
GAME_VERSION = "FC27"


def sql_str(value):
    if value is None or value == "":
        return "NULL"
    escaped = value.replace("'", "''")
    return f"'{escaped}'"


def sql_int(value):
    if value is None or value == "":
        return "NULL"
    return str(int(value))


def sql_text_array(values):
    if not values:
        return "'{}'::text[]"
    escaped = ",".join(v.replace("'", "''").replace('"', '\\"') for v in values)
    return f"'{{{escaped}}}'::text[]"


def parse_positions(row):
    primary = (row.get("position") or "").strip().upper()
    alt_raw = (row.get("alternative_positions") or "").strip()
    alt = [p.strip().upper() for p in alt_raw.split(",") if p.strip()]
    return primary, alt


def main():
    with open(IN_PATH, encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    leagues = sorted({r["league"] for r in rows if r.get("league")})
    nations = sorted({r["nationality"] for r in rows if r.get("nationality")})
    clubs = sorted({(r["club"], r.get("league") or "") for r in rows if r.get("club")})

    lines = []
    lines.append("begin;")
    lines.append("")

    lines.append("-- leagues (upsert-by-name, mesma logica de upsertByName no importer)")
    if leagues:
        values = ",\n  ".join(f"({sql_str(name)})" for name in leagues)
        lines.append(
            f"insert into fc_leagues (provider, name)\n"
            f"select {sql_str(PROVIDER)}, v.name\n"
            f"from (values\n  {values}\n) as v(name)\n"
            f"where not exists (select 1 from fc_leagues l where l.name = v.name);"
        )
    lines.append("")

    lines.append("-- nations (upsert-by-name)")
    if nations:
        values = ",\n  ".join(f"({sql_str(name)})" for name in nations)
        lines.append(
            f"insert into fc_nations (provider, name)\n"
            f"select {sql_str(PROVIDER)}, v.name\n"
            f"from (values\n  {values}\n) as v(name)\n"
            f"where not exists (select 1 from fc_nations n where n.name = v.name);"
        )
    lines.append("")

    lines.append("-- clubs (upsert-by-name, league_id resolvido por nome)")
    if clubs:
        values = ",\n  ".join(
            f"({sql_str(name)}, {sql_str(league)})" for name, league in clubs
        )
        lines.append(
            f"insert into fc_clubs (provider, name, league_id)\n"
            f"select {sql_str(PROVIDER)}, v.name, l.id\n"
            f"from (values\n  {values}\n) as v(name, league_name)\n"
            f"left join fc_leagues l on l.name = v.league_name\n"
            f"where not exists (select 1 from fc_clubs c where c.name = v.name);"
        )
    lines.append("")

    lines.append("-- fc_players (upsert por provider, game_version, provider_player_id)")
    player_rows = []
    for r in rows:
        primary, alt = parse_positions(r)
        player_rows.append(
            "  ("
            f"{sql_str(r['player_id'])}, {sql_str(r['name'])}, {sql_str(r.get('short_name'))}, "
            f"{sql_str(r.get('nationality'))}, {sql_str(r.get('club'))}, {sql_str(r.get('league'))}, "
            f"{sql_str(primary)}, {sql_text_array(alt)}, {sql_int(r.get('height'))}, "
            f"{sql_str((r.get('preferred_foot') or '').upper())}, {sql_int(r.get('weak_foot'))}, "
            f"{sql_int(r.get('skill_moves'))}"
            ")"
        )
    values = ",\n".join(player_rows)
    lines.append(
        "insert into fc_players (\n"
        "  provider, provider_player_id, game_version, name, common_name,\n"
        "  nation_id, club_id, league_id, primary_position, alternative_positions,\n"
        "  image_url, height_cm, preferred_foot, weak_foot, skill_moves,\n"
        "  is_active, last_synced_at\n"
        ")\n"
        "select\n"
        f"  {sql_str(PROVIDER)}, v.provider_player_id, {sql_str(GAME_VERSION)}, v.name, v.common_name,\n"
        "  (select id from fc_nations where name = v.nation_name),\n"
        "  (select id from fc_clubs where name = v.club_name),\n"
        "  (select id from fc_leagues where name = v.league_name),\n"
        "  v.primary_position, v.alt_positions,\n"
        "  null, v.height_cm, nullif(v.preferred_foot, ''), v.weak_foot, v.skill_moves,\n"
        "  true, now()\n"
        "from (values\n"
        f"{values}\n"
        ") as v(\n"
        "  provider_player_id, name, common_name, nation_name, club_name, league_name,\n"
        "  primary_position, alt_positions, height_cm, preferred_foot, weak_foot, skill_moves\n"
        ")\n"
        "on conflict (provider, game_version, provider_player_id) where provider_player_id is not null\n"
        "do update set\n"
        "  name = excluded.name,\n"
        "  common_name = excluded.common_name,\n"
        "  nation_id = excluded.nation_id,\n"
        "  club_id = excluded.club_id,\n"
        "  league_id = excluded.league_id,\n"
        "  primary_position = excluded.primary_position,\n"
        "  alternative_positions = excluded.alternative_positions,\n"
        "  height_cm = excluded.height_cm,\n"
        "  preferred_foot = excluded.preferred_foot,\n"
        "  weak_foot = excluded.weak_foot,\n"
        "  skill_moves = excluded.skill_moves,\n"
        "  is_active = true,\n"
        "  last_synced_at = now(),\n"
        "  updated_at = now();"
    )
    lines.append("")

    lines.append("-- fc_player_cards (upsert por provider, provider_card_id)")
    card_rows = []
    for r in rows:
        primary, alt = parse_positions(r)
        is_gk = primary == "GK"

        def line_stat(field):
            return "NULL" if is_gk else sql_int(r.get(field))

        def gk_stat(field):
            return sql_int(r.get(field)) if is_gk else "NULL"

        card_rows.append(
            "  ("
            f"{sql_str(r['provider_card_id'])}, {sql_str(r['player_id'])}, {sql_str(r['name'])}, "
            f"{sql_str(r.get('short_name'))}, {sql_int(r['overall'])}, {sql_str(primary)}, "
            f"{sql_text_array(alt)}, "
            f"{line_stat('pace')}, {line_stat('shooting')}, {line_stat('passing')}, "
            f"{line_stat('dribbling')}, {line_stat('defending')}, {line_stat('physical')}, "
            f"{gk_stat('gk_diving')}, {gk_stat('gk_handling')}, {gk_stat('gk_kicking')}, "
            f"{gk_stat('gk_reflexes')}, NULL, {gk_stat('gk_positioning')}, "
            f"{sql_int(r.get('skill_moves'))}, {sql_int(r.get('weak_foot'))}, "
            f"{sql_text_array([p.strip() for p in (r.get('playstyles') or '').split(',') if p.strip()])}, "
            f"{sql_text_array([p.strip() for p in (r.get('playstyles_plus') or '').split(',') if p.strip()])}, "
            f"{sql_int(r.get('height'))}, {sql_str((r.get('preferred_foot') or '').upper())}, "
            f"{sql_str(r.get('club'))}, {sql_str(r.get('league'))}, {sql_str(r.get('nationality'))}, "
            f"{sql_str(r['card_type'])}, {sql_str(r.get('source_url'))}"
            ")"
        )
    values = ",\n".join(card_rows)
    lines.append(
        "insert into fc_player_cards (\n"
        "  provider_card_id, provider, fc_player_id, player_name, common_name, rating,\n"
        "  primary_position, alternative_positions,\n"
        "  pace, shooting, passing, dribbling, defending, physical,\n"
        "  gk_diving, gk_handling, gk_kicking, gk_reflexes, gk_speed, gk_positioning,\n"
        "  skill_moves, weak_foot, playstyles, playstyles_plus,\n"
        "  height_cm, preferred_foot, club_name, league_name, nation_name,\n"
        "  card_type, source_url, club_id, league_id, nation_id,\n"
        "  game_version, is_active, last_synced_at\n"
        ")\n"
        "select\n"
        f"  v.provider_card_id, {sql_str(PROVIDER)},\n"
        "  (select id from fc_players where provider = " + sql_str(PROVIDER) +
        " and game_version = " + sql_str(GAME_VERSION) + " and provider_player_id = v.provider_player_id),\n"
        "  v.player_name, v.common_name, v.rating, v.primary_position, v.alt_positions,\n"
        "  v.pace, v.shooting, v.passing, v.dribbling, v.defending, v.physical,\n"
        "  v.gk_diving, v.gk_handling, v.gk_kicking, v.gk_reflexes, v.gk_speed, v.gk_positioning,\n"
        "  v.skill_moves, v.weak_foot, v.playstyles, v.playstyles_plus,\n"
        "  v.height_cm, nullif(v.preferred_foot, ''), v.club_name, v.league_name, v.nation_name,\n"
        "  v.card_type, v.source_url,\n"
        "  (select id from fc_clubs where name = v.club_name),\n"
        "  (select id from fc_leagues where name = v.league_name),\n"
        "  (select id from fc_nations where name = v.nation_name),\n"
        f"  {sql_str(GAME_VERSION)}, true, now()\n"
        "from (values\n"
        f"{values}\n"
        ") as v(\n"
        "  provider_card_id, provider_player_id, player_name, common_name, rating, primary_position,\n"
        "  alt_positions, pace, shooting, passing, dribbling, defending, physical,\n"
        "  gk_diving, gk_handling, gk_kicking, gk_reflexes, gk_speed, gk_positioning,\n"
        "  skill_moves, weak_foot, playstyles, playstyles_plus,\n"
        "  height_cm, preferred_foot, club_name, league_name, nation_name,\n"
        "  card_type, source_url\n"
        ")\n"
        "on conflict (provider, provider_card_id) where provider_card_id is not null\n"
        "do update set\n"
        "  fc_player_id = excluded.fc_player_id,\n"
        "  player_name = excluded.player_name,\n"
        "  common_name = excluded.common_name,\n"
        "  rating = excluded.rating,\n"
        "  primary_position = excluded.primary_position,\n"
        "  alternative_positions = excluded.alternative_positions,\n"
        "  pace = excluded.pace, shooting = excluded.shooting, passing = excluded.passing,\n"
        "  dribbling = excluded.dribbling, defending = excluded.defending, physical = excluded.physical,\n"
        "  gk_diving = excluded.gk_diving, gk_handling = excluded.gk_handling,\n"
        "  gk_kicking = excluded.gk_kicking, gk_reflexes = excluded.gk_reflexes,\n"
        "  gk_speed = excluded.gk_speed, gk_positioning = excluded.gk_positioning,\n"
        "  skill_moves = excluded.skill_moves, weak_foot = excluded.weak_foot,\n"
        "  playstyles = excluded.playstyles, playstyles_plus = excluded.playstyles_plus,\n"
        "  height_cm = excluded.height_cm, preferred_foot = excluded.preferred_foot,\n"
        "  club_name = excluded.club_name, league_name = excluded.league_name,\n"
        "  nation_name = excluded.nation_name, card_type = excluded.card_type,\n"
        "  source_url = excluded.source_url,\n"
        "  club_id = excluded.club_id, league_id = excluded.league_id, nation_id = excluded.nation_id,\n"
        "  is_active = true,\n"
        "  last_synced_at = now(),\n"
        "  updated_at = now();"
    )
    lines.append("")
    lines.append("commit;")

    with open(OUT_PATH, "w", encoding="utf-8") as out:
        out.write("\n".join(lines) + "\n")

    print(f"SQL escrito em {OUT_PATH}")
    print(f"leagues: {len(leagues)}, nations: {len(nations)}, clubs: {len(clubs)}, players/cards: {len(rows)}")


if __name__ == "__main__":
    main()
