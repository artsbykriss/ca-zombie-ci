#!/usr/bin/env python3
"""Synchronized snapshot round: fine + nSigFigs 2/3/4 books for BTC & ETH, timestamped.
Read-only public API. Saves into analysis/ only."""
import json, time, urllib.request, datetime

BASE = "https://api.hyperliquid.xyz/info"
UA = "Mozilla/5.0 (X11; Linux x86_64) papertrade-research/1.0"

def post(payload, timeout=30):
    req = urllib.request.Request(
        BASE, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": UA}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def utcnow():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")

def main():
    round_start = utcnow()
    allv = {"round_start_utc": round_start, "variants": {}}
    fine = {}
    for coin in ("BTC", "ETH"):
        for tag, extra in (("fine", {}), ("ns4", {"nSigFigs": 4}),
                           ("ns3", {"nSigFigs": 3}), ("ns2", {"nSigFigs": 2})):
            t0 = time.time()
            p = {"type": "l2Book", "coin": coin}
            p.update(extra)
            b = post(p)
            rec = {"coin": coin, "variant": tag, "fetched_at_utc": utcnow(),
                   "fetch_latency_s": round(time.time() - t0, 4),
                   "request": p, "api_time_ms": b.get("time"), "response": b}
            allv["variants"][f"{coin}_{tag}"] = rec
            if tag == "fine":
                fine[coin] = rec
            time.sleep(0.1)
    round_end = utcnow()
    allv["round_end_utc"] = round_end
    with open("/home/heisenberg/CA/papertrade/analysis/child3-depthvariants.json", "w") as f:
        json.dump(allv, f, indent=1)
    # canonical fine books (per task spec): raw l2Book responses
    for coin, rec in fine.items():
        with open(f"/home/heisenberg/CA/papertrade/analysis/child3-books-{coin}.json", "w") as f:
            json.dump(rec, f, indent=1)
    print("round", round_start, "->", round_end)
    for k, rec in allv["variants"].items():
        lv = rec["response"]["levels"]
        print(k, rec["fetched_at_utc"], "ask_top", lv[1][0]["px"], "bid_top", lv[0][0]["px"],
              "levels", len(lv[0]), len(lv[1]))

if __name__ == "__main__":
    main()
