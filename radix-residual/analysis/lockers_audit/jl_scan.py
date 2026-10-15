#!/usr/bin/env python3
"""JustLock locker: full state scan (read-only Gateway reads).

Dumps:
  jl_component_state.json  - component fungibles/nonfungibles + top-level fields
  jl_vaults_map.json       - lock id -> internal vault address
  jl_vault_contents.json   - lock id -> vault fungible/nft contents
  jl_receipts_nfdata.json  - receipt id -> NFT data (unlockable_at, unlocked_at, ...)
  jl_receipt_holders.json  - holders of the receipt resource
"""
import json
import sys
import time

sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import post, entity_details, kvs_keys, kvs_data, fungibles, ledger_state  # noqa: E402

COMPONENT = "component_rdx1cpae8nqhyeu2pz6z89vwca8085xels52lhsfrutnvagxz53u3p4yvl"
VAULTS_KVS = "internal_keyvaluestore_rdx1kqvnvkez5u0r7q33x0yt20lau7wmm4wh3mxlrge8548sz2ycw9mpl6"
RECEIPT_RES = "resource_rdx1nfajj55xgl6dm4ecfv9hru2xnr45ydtuuecs7phgvctuarcvzcrkr6"
OUT = "/home/heisenberg/CA/radix-residual/analysis/lockers_audit"

ls = ledger_state()
print("state_version", ls)

# 1. component state
comp = entity_details([COMPONENT], opt_ins={"non_fungible_include_nfdata": True})["items"][0]
comp_fung = fungibles(COMPONENT)
comp["fungible_resources"]["items"] = comp_fung
json.dump({"ledger_state": ls, "component": comp},
          open(f"{OUT}/jl_component_state.json", "w"), indent=1)
print("component fungibles:", len(comp_fung))

# 2. vaults KVS -> map id -> vault address
keys = kvs_keys(VAULTS_KVS)
print("kvs keys:", len(keys))
id2vault = {}
for i in range(0, len(keys), 100):
    dd = kvs_data(VAULTS_KVS, keys[i:i + 100])
    for e in dd["entries"]:
        nid = e["key"]["programmatic_json"]["value"]
        vault = e["value"]["programmatic_json"]["value"]
        id2vault[nid] = vault
    time.sleep(0.2)
json.dump(id2vault, open(f"{OUT}/jl_vaults_map.json", "w"), indent=1)
print("vault map:", len(id2vault))

# 3. vault contents (batch entity_details)
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
        if det.get("type") == "FungibleVault":
            entry["amount"] = det.get("balance", {}).get("amount")
        elif det.get("type") == "NonFungibleVault":
            entry["nf_ids"] = det.get("non_fungible_ids")
            entry["balance"] = det.get("balance")
        contents[nid] = entry
    time.sleep(0.15)
json.dump(contents, open(f"{OUT}/jl_vault_contents.json", "w"), indent=1)
nonzero = sum(1 for c in contents.values()
              if c.get("fungibles") or c.get("nfts"))
print("vaults with contents:", nonzero, "/", len(contents))

# 4. receipt NFT data for all ids (0..422 = keys; plus any minted beyond kvs keys?)
ids = list(id2vault.keys())
nfdata = {}
for i in range(0, len(ids), 40):
    r = post("/state/non-fungible/data", {
        "resource_address": RECEIPT_RES,
        "non_fungible_ids": ids[i:i + 40],
        "opt_ins": {"non_fungible_include_nfdata": True},
    })
    for it in r.get("non_fungible_ids", []):
        nid = it["non_fungible_id"]
        nfdata[nid] = it
    time.sleep(0.2)
json.dump(nfdata, open(f"{OUT}/jl_receipts_nfdata.json", "w"), indent=1)
print("receipt nfdata:", len(nfdata))

# 5. receipt holders (paged)
holders = []
cursor = None
while True:
    body = {"resource_address": RECEIPT_RES, "limit_per_page": 100}
    if cursor:
        body["cursor"] = cursor
    r = post("/extensions/resource-holders/page", body)
    holders.extend(r.get("items", []))
    cursor = r.get("next_cursor")
    if not cursor:
        break
    time.sleep(0.2)
json.dump(holders, open(f"{OUT}/jl_receipt_holders.json", "w"), indent=1)
print("holders:", len(holders))
