#!/usr/bin/env python3
"""Recon: RlyFun launches -> bonding curve components -> XRD balances."""
import json
from rdx import *

RLY_KVS = "internal_keyvaluestore_rdx1krtyftm7ly5fcwj7p9n4ksan9atxcvwhdpg3mnuc42atsdtc5nyu3v"
XRD = "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"

keys = kvs_keys(RLY_KVS)
print("keys:", len(keys))
entries = []
for i in range(0, len(keys), 100):
    data = kvs_data(RLY_KVS, keys[i:i+100])
    entries.extend(data["entries"])
print("entries:", len(entries))
json.dump(entries, open("rlyfun_entries_raw.json", "w"), indent=1)

curves = []
for e in entries:
    try:
        v = e["value"]["programmatic_json"]
        f = v.get("fields", [])
        comp = None
        for ff in f:
            val = ff.get("value")
            if isinstance(val, str) and val.startswith("component_rdx1"):
                comp = val
                break
        curves.append({"key": e["key"]["programmatic_json"], "component": comp, "raw": v})
    except Exception as ex:
        curves.append({"err": str(ex), "raw": json.dumps(e)[:200]})
print("curves extracted:", sum(1 for c in curves if c.get("component")))
json.dump(curves, open("rlyfun_curves.json", "w"), indent=1)

# fetch details for curve components in batches
comps = [c["component"] for c in curves if c.get("component")]
details = []
for i in range(0, len(comps), 20):
    r = entity_details(comps[i:i+20], aggregation_level="Global")
    details.extend(r["items"])
print("curve details:", len(details))
out = []
for it in details:
    xrd = None
    f = it.get("fungible_resources", {}).get("items", [])
    for x in f:
        if x["resource_address"] == XRD:
            xrd = x["amount"]
    out.append({
        "address": it["address"],
        "blueprint": it.get("details", {}).get("blueprint_name"),
        "package": it.get("details", {}).get("package_address"),
        "xrd": xrd,
        "n_fungibles": len(f),
    })
json.dump(out, open("rlyfun_curve_details.json", "w"), indent=1)
tot = sum(float(x["xrd"] or 0) for x in out)
print("curves:", len(out), "total XRD:", tot)
for x in out[:10]:
    print(json.dumps(x))
