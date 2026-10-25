#!/usr/bin/env python3
"""Recon 2: enumerate live accounts of the Streamflow programs (discriminator census)."""
import json, os, sys, base64
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sol import get_program_accounts, get_slot

PROGS = {
    "stake":  "STAKEvGqQTtzJZH6BWDcbpzXXn2BBerPAgQ3EGLN2GH",
    "reward": "RWRDdfRbi3339VgKxTAXg4cjyniF7cbhNbMxZWiSKmj",
    "reward_dyn": "RWRDyfZa6Rk9UYi85yjYYfGmoUqffLqjo6vZdFawEez",
    "vesting": "strmRqUCoQUgGUan5YhzUZa6KqdzwX5L6FpUxfmKg5m",
}
out = {"slot": get_slot(), "programs": {}}
for name, pid in PROGS.items():
    r = get_program_accounts(pid, encoding="base64", dataSlice={"offset": 0, "length": 8})
    if not isinstance(r, list):
        out["programs"][name] = {"error": str(r)[:200]}
        continue
    census = {}
    for a in r:
        disc = a["account"]["data"][0]
        census[disc] = census.get(disc, 0) + 1
    out["programs"][name] = {"count": len(r), "discriminators": census}
    print(name, pid, "count=", len(r))
    for d, c in sorted(census.items(), key=lambda x: -x[1]):
        print("   ", d, c)
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "census.json"), "w") as f:
    json.dump(out, f, indent=1)
