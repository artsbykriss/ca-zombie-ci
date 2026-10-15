#!/usr/bin/env python3
"""Resolve market method input fields from package definitions (for manifest building)."""
import json

d = json.load(open("weft_packages_live.json"))

def resolve(lid, types, depth=0):
    if depth > 6:
        return "..."
    kind = lid.get("kind")
    if kind == "WellKnown":
        wk = lid.get("well_known_type_id") or {}
        return wk.get("name") or wk.get("type_name") or "WellKnown"
    i = lid.get("id")
    tid = types.get(str(i))
    if tid is None:
        return f"#{i}"
    k = tid.get("kind")
    nm = tid.get("name")
    if k == "Tuple":
        return nm or "Tuple"
    if k == "Enum":
        return (nm or "Enum") + "{" + "|".join(v.get("variant_name", "?") for v in tid.get("variants", [])) + "}"
    if k == "Array":
        return "Array<...>"
    return nm or k

def field_type(f, types):
    """f is input field with 'type' (TypeRef) or 'field_type_ref'"""
    t = f.get("type")
    if t is None:
        t = {"type": "Static", "type_id": f.get("field_type_ref", {})}
    if t.get("type") == "Static":
        return resolve(t["type_id"]["local_type_id"], types)
    return t.get("type")

def dump_type(index, types, indent=2, seen=None):
    """recursively dump tuple/enum fields"""
    if seen is None:
        seen = set()
    tid = types.get(str(index))
    if not tid or index in seen:
        return
    seen.add(index)
    pad = " " * indent
    k = tid.get("kind")
    if k == "Tuple":
        print(f"{pad}Tuple#{index} {tid.get('name')}")
        for f in tid.get("fields", []):
            ft = field_type(f, types)
            fid = f.get("field_type_ref", {}).get("type_id", {}).get("local_type_id", {}).get("id") if "field_type_ref" in f else f.get("type", {}).get("type_id", {}).get("local_type_id", {}).get("id")
            print(f"{pad}  {f.get('field_name')}: {ft}" + (f"  [#{fid}]" if fid is not None else ""))
            if fid is not None and isinstance(fid, int):
                dump_type(fid, types, indent + 4, seen)
    elif k == "Enum":
        print(f"{pad}Enum#{index} {tid.get('name')}")
        for v in tid.get("variants", []):
            print(f"{pad}  variant {v.get('variant_name')}")
            for f in v.get("fields", []):
                ft = field_type(f, types)
                fid = f.get("field_type_ref", {}).get("type_id", {}).get("local_type_id", {}).get("id") if "field_type_ref" in f else None
                print(f"{pad}    {f.get('field_name')}: {ft}" + (f"  [#{fid}]" if fid is not None else ""))
                if fid is not None:
                    dump_type(fid, types, indent + 6, seen)

TARGETS = ["create_cdp", "add_collateral", "borrow", "repay", "get_price", "get_cdp", "liquidate", "remove_collateral", "cdp_batch_operation", "update_cdp", "flash_add_collateral", "flash_remove_collateral", "refinance", "burn_cdp"]
for it in d["items"]:
    if "pktdrmwan4mcugates" not in it["address"]:
        continue
    b = it["details"]["blueprints"]["items"][0]
    iface = b["definition"]["interface"]
    types = iface["types"]
    for fname, fdef in iface["functions"].items():
        if fname not in TARGETS:
            continue
        inp = fdef.get("input", {})
        print("=" * 100)
        print("FN", fname)
        lid = inp.get("type_id", {}).get("local_type_id", {})
        if lid.get("kind") == "WellKnown":
            print("   input wellknown:", lid.get("well_known_type_id"))
        else:
            dump_type(lid.get("id"), types)
        out = fdef.get("output", {})
        olid = out.get("type_id", {}).get("local_type_id", {})
        if olid.get("kind") == "WellKnown":
            print("   output wellknown:", olid.get("well_known_type_id"))
        else:
            print("   output type#", olid.get("id"), types.get(str(olid.get("id")), {}).get("name"))
