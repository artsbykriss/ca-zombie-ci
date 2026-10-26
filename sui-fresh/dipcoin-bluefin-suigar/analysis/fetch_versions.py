#!/usr/bin/env python3
"""Fetch per-version package modules (disassembly) for a Sui package.

GraphQL package(address:) always resolves to the LATEST version, so to read an
OLD version's bytecode we query object(address:<version-specific addr>) and read
asMovePackage.modules. Read-only, public endpoint, no secrets.
"""
import sys, json, urllib.request, os

ENDPOINT = "https://graphql.mainnet.sui.io/graphql"

def gql(query, variables=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(ENDPOINT, data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())

VER_Q = """query($a:SuiAddress!){ package(address:$a){ address version
  packageVersionsBefore(last:40){ nodes{ address version } } } }"""

OBJ_Q = """query($a:SuiAddress!,$c:String){ object(address:$a){ address version
  asMovePackage{ address version modules(first:50, after:$c){
    pageInfo{hasNextPage endCursor}
    nodes{ name disassembly } } } } }"""

def versions(addr):
    r = gql(VER_Q, {"a": addr})
    p = (r.get("data") or {}).get("package")
    hist = list(reversed(p["packageVersionsBefore"]["nodes"]))
    hist.append({"address": p["address"], "version": p["version"]})
    return hist

def modules_of(addr):
    mods, cur = [], None
    while True:
        r = gql(OBJ_Q, {"a": addr, "c": cur})
        p = (r.get("data") or {}).get("object")
        if not p:
            return None, r.get("errors")
        mp = p["asMovePackage"]
        mods += mp["modules"]["nodes"]
        if mp["modules"]["pageInfo"]["hasNextPage"]:
            cur = mp["modules"]["pageInfo"]["endCursor"]
        else:
            return mods, None

def main(orig, outdir):
    os.makedirs(outdir, exist_ok=True)
    vs = versions(orig)
    summary = {"original": orig, "versions": []}
    for v in vs:
        mods, err = modules_of(v["address"])
        if err:
            print("ERR", v, err); continue
        rec = {"version": v["version"], "address": v["address"],
               "modules": [m["name"] for m in mods]}
        summary["versions"].append(rec)
        json.dump({"version": v["version"], "address": v["address"],
                   "modules": {m["name"]: m["disassembly"] for m in mods}},
                  open(os.path.join(outdir, f"v{v['version']:02d}_{v['address'][:12]}.json"), "w"))
        print(f"v{v['version']:>2} {v['address']} nmod={len(mods)}")
    json.dump(summary, open(os.path.join(outdir, "_versions.json"), "w"), indent=1)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
