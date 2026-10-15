#!/usr/bin/env python3
"""Weft V2 audit: re-verify live state at current state version (read-only)."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import *

POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
KVS = "internal_keyvaluestore_rdx1kzjr763caq96j0kv883vy8gnf3jvrrp7dfm9zr5n0akryvzsxvyujc"

ls = ledger_state()
print("LEDGER:", json.dumps(ls))

r = entity_details([POOL, MARKET], opt_ins={"explicit_metadata": ["name", "symbol", "description", "dapp_definitions", "tags"]})
json.dump(r, open("weft_entities_live.json", "w"), indent=1)
print("state_version of fetch:", r["ledger_state"]["state_version"])

for it in r["items"]:
    det = it.get("details", {})
    print("=" * 110)
    print(it["address"])
    print("  blueprint:", det.get("blueprint_name"), det.get("blueprint_version"), "pkg:", det.get("package_address"))
    st = det.get("state", {})
    for f in st.get("fields", []):
        print("   FIELD", f.get("field_name"), "=", json.dumps(f.get("value"))[:400])
    print("  ROLE ASSIGNMENTS:")
    for ra in det.get("role_assignments", []):
        print("   ", json.dumps(ra)[:300])
    fr = it.get("fungible_resources", {}).get("items", [])
    print("  fungibles:", len(fr))
    for x in fr:
        if float(x["amount"]) > 0:
            print("    ", x["resource_address"], float(x["amount"]))

# resource pools KVS at current version
keys = kvs_keys(KVS)
print("resource_pools KVS keys:", len(keys))
data = kvs_data(KVS, keys)
json.dump(data, open("weft_resourcepools_kvs_live.json", "w"), indent=1)
print("entries:", len(data.get("entries", [])))
