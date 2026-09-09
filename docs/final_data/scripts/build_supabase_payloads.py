#!/usr/bin/env python3
"""
Build provider-neutral import payloads for the existing fc_players -> fc_player_cards architecture.
This does not contact Supabase or write/delete anything remotely.
"""
import argparse,csv,json
from pathlib import Path
def j(x,default=None):
    try:return json.loads(x) if x else default
    except:return default
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("csv"); ap.add_argument("--out",default="output/supabase_payloads")
    a=ap.parse_args(); out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
    with open(a.csv,encoding="utf-8-sig",newline="") as f: rows=list(csv.DictReader(f))
    players=[]; cards=[]
    for r in rows:
        pid=r.get("provider_player_id") or None
        players.append({
          "provider":r.get("source_provider"),"provider_player_id":pid,"game_version":"FC27",
          "name":r.get("name"),"common_name":r.get("common_name") or None,
          "primary_position":r.get("primary_position") or None,
          "alternative_positions":j(r.get("alternative_positions"),[]),
          "image_url":r.get("player_image_url") or None,
          "height_cm":int(r["height_cm"]) if r.get("height_cm") else None,
          "preferred_foot":r.get("preferred_foot") or None,
          "weak_foot":int(float(r["weak_foot"])) if r.get("weak_foot") else None,
          "skill_moves":int(float(r["skill_moves"])) if r.get("skill_moves") else None,
          "raw_metadata":{"source_url":r.get("source_url"),"collected_at":r.get("collected_at")}
        })
        cards.append({
          "provider":r.get("source_provider"),"provider_card_id":r.get("provider_item_id") or pid,
          "provider_player_id":pid,"game_version":"FC27","player_name":r.get("name"),
          "rating":int(float(r["rating"])) if r.get("rating") else None,
          "primary_position":r.get("primary_position") or None,
          "alternative_positions":j(r.get("alternative_positions"),[]),
          "card_type":r.get("card_type") or "BASE_DATASET","rarity":r.get("rarity") or None,
          "pace":int(float(r["pace"])) if r.get("pace") else None,
          "shooting":int(float(r["shooting"])) if r.get("shooting") else None,
          "passing":int(float(r["passing"])) if r.get("passing") else None,
          "dribbling":int(float(r["dribbling"])) if r.get("dribbling") else None,
          "defending":int(float(r["defending"])) if r.get("defending") else None,
          "physical":int(float(r["physical"])) if r.get("physical") else None,
          "gk_diving":int(float(r["gk_diving"])) if r.get("gk_diving") else None,
          "gk_handling":int(float(r["gk_handling"])) if r.get("gk_handling") else None,
          "gk_kicking":int(float(r["gk_kicking"])) if r.get("gk_kicking") else None,
          "gk_reflexes":int(float(r["gk_reflexes"])) if r.get("gk_reflexes") else None,
          "gk_speed":int(float(r["gk_speed"])) if r.get("gk_speed") else None,
          "gk_positioning":int(float(r["gk_positioning"])) if r.get("gk_positioning") else None,
          "skill_moves":int(float(r["skill_moves"])) if r.get("skill_moves") else None,
          "weak_foot":int(float(r["weak_foot"])) if r.get("weak_foot") else None,
          "preferred_foot":r.get("preferred_foot") or None,
          "playstyles":j(r.get("playstyles"),[]),
          "player_roles":j(r.get("player_roles"),[]),
          "source_url":r.get("source_url") or None,
          "raw_provider_data":j(r.get("raw_provider_data"),{})
        })
    (out/"fc_players_payload.json").write_text(json.dumps(players,ensure_ascii=False,indent=2),encoding="utf-8")
    (out/"fc_player_cards_payload.json").write_text(json.dumps(cards,ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"{len(players)} players, {len(cards)} cards -> {out}")
if __name__=="__main__":main()
