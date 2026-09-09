#!/usr/bin/env python3
"""Validate a normalized FC27 CSV without inventing missing data."""
import argparse,csv,json,sys
from pathlib import Path
def main():
    ap=argparse.ArgumentParser(); ap.add_argument("csv"); ap.add_argument("--expected-total",type=int)
    a=ap.parse_args()
    with open(a.csv,encoding="utf-8-sig",newline="") as f: rows=list(csv.DictReader(f))
    ids=[r.get("provider_player_id") for r in rows if r.get("provider_player_id")]
    errors=[]; warnings=[]
    if a.expected_total is not None and len(rows)!=a.expected_total: errors.append(f"row count {len(rows)} != expected {a.expected_total}")
    if len(ids)!=len(set(ids)): errors.append("duplicate provider_player_id")
    for i,r in enumerate(rows,2):
        if not r.get("name"): errors.append(f"line {i}: missing name")
        try:
            o=int(float(r["rating"]))
            if not 1<=o<=99: errors.append(f"line {i}: rating out of range {o}")
        except: errors.append(f"line {i}: invalid rating")
    if any(not r.get("player_roles") or r.get("player_roles") in ("[]","") for r in rows):
        warnings.append("player_roles contains missing values; expected until a trustworthy player-specific FC27 role source is available")
    report={"rows":len(rows),"unique_provider_player_ids":len(set(ids)),"errors":errors[:500],"warnings":warnings}
    print(json.dumps(report,indent=2,ensure_ascii=False))
    sys.exit(1 if errors else 0)
if __name__=="__main__": main()
