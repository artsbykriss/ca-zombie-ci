#!/usr/bin/env python3
"""Fetch metadata for all Weft-relevant resources: names, symbols, supply."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details

d = json.load(open("weft_all_kvs_live.json"))
ents = json.load(open("weft_entities_live.json"))

addrs = set()
# market + pool held fungibles
for it in ents["items"]:
    for x in it.get("fungible_resources", {}).get("items", []):
        addrs.add(x["resource_address"])
# resource configs keys
for e in d["resource_configs"]["data"]:
    addrs.add(json.loads(json.dumps(e["key"])).get("programmatic_json", {}).get("value") or e["key"].get("raw_hex"))
# the above is wrong for keys; instead re-fetch raw keys programmatically
addrs = {a for a in addrs if a and a.startswith("resource_")}

def key_addr(e):
    pj = e["key"].get("programmatic_json")
    if pj and pj.get("kind") != "Enum":
        return pj.get("value")
    if pj and pj.get("variant_name") in ("Current", "History"):
        return pj.get("fields", [{}])[-1].get("value") if pj.get("fields") else None
    return None

for name in ("resource_configs", "collateral_assets", "price_cache", "resource_type_cache", "liquidation_fees"):
    for e in d.get(name, {}).get("data", []):
        # keys are resource addresses in various encodings; parse raw_hex if needed
        try:
            a = key_addr(e)
        except Exception:
            a = None
        # for price_cache the key is raw resource address string in hex; decode
        if not a and e["key"].get("programmatic_json") is None:
            hexs = e["key"]["raw_hex"]
            # resource address sbor: 0x58 + 0x80 + 29 bytes; address encoding: node id 1 byte + 29
            if hexs.startswith("58"):
                import bech32  # may not exist
            a = None
        if a and a.startswith("resource_"):
            addrs.add(a)
# deposit unit resources
for e in d["pool_resource_pools"]["data"]:
    v = e["value"]["programmatic_json"]
    for f in v.get("fields", []):
        if f.get("field_name") == "deposit_unit_res_address":
            addrs.add(f["value"])

print("distinct resources:", len(addrs))
out = {}
items = sorted(addrs)
for i in range(0, len(items), 20):
    batch = items[i:i+20]
    try:
        r = entity_details(batch, opt_ins={"explicit_metadata": ["name", "symbol", "description", "icon_url", "info"]})
        for it in r["items"]:
            meta = {}
            for m in it.get("metadata", {}).get("items", []):
                tv = m.get("value", {}).get("typed", {})
                if isinstance(tv, dict) and "value" in tv:
                    meta[m["key"]] = tv["value"]
            out[it["address"]] = {"metadata": meta}
    except Exception as e:
        print("batch fail", i, e)
json.dump(out, open("weft_resource_metadata.json", "w"), indent=1)
for a, v in sorted(out.items()):
    m = v.get("metadata", {})
    print(f"{a} | {m.get('symbol')} | {m.get('name')} | {str(m.get('description'))[:60]}")
