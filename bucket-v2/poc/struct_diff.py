#!/usr/bin/env python3
"""Struct-layout stability check across package versions (READ-ONLY).

For each family, fetch the disassembly of the FIRST and LATEST version, extract every
`struct <Name> has <abilities> { fields }`, and report which structs changed. A struct
that changed layout means old code CANNOT operate on objects created/updated by the new
code (the layout gate), which is the exploitability condition for the version/import
primitive. A struct that is identical across all versions means the layout gate does NOT
protect the old code.

Public GraphQL only. Output -> ci-out/struct_diff.json
"""
import json, os, re, urllib.request, datetime

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
OUT = os.environ.get("OUTDIR", os.path.join(os.path.dirname(__file__), "..", "ci-out"))
FAMILIES = {
    "dipcoin":      "0x978fed071cca22dd26bec3cf4a5d5a00ab10f39cb8c659bbfdfbec4397241001",
    "bluefin-pro":  "0xe74481697f432ddee8dd6f9bd13b9d0297a5b63d55f3db25c4d3b5d34dad85b7",
    "suigar":       "0xcbb0929f21450013ebe5e86e7139f2409da2e3ed212c51126a7e6448b795a43f",
    "bucket-vault": "0x9f835c21d21f8ce519fec17d679cd38243ef2643ad879e7048ba77374be4036e",
    "bucket-pool":  "0xc2ae6693383e4a81285136effc8190c7baaf0e75aafa36d1c69cd2170cfc3803",
    "alphalend":    "0xd631cd66138909636fc3f73ed75820d0c5b76332d1644608ed1c85ea2b8219b4",
    "kai-leverage": "0x51e0ccce48f0763f98f1cb4856847c2e1531adacada99cdd7626ab999db57523",
}

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def ver_chain(orig):
    q = """query($a:SuiAddress!){ package(address:$a){ address version
      packageVersionsBefore(last:50){ nodes{ address version } } } }"""
    p = ((gql(q, {"a": orig}).get("data") or {}).get("package"))
    if not p: return []
    hist = sorted(p["packageVersionsBefore"]["nodes"], key=lambda x: x["version"])
    hist.append({"address": p["address"], "version": p["version"]})
    seen, out = set(), []
    for h in hist:
        if h["version"] in seen: continue
        seen.add(h["version"]); out.append(h)
    return out

def disasm(veraddr):
    q = """query($a:SuiAddress!,$c:String){ object(address:$a){ asMovePackage{
      modules(first:50, after:$c){ pageInfo{hasNextPage endCursor} nodes{ name disassembly } } } } }"""
    mods, cur = [], None
    while True:
        r = gql(q, {"a": veraddr, "c": cur})
        p = ((r.get("data") or {}).get("object") or {}).get("asMovePackage")
        if not p: return {}
        mods += p["modules"]["nodes"]
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]: cur = pi["endCursor"]
        else: break
    return {m["name"]: (m.get("disassembly") or "") for m in mods}

def structs(d):
    out = {}
    for mod, dis in d.items():
        lines = dis.splitlines(); i = 0
        while i < len(lines):
            m = re.match(r'^struct (\w+)(<[^>]*>)? has ([^\{]+)\{', lines[i])
            if m:
                body = []; i += 1
                while i < len(lines) and not lines[i].startswith('}'):
                    body.append(lines[i].strip().rstrip(',')); i += 1
                out[f"{mod}::{m.group(1)}"] = (m.group(3).strip(), body)
            i += 1
    return out

def main():
    os.makedirs(OUT, exist_ok=True)
    res = {"generated": datetime.datetime.utcnow().isoformat() + "Z", "families": {}}
    for fam, orig in FAMILIES.items():
        vs = ver_chain(orig)
        if not vs: res["families"][fam] = {"error": "no package"}; continue
        first, last = vs[0], vs[-1]
        s0, s1 = structs(disasm(first["address"])), structs(disasm(last["address"]))
        changed, identical = {}, []
        for k in set(s0) & set(s1):
            if s0[k] != s1[k]: changed[k] = {"first": s0[k], "latest": s1[k]}
            else: identical.append(k)
        res["families"][fam] = {
            "n_versions": len(vs), "first": first, "latest": last,
            "n_structs_first": len(s0), "n_structs_latest": len(s1),
            "structs_identical": sorted(identical),
            "structs_changed": changed,
            "structs_only_first": sorted(set(s0) - set(s1)),
            "structs_only_latest": sorted(set(s1) - set(s0)),
        }
        print(f"[{fam}] {len(vs)} versions; identical={len(identical)} changed={len(changed)} "
              f"only_first={len(set(s0)-set(s1))} only_latest={len(set(s1)-set(s0))}")
        for k, v in changed.items():
            print(f"    CHANGED {k}: first={v['first'][1]}  latest={v['latest'][1]}")
    json.dump(res, open(os.path.join(OUT, "struct_diff.json"), "w"), indent=1)
    print("wrote", os.path.join(OUT, "struct_diff.json"))

if __name__ == "__main__":
    main()
