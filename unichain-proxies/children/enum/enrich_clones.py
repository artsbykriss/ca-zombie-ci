#!/usr/bin/env python3
"""For each candidate ImmutableProxy address, fetch contract detail + address detail.
READ-ONLY. Saves enriched records to ci-out/clones_raw.json.
"""
import json, time, os, sys
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

H = {"User-Agent": "Mozilla/5.0 (research; read-only)"}
BASE = "https://unichain.blockscout.com/api/v2"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ci-out")
os.makedirs(OUT, exist_ok=True)

def get(url, params=None, tries=6):
    for i in range(tries):
        try:
            r = requests.get(url, headers=H, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            if r.status_code == 404:
                return None
            time.sleep(1.2 * (i + 1))
        except Exception:
            time.sleep(1.2 * (i + 1))
    return None

def enrich(addr):
    sc = get(f"{BASE}/smart-contracts/{addr}")
    ad = get(f"{BASE}/addresses/{addr}")
    rec = {"address": addr}
    if sc:
        rec["constructor_args"] = sc.get("constructor_args")
        rec["creation_bytecode"] = sc.get("creation_bytecode")
        rec["deployed_bytecode"] = sc.get("deployed_bytecode")
        rec["compiler_version"] = sc.get("compiler_version")
        rec["verified_at"] = sc.get("verified_at")
        rec["decoded_constructor_args"] = sc.get("decoded_constructor_args")
    if ad:
        rec["creator"] = ad.get("creator_address_hash")
        rec["creation_tx"] = ad.get("creation_transaction_hash")
        rec["coin_balance"] = ad.get("coin_balance")
        rec["name"] = ad.get("name")
        rec["has_token_transfers"] = ad.get("has_token_transfers")
        rec["has_tokens"] = ad.get("has_tokens")
    return rec

if __name__ == "__main__":
    items = json.load(open(os.path.join(OUT, "search_ImmutableProxy.json")))
    addrs = [it["address"]["hash"] for it in items]
    print("candidates", len(addrs))
    recs = []
    with ThreadPoolExecutor(max_workers=8) as ex:
        futs = {ex.submit(enrich, a): a for a in addrs}
        done = 0
        for f in as_completed(futs):
            try:
                recs.append(f.result())
            except Exception as e:
                recs.append({"address": futs[f], "error": str(e)})
            done += 1
            if done % 25 == 0:
                print("done", done)
    recs.sort(key=lambda r: r["address"].lower())
    with open(os.path.join(OUT, "clones_raw.json"), "w") as f:
        json.dump(recs, f, indent=1)
    print("saved", len(recs))
    # summarize impls
    import collections
    impls = collections.Counter((r.get("constructor_args") or "NONE")[-40:] for r in recs)
    print("impl (last 40 of constructor_args):")
    for k, v in impls.most_common():
        print(" ", k, v)
    creators = collections.Counter(r.get("creator") for r in recs)
    print("creators:")
    for k, v in creators.most_common(10):
        print(" ", k, v)
