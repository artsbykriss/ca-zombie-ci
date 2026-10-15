#!/usr/bin/env python3
"""Re-extract JustLock vault contents with correct NonFungibleVault handling."""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details  # noqa: E402

OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"
id2vault = json.load(open(f"{OUT}/jl_vaults_map.json"))
vaults = list(id2vault.items())
contents = {}
B = 20
for i in range(0, len(vaults), B):
    chunk = vaults[i:i + B]
    addrs = [v for _, v in chunk]
    r = entity_details(addrs, aggregation_level="Global")
    got = {it["address"]: it for it in r["items"]}
    for nid, vaddr in chunk:
        it = got.get(vaddr)
        if it is None:
            contents[nid] = {"error": "not returned"}
            continue
        det = it.get("details", {})
        entry = {"vault": vaddr, "details_type": det.get("type"),
                 "resource": det.get("resource_address")}
        bal = det.get("balance", {})
        if det.get("type") == "FungibleVault":
            entry["amount"] = bal.get("amount")
        elif det.get("type") == "NonFungibleVault":
            entry["total_count"] = bal.get("total_count")
        contents[nid] = entry
    time.sleep(0.15)
json.dump(contents, open(f"{OUT}/jl_vault_contents.json", "w"), indent=1)
nz = {k: v for k, v in contents.items()
      if v.get("amount") not in (None, "0") or v.get("total_count")}
print("with content:", len(nz))
