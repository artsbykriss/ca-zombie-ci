#!/usr/bin/env python3
"""TASK 2a: fetch full getSignaturesForAddress lists for key Phase YIELD accounts (read-only)."""
import json, sys, time
sys.path.insert(0, "/home/heisenberg/CA/phase-stake/analysis")
from sol_util import rpc

OUT = "/home/heisenberg/CA/phase-stake/analysis/history_sigs.json"
ADDRS = {
    "pool": "phasejkG1akKgqkLvfWzWY17evnH6mSWznnUspmpyeG",
    "reserve": "phaseECAeXantYWXvRGkmeh7ddQsUJTf7DcywquY9Z2",
    "stake8QtQ": "8QtQ1U34DPs2UKQiwUoRPMHnjJedsmdASZdbQHa7VHKh",
    "mint": "phaseZSfPxTDBpiVb96H4XFSD8xHeHxZre5HerehBJG",
    "fee": "GAGMZfQU5ArnaciyQBnDLsEpbbhpyqPR24t98WYL4n6U",
    "manager_pda": "7LqSTwcwHodtrRmPWkptKWraELTW2DpchzRWhdoS4HH1",
    "vlist": "phaseeExd43yGjjad2FZSigdG9UTRpMdxS4aMerx821",
}
MAX_TOTAL = 6000

res = {}
try:
    res = json.load(open(OUT))
except Exception:
    pass

for name, addr in ADDRS.items():
    if name in res and res[name].get("complete"):
        print(name, "already complete:", len(res[name]["sigs"]))
        continue
    sigs = res.get(name, {}).get("sigs", [])
    before = sigs[-1]["signature"] if sigs else None
    complete = False
    while len(sigs) < MAX_TOTAL:
        params = [addr, {"limit": 1000}]
        if before:
            params[1]["before"] = before
        time.sleep(1.3)
        page = rpc("getSignaturesForAddress", params)
        if not page:
            complete = True
            break
        sigs.extend(page)
        if len(page) < 1000:
            complete = True
            break
        before = page[-1]["signature"]
    res[name] = {"address": addr, "sigs": sigs, "complete": complete, "count": len(sigs)}
    json.dump(res, open(OUT, "w"), indent=2)
    if sigs:
        tb0, tb1 = sigs[-1]["blockTime"], sigs[0]["blockTime"]
        errs = sum(1 for s in sigs if s.get("err"))
        print(f"{name}: {len(sigs)} sigs complete={complete} blocktime {tb0}..{tb1} errs={errs} oldest_slot={sigs[-1]['slot']} newest_slot={sigs[0]['slot']}")
    else:
        print(name, "no sigs")

print("saved", OUT)
