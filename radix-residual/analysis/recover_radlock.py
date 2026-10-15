#!/usr/bin/env python3
"""Recover RadLock locker components: scan holders of RadLock-listed resources."""
import json
from rdx import post, entity_details

RADLOCK_PKG = "package_rdx1pk65frtcahcv0tnllnmucshajj7jl2q3nga0ds9de900nh9yc7vtsq"


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


resources = json.load(open("radlock_locked_resources.json")) if False else [
    # from archived app.radlock.io insights pages
    "resource_rdx1t40gu7xfffcc723ylrfq7gw7g94v9qjsq7e49ue8r07afz0q2v4qjx",
]

cands = set()
for res in resources:
    hs = all_holders(res)
    print(res, "holders:", len(hs))
    for h in hs:
        a = h["holder_address"]
        if a.startswith(("component_rdx1", "pool_rdx1")):
            cands.add(a)
print("component/pool holders:", len(cands))
json.dump(sorted(cands), open("radlock_candidate_holders.json", "w"), indent=1)

# fetch details in batches
found = []
cands = sorted(cands)
for i in range(0, len(cands), 20):
    r = entity_details(cands[i:i+20], opt_ins={"explicit_metadata": ["name"]})
    for it in r["items"]:
        d = it.get("details", {})
        rec = {
            "address": it["address"],
            "blueprint": d.get("blueprint_name"),
            "version": d.get("blueprint_version"),
            "package": d.get("package_address"),
        }
        md = it.get("metadata", {}).get("items", [])
        for m in md:
            if m.get("key") == "name":
                rec["name"] = m.get("value", {}).get("typed", {}).get("value")
        found.append(rec)

json.dump(found, open("radlock_holder_components.json", "w"), indent=1)
for f in found:
    print(f.get("blueprint"), "|", f.get("name"), "|", f["address"], "|", f["package"])
