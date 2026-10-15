#!/usr/bin/env python3
"""Fetch blueprint definitions (functions, methods) for Weft + feed packages."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")
from rdx import entity_details

PACKAGES = {
    "lending_pool": "package_rdx1p5uwrs3heg37n5zyzate8xtc440l2x3l59ywya4jl2na6em25qjnfj",
    "lending_market": "package_rdx1pktdrmwan4mcugates06wwcvspn4y0hsapm9zkyg4clh0sf8qn7c6t",
    "pricefeed": "package_rdx1ph9czlv50shsth9pu4zfffp69g99uczj6v3kplkh92hzr5phujcddc",
    "lsu_pricefeed_proxy": "package_rdx1p50jftuyvelpedf5cth5qemrfm4nwhrenke60sn8de36tck9anuvj8",
    "pricefeed2": "package_rdx1pk088lw25dn4ah4m28yk8n8czmck8kvp2gzvct74aele6dr5dtjr9d",
}

r = entity_details(list(PACKAGES.values()))
json.dump(r, open("weft_packages_live.json", "w"), indent=1)
for it in r["items"]:
    det = it.get("details", {})
    name = [k for k, v in PACKAGES.items() if v == it["address"]][0]
    bps = det.get("blueprints", {}).get("items", [])
    print("=" * 110)
    print(name, it["address"], "| vm:", det.get("vm_type"), "blueprints:", [(b["name"], b["version"]) for b in bps])
    for b in bps:
        print(f"--- blueprint {b['name']} {b['version']}")
        defs = b.get("definition", {})
        print("    deps:", json.dumps(defs.get("dependencies", []))[:200])
        for fn in defs.get("functions", []):
            print(f"    FN  {fn['name']}({', '.join(i['type_name'] + ':' + i['name'] for i in fn.get('inputs', []))}) -> {fn.get('output', {}).get('type_name')}")
        for m in defs.get("methods", []):
            print(f"    MTH {m['name']}({', '.join(i['type_name'] + ':' + i['name'] for i in m.get('inputs', []))}) -> {m.get('output', {}).get('type_name')}")
