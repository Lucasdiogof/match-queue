#!/usr/bin/env python3
"""
Fetch EA SPORTS FC 27 ratings from EA's machine-readable Drop API.

Important:
- This endpoint may answer 403 depending on client/network policy.
- Nothing in this script bypasses authentication, bot protection, or access controls.
- If EA refuses the request, the script stops and tells you to use an allowed network/client.
- Run again after 2026-09-10 because EA's official ratings site announced a DB update.
"""
from __future__ import annotations
import argparse, json, time, urllib.request, urllib.error
from pathlib import Path
from datetime import datetime, timezone

DEFAULT = "https://drop-api.ea.com/rating/ea-sports-fc-27"
EA_RATINGS = "https://www.ea.com/games/ea-sports-fc/ratings"

def get_json(url: str, timeout: int=30):
    req = urllib.request.Request(url, headers={
        "Accept":"application/json,text/plain,*/*",
        "User-Agent":"Mozilla/5.0 FC27DataResearch/1.0",
        "Referer":EA_RATINGS,
        "Origin":"https://www.ea.com",
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--base",default=DEFAULT)
    ap.add_argument("--locale",default="en")
    ap.add_argument("--limit",type=int,default=100)
    ap.add_argument("--delay",type=float,default=0.35)
    ap.add_argument("--out",default="output/ea_fc27_raw")
    ap.add_argument("--max-pages",type=int)
    args=ap.parse_args()
    out=Path(args.out); out.mkdir(parents=True,exist_ok=True)
    offset=0; pages=0; total=None; all_items=[]
    try:
        while total is None or offset < total:
            url=f"{args.base}?locale={args.locale}&limit={args.limit}&offset={offset}"
            payload=get_json(url)
            items=payload.get("items") or payload.get("results") or []
            if total is None:
                total=payload.get("totalItems") or payload.get("total") or len(items)
                print(f"reported total={total}")
            (out/f"page_{offset:06d}.json").write_text(
                json.dumps(payload,ensure_ascii=False,indent=2),encoding="utf-8")
            all_items.extend(items)
            pages+=1
            print(f"page={pages} offset={offset} rows={len(items)} accumulated={len(all_items)}")
            if not items: break
            offset += len(items)
            if args.max_pages and pages >= args.max_pages: break
            time.sleep(args.delay)
    except urllib.error.HTTPError as e:
        if e.code == 403:
            raise SystemExit(
              "EA returned HTTP 403. This script will not bypass the restriction. "
              "Run it from a network/client where EA allows the public endpoint, "
              "or use the official web ratings pages as the authoritative reference.")
        raise
    meta={
      "source":"EA_DROP_API","collected_at":datetime.now(timezone.utc).isoformat(),
      "reported_total":total,"downloaded_rows":len(all_items),"pages":pages,
      "base":args.base
    }
    (out/"_manifest.json").write_text(json.dumps(meta,indent=2),encoding="utf-8")
    (out/"all_items.json").write_text(json.dumps(all_items,ensure_ascii=False),encoding="utf-8")
    print(json.dumps(meta,indent=2))
if __name__=="__main__": main()
