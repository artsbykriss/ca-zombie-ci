#!/usr/bin/env python3
"""Extract function/method signatures from blueprint definitions."""
import json

d = json.load(open("weft_packages_live.json"))
for it in d["items"]:
    det = it.get("details", {})
    for b in det.get("blueprints", {}).get("items", []):
        defs = b.get("definition", {})
        iface = defs.get("interface", {})
        print("=" * 110)
        print(it["address"], "|", b["name"], b["version"])
        print("iface keys:", list(iface.keys()))
        for fn in iface.get("functions", []):
            print("  FN ", fn["name"], "| inputs:", json.dumps(fn.get("inputs", []))[:300], "| output:", json.dumps(fn.get("output"))[:200])
        for m in iface.get("methods", []):
            print("  MTH", m["name"], "| inputs:", json.dumps(m.get("inputs", []))[:300], "| output:", json.dumps(m.get("output"))[:200])
