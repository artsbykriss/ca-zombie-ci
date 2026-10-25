#!/usr/bin/env python3
"""Dump per-version Move bytecode for every version of a package.

Usage: python3 tools/sui_vermod.py <packageAddr> [outdir]
Writes <outdir>/<pkgshort>_v<ver>_<module>.mv and a pkg_versions json.
"""
import sys, json, os
sys.path.insert(0, os.path.dirname(__file__))
from sui import gql

def verchain(addr):
    q = """query($a:SuiAddress!){ package(address:$a){ address version
      packageVersionsBefore(last:40){ nodes{ address version } } } }"""
    p = gql(q, {"a": addr})["data"]["package"]
    hist = list(reversed(p["packageVersionsBefore"]["nodes"]))
    chain = [(h["version"], h["address"]) for h in hist] + [(p["version"], p["address"])]
    return chain

def mods_at(addr):
    out, cursor = [], None
    while True:
        q = """query($a:SuiAddress!,$c:String){ object(address:$a){ address version
          asMovePackage{ address version modules(first:50, after:$c){
            pageInfo{hasNextPage endCursor} nodes{ name disassembly } } } } }"""
        r = gql(q, {"a": addr, "c": cursor})
        if r.get("errors"): return {"errors": r["errors"]}
        o = r["data"]["object"]
        if not o or not o.get("asMovePackage"): return {"address": None}
        mp = o["asMovePackage"]
        out += mp["modules"]["nodes"]
        pi = mp["modules"]["pageInfo"]
        if pi["hasNextPage"]: cursor = pi["endCursor"]
        else: break
    return {"address": mp["address"], "version": mp["version"], "modules": out}

def main(addr, outdir="."):
    os.makedirs(outdir, exist_ok=True)
    chain = verchain(addr)
    summary = {"package_original": chain[0][1], "versions": []}
    for ver, vaddr in chain:
        m = mods_at(vaddr)
        if "errors" in m or m.get("address") is None:
            print("ERR", ver, vaddr, str(m)[:200]); continue
        summary["versions"].append({"version": ver, "address": vaddr,
                                    "modules": [x["name"] for x in m["modules"]]})
        for mod in m["modules"]:
            fn = os.path.join(outdir, f"{vaddr[:10]}_v{ver}_{mod['name']}.mv")
            with open(fn, "w") as fh:
                fh.write(f"// module {mod['name']}  version-object {vaddr} (v{ver})\n")
                fh.write(mod.get("disassembly") or "")
        print(f"v{ver} {vaddr}  modules={[x['name'] for x in m['modules']]}")
    json.dump(summary, open(os.path.join(outdir, f"verchain_{addr[:10]}.json"), "w"), indent=1)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else ".")
