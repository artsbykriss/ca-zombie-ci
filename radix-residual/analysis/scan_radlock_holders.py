#!/usr/bin/env python3
"""Scan recent RadLock-listed resources' holders for components; identify RadLock locker."""
import json
import sys
from rdx import post, entity_details

RADLOCK_PKG = "package_rdx1pk65frtcahcv0tnllnmucshajj7jl2q3nga0ds9de900nh9yc7vtsq"

resources = [l.strip() for l in open("/tmp/opencode/radlock_recent_resources.txt") if l.strip()]
print("resources:", len(resources))

def all_holders(resource):
    items = []
    cursor = None
    while True:
        body = {"resource_address": resource}
        if cursor:
            body["cursor"] = cursor
        r = post("/extensions/resource-holders/page", body)
        items.extend(r.get("items", []))
        cursor = r.get("next_cursor")
        if not cursor:
            break
    return items

cands = {}
try:
    done = json.load(open("radlock_scan_progress.json"))
except Exception:
    done = {}
for i, res in enumerate(resources):
    if res in done:
        continue
    try:
        hs = all_holders(res)
    except Exception as e:
        print("ERR", res, str(e)[:120])
        continue
    comps = [h["holder_address"] for h in hs if h["holder_address"].startswith(("component_rdx1", "pool_rdx1"))]
    done[res] = comps
    if i % 20 == 0:
        json.dump(done, open("radlock_scan_progress.json", "w"), indent=1)
        print(f"[{i}/{len(resources)}] {res[:30]} holders={len(hs)} comps={len(comps)}")
json.dump(done, open("radlock_scan_progress.json", "w"), indent=1)

allc = sorted({c for v in done.values() for c in v})
print("unique component holders:", len(allc))
json.dump(allc, open("radlock_all_component_holders.json", "w"), indent=1)

# fetch details and find the RadLock ones
found = []
for i in range(0, len(allc), 20):
    r = entity_details(allc[i:i+20], opt_ins={"explicit_metadata": ["name", "dapp_definitions"]})
    for it in r["items"]:
        d = it.get("details", {})
        if d.get("package_address") == RADLOCK_PKG:
            found.append({"address": it["address"], "blueprint": d.get("blueprint_name"), "version": d.get("blueprint_version"), "state": d.get("state")})
            print("*** RADLOCK COMPONENT:", it["address"], d.get("blueprint_name"))
json.dump(found, open("radlock_components_found.json", "w"), indent=1)
print("radlock components found:", len(found))
