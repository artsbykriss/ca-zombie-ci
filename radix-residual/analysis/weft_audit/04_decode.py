#!/usr/bin/env python3
"""Decode Weft V2 KVS entries into readable summaries."""
import json, sys

d = json.load(open("weft_all_kvs_live.json"))

def pj(e, side="value"):
    return e[side].get("programmatic_json")

def brief(node, depth=0):
    """compact one-line render"""
    if not isinstance(node, dict):
        return str(node)
    k = node.get("kind")
    if k == "Tuple":
        return "{" + ", ".join(f"{f.get('field_name')}={brief(f, depth+1)}" for f in node.get("fields", [])) + "}"
    if k == "Enum":
        vn = node.get("variant_name")
        if node.get("fields"):
            return f"{vn}(" + ", ".join(brief(f, depth+1) for f in node["fields"]) + ")"
        if node.get("value") is not None:
            return f"{vn}:{node.get('value')}"
        return vn
    if k == "Map":
        return "{" + ", ".join(f"{brief(en['key'],depth+1)}: {brief(en['value'],depth+1)}" for en in node.get("entries", [])) + "}"
    if k in ("Array", "List"):
        return "[" + ", ".join(brief(x, depth+1) for x in node.get("elements", node.get("fields", []))) + "]"
    return f"{node.get('value')}"

name = sys.argv[1] if len(sys.argv) > 1 else "resource_configs"
for e in d[name]["data"]:
    k = pj(e, "key"); v = pj(e, "value")
    keyrepr = brief(k) if k else e["key"].get("raw_hex")
    print(f"[{name}] key={keyrepr}")
    print(f"   value={brief(v)[:1600]}")
    try:
        print(f"   hex={e['value']['raw_hex'][:400]}")
    except Exception:
        pass
