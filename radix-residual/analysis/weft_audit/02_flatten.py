#!/usr/bin/env python3
"""Flatten Weft V2 component state recursively; dump role assignments; collect KVS/vault addresses."""
import json, sys
sys.path.insert(0, "/home/heisenberg/CA/radix-residual/analysis")

def flatten(node, prefix="", out=None):
    if out is None:
        out = []
    kind = node.get("kind")
    if kind == "Tuple":
        tn = node.get("type_name", "?")
        # print nested structs with type names stripped of "<...>"
        base = tn.split("<")[0]
        for f in node.get("fields", []):
            flatten(f, f"{prefix}{node.get('field_name','')}.{f.get('field_name')}" if prefix or node.get('field_name') else f.get("field_name"), out)
    elif kind == "Enum":
        vn = node.get("variant_name")
        if node.get("fields"):
            for f in node.get("fields", []):
                flatten(f, f"{prefix}[{vn}].{f.get('field_name')}", out)
        else:
            out.append((prefix, f"Enum::{vn}"))
    elif kind == "Map":
        for e in node.get("entries", []):
            k = e.get("key", {})
            kv = k.get("value", k.get("variant_name", "?"))
            flatten(e.get("value", {}), f"{prefix}[{kv}]", out)
    elif kind == "Array" or kind == "List":
        for i, f in enumerate(node.get("elements", node.get("fields", []))):
            flatten(f, f"{prefix}[{i}]", out)
    else:
        out.append((prefix, f"{kind}:{node.get('type_name','')}={node.get('value')}"))
    return out

def walk_collect(node, addrs, kind_filter=None):
    """Collect all Own/Reference addresses of given kinds."""
    k = node.get("kind")
    if k in ("Own", "Reference") and node.get("value"):
        tn = node.get("type_name", "")
        if kind_filter is None or tn in kind_filter:
            addrs.append((node.get("field_name"), tn, node["value"]))
    for f in node.get("fields", []) or []:
        walk_collect(f, addrs, kind_filter)
    for e in node.get("entries", []) or []:
        walk_collect(e.get("key", {}), addrs, kind_filter)
        walk_collect(e.get("value", {}), addrs, kind_filter)
    for e in node.get("elements", []) or []:
        walk_collect(e, addrs, kind_filter)
    return addrs

def main():
    d = json.load(open("weft_entities_live.json"))
    for it in d["items"]:
        det = it["details"]
        print("=" * 110)
        print(it["address"], "|", det.get("blueprint_name"), det.get("blueprint_version"), "| pkg:", det.get("package_address"))
        print("-" * 40, "STATE (flattened)")
        for f in det.get("state", {}).get("fields", []):
            for path, val in flatten(f, f.get("field_name")):
                print(f"  {path} = {val}")
        print("-" * 40, "ROLES")
        for ra in det.get("role_assignments", {}).get("entries", []):
            rk = ra["role_key"]["name"]
            rr = ra["assignment"].get("explicit_rule") or ra["assignment"].get("owner_rule", {})
            typ = rr.get("type")
            extra = ""
            if typ == "Protected":
                ar = rr.get("access_rule", {})
                extra = json.dumps(ar.get("proof_rule") or ar.get("any_of") or ar)[:200]
            print(f"  role={rk} rule={typ} {extra} resolution={ra['assignment'].get('resolution')} updaters={[u['name'] for u in ra.get('updater_roles', [])]}")
        print("-" * 40, "OWNED ADDRESSES")
        for f in det.get("state", {}).get("fields", []):
            for name, tn, val in walk_collect(f, []):
                if tn in ("KeyValueStore", "NonFungibleVault", "FungibleVault", "Vault"):
                    print(f"  {name} [{tn}] = {val}")

if __name__ == "__main__":
    main()
