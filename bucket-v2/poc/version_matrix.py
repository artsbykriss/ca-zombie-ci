#!/usr/bin/env python3
"""ZH4 pass-7 cross-cutting PoC: Sui package-version / import matrix (READ-ONLY).

For each Sui package family it:
  1. enumerates every published version (original -> latest) via GraphQL,
  2. fetches each version's Move module + function inventory from its EXACT object
     (`object(address:)`, not the original-id->latest resolution),
  3. reports functions that exist in OLD versions but NOT in the latest
     (the version/package-import hazard: an old, possibly ungated, entry point that
     a later upgrade gated or removed but which remains callable),
  4. reports the reverse (new functions), and flags `entry` visibility.

Public endpoint only. No keys, no signing. Output -> ci-out/.
"""
import json, os, sys, urllib.request, re, datetime

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
OUT = os.environ.get("OUTDIR", os.path.join(os.path.dirname(__file__), "..", "ci-out"))

FAMILIES = {
    "dipcoin":        "0x978fed071cca22dd26bec3cf4a5d5a00ab10f39cb8c659bbfdfbec4397241001",
    "bluefin-pro":    "0xe74481697f432ddee8dd6f9bd13b9d0297a5b63d55f3db25c4d3b5d34dad85b7",
    "suigar":         "0xcbb0929f21450013ebe5e86e7139f2409da2e3ed212c51126a7e6448b795a43f",
    "bucket-vault":   "0x9f835c21d21f8ce519fec17d679cd38243ef2643ad879e7048ba77374be4036e",
    "bucket-pool":    "0xc2ae6693383e4a81285136effc8190c7baaf0e75aafa36d1c69cd2170cfc3803",
    "alphalend":      "0xd631cd66138909636fc3f73ed75820d0c5b76332d1644608ed1c85ea2b8219b4",
    "alphafi-oracle": "0x7671937b899c7756644da64feb8674a04dfc335059874919a863fb8da6f19fd4",
    "kai-leverage":   "0x51e0ccce48f0763f98f1cb4856847c2e1531adacada99cdd7626ab999db57523",
    "kai-access":     "0x0d9dd55ac7eb676dc78f7d0ae3bc5529d7fd6b52ac0d0edb2d7820c52d080026",
}

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def versions(orig):
    q = """query($a:SuiAddress!){ package(address:$a){ address version
      packageVersionsBefore(last:50){ nodes{ address version } } } }"""
    p = (gql(q, {"a": orig}).get("data") or {}).get("package")
    if not p: return None
    hist = sorted(p["packageVersionsBefore"]["nodes"], key=lambda x: x["version"])
    hist.append({"address": p["address"], "version": p["version"]})
    # de-dup by version
    seen, out = set(), []
    for h in hist:
        if h["version"] in seen: continue
        seen.add(h["version"]); out.append(h)
    return out

def module_functions(veraddr):
    """Return {module: [ (visibility,isEntry,name) ]} for the EXACT version object."""
    mods, cursor = [], None
    while True:
        q = """query($a:SuiAddress!,$c:String){ object(address:$a){ asMovePackage{
          modules(first:50, after:$c){ pageInfo{hasNextPage endCursor} nodes{ name } } } } }"""
        r = gql(q, {"a": veraddr, "c": cursor})
        o = (r.get("data") or {}).get("object")
        if not o or not o.get("asMovePackage"): return {}
        p = o["asMovePackage"]
        mods += p["modules"]["nodes"]
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]: cursor = pi["endCursor"]
        else: break
    res = {}
    for m in mods:
        fns, fc = [], None
        while True:
            q2 = """query($a:SuiAddress!,$mn:String,$c:String){ object(address:$a){ asMovePackage{
              module(name:$mn){ functions(first:50, after:$c){ pageInfo{hasNextPage endCursor}
                nodes{ name visibility isEntry } } } } } }"""
            rr = gql(q2, {"a": veraddr, "mn": m["name"], "c": fc})
            node = (((rr.get("data") or {}).get("object") or {}).get("asMovePackage") or {}).get("module")
            if not node: break
            for f in node["functions"]["nodes"]:
                fns.append((f["visibility"], f["isEntry"], f["name"]))
            pi2 = node["functions"]["pageInfo"]
            if pi2["hasNextPage"]: fc = pi2["endCursor"]
            else: break
        res[m["name"]] = fns
    return res

def fnsig(mod, f):
    return f"{mod}::{f[2]}"

def main():
    os.makedirs(OUT, exist_ok=True)
    report = {"generated": datetime.datetime.utcnow().isoformat() + "Z", "endpoint": ENDPOINT,
              "families": {}}
    filt = [x for x in os.environ.get("FAMILY_FILTER", "").split(",") if x]
    fams = {k: v for k, v in FAMILIES.items() if not filt or any(f in k for f in filt)}
    for name, orig in fams.items():
        try:
            vs = versions(orig)
        except Exception as e:
            report["families"][name] = {"error": str(e)}; continue
        if not vs:
            report["families"][name] = {"error": "no package"}; continue
        inv = {}
        for v in vs:
            try:
                inv[v["version"]] = module_functions(v["address"])
            except Exception as e:
                inv[v["version"]] = {"__error__": str(e)}
        latest_v = max(inv)
        latest_set = {fnsig(m, f) for m, fl in inv[latest_v].items() if isinstance(fl, list)
                      for f in fl}
        per_version = {}
        for ver, mods in inv.items():
            if ver == latest_v: continue
            s = {fnsig(m, f) for m, fl in mods.items() if isinstance(fl, list) for f in fl}
            removed = sorted(s - latest_set)          # in old version, gone in latest
            added = sorted(latest_set - s)            # new in latest
            per_version[ver] = {"n_modules": len(mods), "n_fns": len(s),
                                "fns_not_in_latest": removed, "fns_only_in_latest": added[:40]}
        report["families"][name] = {
            "original": orig, "n_versions": len(vs),
            "versions": [{"v": v["version"], "addr": v["address"]} for v in vs],
            "latest_version": latest_v,
            "latest_n_functions": len(latest_set),
            "old_version_diffs": per_version,
        }
        print(f"[{name}] {len(vs)} versions, latest v{latest_v}, {len(latest_set)} fns")
        for ver, d in per_version.items():
            if d["fns_not_in_latest"]:
                print(f"   v{ver}: {len(d['fns_not_in_latest'])} fns NOT in latest -> "
                      f"{', '.join(d['fns_not_in_latest'][:12])}")
    path = os.path.join(OUT, "version_matrix.json")
    json.dump(report, open(path, "w"), indent=1)
    print("wrote", path)

if __name__ == "__main__":
    main()
