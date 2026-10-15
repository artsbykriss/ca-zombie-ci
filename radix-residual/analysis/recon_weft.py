#!/usr/bin/env python3
"""Recon: Weft V2 live state - lending pool, lending market, resource pools KVS."""
import json
from rdx import *

POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"
KVS = "internal_keyvaluestore_rdx1kzjr763caq96j0kv883vy8gnf3jvrrp7dfm9zr5n0akryvzsxvyujc"

# full details
r = entity_details([POOL, MARKET], opt_ins={"explicit_metadata": ["name", "symbol", "description", "dapp_definitions", "tags"]})
json.dump(r, open("weft_entities.json", "w"), indent=1)
for it in r["items"]:
    d = it.get("details", {})
    print("=" * 90)
    print(it["address"], "|", d.get("blueprint_name"), d.get("blueprint_version"), "| pkg:", d.get("package_address"))
    st = d.get("state", {})
    print("state fields:")
    for f in st.get("fields", []):
        v = json.dumps(f.get("value"))[:220]
        print("   ", f.get("field_name"), "=", v)
    fr = it.get("fungible_resources", {})
    print("fungibles:", len(fr.get("items", [])))
    tot_nonzero = [x for x in fr.get("items", []) if float(x["amount"]) > 0]
    print("nonzero:", len(tot_nonzero))
    for x in tot_nonzero[:20]:
        print("   ", x["resource_address"], x["amount"])

# resource pools KVS
keys = kvs_keys(KVS)
print("KVS keys:", len(keys))
data = kvs_data(KVS, keys[:100])
json.dump(data, open("weft_resourcepools_kvs.json", "w"), indent=1)
print("entries:", len(data.get("entries", [])))
for e in data.get("entries", [])[:3]:
    print(json.dumps(e)[:600])
