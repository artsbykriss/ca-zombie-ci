#!/usr/bin/env python3
"""JustLock: receipt ownership map + component role/owner inspection."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
RECEIPT = "resource_rdx1nfajj55xgl6dm4ecfv9hru2xnr45ydtuuecs7phgvctuarcvzcrkr6"
COMPONENT = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"

# 1. full component item (look for role_assignments / details)
r = entity_details([COMPONENT], aggregation_level="Global",
                   opt_ins={"non_fungible_include_nfdata": True})
open(f"{OUT}/jl_component_raw.json", "w").write(json.dumps(r, indent=1))
top = r["items"][0]
print("top keys:", list(top.keys()))
print("details keys:", list(top.get("details", {}).keys()) if top.get("details") else None)
if top.get("details"):
    print(json.dumps(top["details"], indent=1)[:1500])

# 2. receipt resource details (roles/owner/royalty)
rr = entity_details([RECEIPT], aggregation_level="Global")
open(f"{OUT}/jl_receipt_res_raw.json", "w").write(json.dumps(rr, indent=1))
print("receipt res keys:", list(rr["items"][0].keys()))
print(json.dumps(rr["items"][0].get("details"), indent=1)[:800])

# 3. per-holder receipt ids
holders = json.load(open(f"{OUT}/jl_receipt_holders.json"))
print("holders:", len(holders), json.dumps(holders[0])[:200])
owner_map = {}
for h in holders:
    acct = h.get("holder_address") or h.get("address")
    ids = []
    cursor = None
    while True:
        body = {"address": acct, "resource_address": RECEIPT, "limit_per_page": 100}
        if cursor:
            body["cursor"] = cursor
        p = post("/state/entity/page/non-fungibles/", body)
        ids.extend(x["non_fungible_id"] for x in p.get("items", []))
        cursor = p.get("next_cursor")
        if not cursor:
            break
    owner_map[acct] = ids
    time.sleep(0.05)
json.dump(owner_map, open(f"{OUT}/jl_receipt_owner_map.json", "w"), indent=1)
tot = sum(len(v) for v in owner_map.values())
print("receipt ids mapped:", tot)
for k, v in list(owner_map.items()):
    if len(v) > 200:
        print("big holder:", k, len(v))
