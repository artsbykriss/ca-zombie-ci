#!/usr/bin/env python3
"""Probe: next page of pool sigs past the 40k cap + full vlist sig list (creation anchor)."""
import json, time, urllib.request, sys

URL = "https://api.mainnet-beta.solana.com"

def post(method, params, timeout=50):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def call(name, params, tries=30):
    for i in range(tries):
        try:
            d = post("getSignaturesForAddress", params)
            if "result" in d:
                return d["result"]
            print(name, "try", i, str(d.get("error"))[:80], flush=True)
        except Exception as e:
            print(name, "try", i, "exc", str(e)[:80], flush=True)
        time.sleep(min(40, 8 + i * 3))
    return None

POOL = "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG"
VLIST = "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821"

db = json.load(open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json"))
pool_sigs = db["pool"]["sigs"]
last_sig = pool_sigs[-1]["signature"]
print("continuing pool from slot", pool_sigs[-1]["slot"], "bt", pool_sigs[-1]["blockTime"])

page = call("pool41", [POOL, {"limit": 1000, "before": last_sig}])
if page is not None:
    print("pool41 count:", len(page), "oldest slot", page[-1]["slot"], "bt", page[-1]["blockTime"])
    pool_sigs.extend(page)
    db["pool"]["sigs"] = pool_sigs
    json.dump(db, open("/home/heisenberg/CA/phase-stake/analysis/mb_sigs.json", "w"), indent=1)

time.sleep(3)
vsigs = call("vlist", [VLIST, {"limit": 1000}])
if vsigs is not None:
    print("vlist sigs:", len(vsigs))
    for s in vsigs[:5]:
        print("  head", s["slot"], s["blockTime"], s["err"])
    for s in vsigs[-5:]:
        print("  tail", s["slot"], s["blockTime"], s["err"])
    json.dump(vsigs, open("/home/heisenberg/CA/phase-stake/analysis/mb_vlist_sigs.json", "w"), indent=2)
