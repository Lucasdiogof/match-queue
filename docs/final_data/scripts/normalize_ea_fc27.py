#!/usr/bin/env python3
"""Normalize EA Drop API `items` into a provider-neutral FC27 CSV/JSON."""
from __future__ import annotations
import argparse, json, csv
from pathlib import Path
from datetime import date, datetime, timezone

ALIASES={
"pace":["pac","pace"],"shooting":["sho","shooting"],"passing":["pas","passing"],
"dribbling":["dri","dribbling"],"defending":["def","defending"],"physical":["phy","physicality","physical"],
"acceleration":["acceleration"],"sprint_speed":["sprintSpeed"],"finishing":["finishing"],
"shot_power":["shotPower"],"long_shots":["longShots"],"volleys":["volleys"],"penalties":["penalties"],
"positioning":["attPosition","positioning"],"vision":["vision"],"crossing":["crossing"],
"free_kick_accuracy":["freeKickAccuracy","fkAccuracy"],"short_passing":["shortPassing"],
"long_passing":["longPassing"],"curve":["curve"],"agility":["agility"],"balance":["balance"],
"reactions":["reactions"],"ball_control":["ballControl"],"composure":["composure"],
"interceptions":["interceptions"],"heading_accuracy":["headingAccuracy"],
"defensive_awareness":["defensiveAwareness","marking"],"standing_tackle":["standingTackle"],
"sliding_tackle":["slidingTackle"],"jumping":["jumping"],"stamina":["stamina"],"strength":["strength"],
"aggression":["aggression"],"gk_diving":["gkDiving"],"gk_handling":["gkHandling"],
"gk_kicking":["gkKicking"],"gk_positioning":["gkPositioning"],"gk_reflexes":["gkReflexes"],
"gk_speed":["gkSpeed"]
}
def val(stats,key):
    x=(stats or {}).get(key)
    if isinstance(x,dict): return x.get("value")
    return x
def pick(stats,keys):
    for k in keys:
        x=val(stats,k)
        if x is not None: return x
def foot(x):
    if x in (1,"1"): return "Right"
    if x in (2,"2"): return "Left"
    if isinstance(x,str) and x: return x.title()
def iso_birth(x):
    if not x:return None
    s=str(x)
    if len(s)>=10 and s[4]=="-" and s[7]=="-": return s[:10]
    for fmt in ("%m/%d/%Y","%d/%m/%Y"):
        try:return datetime.strptime(s[:10],fmt).date().isoformat()
        except:pass
    return s
def age(dob):
    if not dob:return None
    try:
        d=date.fromisoformat(dob); today=date.today()
        return today.year-d.year-((today.month,today.day)<(d.month,d.day))
    except:return None
def arr(v):
    return v if isinstance(v,list) else []
def normalize(r):
    stats=r.get("stats") or {}
    first=r.get("firstName"); last=r.get("lastName"); common=r.get("commonName")
    name=common or " ".join(x for x in (first,last) if x) or None
    pos=(r.get("position") or {})
    primary=pos.get("shortLabel") or pos.get("label")
    alts=[(x or {}).get("shortLabel") or (x or {}).get("label") for x in arr(r.get("alternatePositions"))]
    alts=[x for x in alts if x]
    ps=[]; psp=[]
    for a in arr(r.get("playerAbilities")):
        label=(a or {}).get("label")
        if not label: continue
        if ((a or {}).get("type") or {}).get("id")=="playStylePlus": psp.append(label)
        else: ps.append(label)
    dob=iso_birth(r.get("birthdate"))
    out={
      "source_provider":"EA_DROP_API","provider_player_id":r.get("id"),
      "provider_item_id":r.get("id"),"game_version":"FC27","name":name,"common_name":common,
      "date_of_birth":dob,"age":age(dob),"height_cm":r.get("height"),"weight_kg":r.get("weight"),
      "gender":((r.get("gender") or {}).get("label") if isinstance(r.get("gender"),dict) else r.get("gender")),
      "preferred_foot":foot(r.get("preferredFoot")),
      "weak_foot":r.get("weakFootAbility",r.get("weakFoot")),"skill_moves":r.get("skillMoves"),
      "nation":((r.get("nationality") or {}).get("label") if isinstance(r.get("nationality"),dict) else None),
      "club":((r.get("team") or {}).get("label") if isinstance(r.get("team"),dict) else None),
      "league":r.get("leagueName") or ((r.get("league") or {}).get("label") if isinstance(r.get("league"),dict) else None),
      "primary_position":primary,"alternative_positions":alts,
      "rating":r.get("overallRating"),"playstyles":ps,"playstyles_plus":psp,"player_roles":[],
      "accelerate":None,"card_type":"BASE_LAUNCH","rarity":None,
      "player_image_url":r.get("avatarUrl") or r.get("imageUrl"),"card_image_url":None,
      "source_url":f"https://www.ea.com/games/ea-sports-fc/ratings?playerId={r.get('id')}" if r.get("id") else None,
      "collected_at":datetime.now(timezone.utc).isoformat()
    }
    detail={}
    for k,aliases in ALIASES.items():
        out[k]=pick(stats,aliases) if k in ("pace","shooting","passing","dribbling","defending","physical","gk_diving","gk_handling","gk_kicking","gk_reflexes","gk_speed","gk_positioning") else out.get(k)
        if k not in ("pace","shooting","passing","dribbling","defending","physical","gk_diving","gk_handling","gk_kicking","gk_reflexes","gk_speed","gk_positioning"):
            detail[k]=pick(stats,aliases)
    out["detailed_stats"]=detail
    out["raw_provider_data"]=r
    return out
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("input"); ap.add_argument("--out",default="output/fc27_normalized")
    a=ap.parse_args(); data=json.loads(Path(a.input).read_text(encoding="utf-8"))
    items=data.get("items",data) if isinstance(data,dict) else data
    rows=[normalize(x) for x in items]
    out=Path(a.out); out.mkdir(parents=True,exist_ok=True)
    (out/"fc27_normalized.json").write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding="utf-8")
    columns=list(rows[0].keys()) if rows else []
    with open(out/"fc27_normalized.csv","w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,fieldnames=columns); w.writeheader()
        for r in rows:
            q=r.copy()
            for k in ("alternative_positions","playstyles","playstyles_plus","player_roles"):
                q[k]=json.dumps(q[k],ensure_ascii=False)
            for k in ("detailed_stats","raw_provider_data"):
                q[k]=json.dumps(q[k],ensure_ascii=False,separators=(",",":"))
            w.writerow(q)
    print(f"normalized {len(rows)} rows -> {out}")
if __name__=="__main__": main()
