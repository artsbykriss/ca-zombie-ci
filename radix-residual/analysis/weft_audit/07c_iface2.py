#!/usr/bin/env python3
"""Resolve Weft blueprint interfaces into readable signatures using interface.types."""
import json

d = json.load(open("weft_packages_live.json"))

def type_ref(t, types):
    if not isinstance(t, dict):
        return str(t)
    if t.get("type") == "Static":
        lid = t.get("type_id", {}).get("local_type_id", {})
        return resolve_local(lid, types)
    if t.get("type") == "Generic":
        return f"Generic[{t.get('generic_type_id')}]"
    return json.dumps(t)[:80]

def resolve_local(lid, types):
    kind = lid.get("kind")
    if kind == "WellKnown":
        return lid.get("well_known_type_id") or lid.get("name") or "WellKnown?"
    i = lid.get("id")
    tid = types.get(str(i)) or types.get(i)
    if tid is None:
        return f"type#{i}"
    if isinstance(tid, dict):
        nm = tid.get("name") or tid.get("kind")
        k = tid.get("kind")
        if k == "Tuple":
            inner = ", ".join(type_ref(f.get("type") if "type" in f else {"type": "Static", "type_id": f.get("field_type_ref", {})}, types) for f in tid.get("fields", []))
            return f"{nm}({inner})" if nm else f"Tuple({inner})"
        if k == "Enum":
            variants = []
            for v in tid.get("variants", []):
                vn = v.get("variant_name")
                inner = ", ".join(type_ref(f.get("type") if "type" in f else {"type": "Static", "type_id": f.get("field_type_ref", {})}, types) for f in v.get("fields", []))
                variants.append(f"{vn}({inner})" if inner else vn)
            return "|".join(variants) if not nm else f"{nm}{{{'|'.join(variants)}}}"
        if k in ("Array", "List"):
            et = tid.get("element_type") or tid.get("element_type_ref") or {}
            return f"Array<{type_ref(et, types)}>"
        if k in ("Map",):
            return "Map"
        if nm:
            return nm
        return k or f"type#{i}"
    return str(tid)[:60]

for it in d["items"]:
    det = it.get("details", {})
    for b in det.get("blueprints", {}).get("items", []):
        defs = b.get("definition", {})
        iface = defs.get("interface", {})
        types = iface.get("types", {})
        print("=" * 110)
        print(it["address"], "|", b["name"], b["version"], "| #types:", len(types))
        for fname, fdef in iface.get("functions", {}).items():
            inp = fdef.get("input", {})
            itypes = ", ".join(type_ref(f["type"], types) + " " + f.get("name", "?") for f in inp.get("fields", [])) if inp else ""
            out = type_ref(fdef.get("output", {}), types) if fdef.get("output") else "()"
            print(f"  FN  {fname}({itypes}) -> {out}")
