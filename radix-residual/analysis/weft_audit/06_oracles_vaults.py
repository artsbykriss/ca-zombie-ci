#!/usr/bin/env python3
"""Fetch oracle/feed components + complete fungible inventory (paginated) + liquidity vaults."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import *

FEEDS = {
    "default_pricefeed": "component_rdx1czdvvanvdy6495phfgz8uv6n2semp2cpexcg6vvty6uaycc82adgyv",   # feed id 1
    "lsu_pricefeed": "component_rdx1cptmek76m0xuw3etvdqttvgtcu99lvz84jh9q8zleaj3vc5elk4epc",       # feed id 2
    "default_pricefeed2": "component_rdx1czptvkuzjnpj6xudw769zw7r3qvj2vezcll7x05khhns0c4qd24mh7",  # feed id 3
}
POOL = "component_rdx1czmr02yl4da709ceftnm9dnmag7rthu0tu78wmtsn5us9j02d9d0xn"
MARKET = "component_rdx1cpy6putj5p7937clqgcgutza7k53zpha039n9u5hkk0ahh4stdmq4w"

r = entity_details(list(FEEDS.values()))
json.dump(r, open("weft_feeds_live.json", "w"), indent=1)
for it in r["items"]:
    det = it["details"]
    name = [k for k, v in FEEDS.items() if v == it["address"]][0]
    print("=" * 110)
    print(name, it["address"], "|", det.get("blueprint_name"), det.get("blueprint_version"), "| pkg:", det.get("package_address"))
    for f in det.get("state", {}).get("fields", []):
        print("  FIELD", f.get("field_name"), "=", json.dumps(f)[:1200])
    for ra in det.get("role_assignments", {}).get("entries", []):
        rk = ra["role_key"]["name"]
        rr = ra["assignment"].get("explicit_rule") or {}
        print("  role=", rk, json.dumps(rr)[:300])

# full paginated fungibles for POOL and MARKET
for addr, tag in ((POOL, "pool"), (MARKET, "market")):
    items = fungibles(addr)
    json.dump(items, open(f"weft_{tag}_fungibles_full.json", "w"), indent=1)
    print(f"### {tag} full fungibles: {len(items)}")
    for x in items:
        print(f"   {x['resource_address']} = {x['amount']}")

# liquidity vaults from pool_resource_pools
d = json.load(open("weft_all_kvs_live.json"))
vaults = []
for e in d["pool_resource_pools"]["data"]:
    v = e["value"]["programmatic_json"]
    for f in v.get("fields", []):
        if f.get("field_name") == "liquidity":
            vaults.append(f["value"])
print("liquidity vaults:", len(vaults))
r = entity_details(vaults)
json.dump(r, open("weft_liquidity_vaults.json", "w"), indent=1)
for it in r["items"]:
    det = it.get("details", {})
    st = det.get("state", {}).get("fields", [])
    res = it.get("fungible_resources", {}).get("items", [])
    print("VAULT", it["address"], det.get("blueprint_name"), "->", [(x["resource_address"][:40], x["amount"]) for x in res])
