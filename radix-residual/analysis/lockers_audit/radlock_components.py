#!/usr/bin/env python3
"""Independently recover RadLock components: fetch details for all component
holders seen on the 133 archived RadLock resource pages; filter for the
RadLock package."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
RADLOCK_PKG = "package_rdx1pk65frtcahcv0tnllnmucshajj7jl2q3nga0ds9de900nh9yc7vtsq"

allc = json.load(open(f"{OUT}/radlock_all_component_holders_snapshot.json"))
print("candidates:", len(allc))
found = []
B = 20
for i in range(0, len(allc), B):
    chunk = allc[i:i + B]
    r = entity_details(chunk, opt_ins={"explicit_metadata": ["name"]})
    got = {it["address"]: it for it in r["items"]}
    for a in chunk:
        it = got.get(a)
        if not it:
            continue
        d = it.get("details", {})
        rec = {"address": a, "blueprint": d.get("blueprint_name"),
               "package": d.get("package_address")}
        for m in it.get("metadata", {}).get("items", []):
            if m.get("key") == "name":
                rec["name"] = m.get("value", {}).get("typed", {}).get("value")
        found.append(rec)
    time.sleep(0.1)
json.dump(found, open(f"{OUT}/radlock_holder_components_full.json", "w"), indent=1)
hits = [f for f in found if f.get("package") == RADLOCK_PKG]
print("total fetched:", len(found))
print("RADIOCK PKG HITS:", json.dumps(hits, indent=1)[:3000])
from collections import Counter  # noqa: E402
print(Counter(f.get("blueprint") for f in found).most_common(20))
