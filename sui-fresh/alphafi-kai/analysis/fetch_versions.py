#!/usr/bin/env python3
"""Fetch per-version Move package disassembly for AlphaLend / AlphaFi Oracle / stdlib.
Read-only, public GraphQL endpoint, no secrets."""
import json, urllib.request, os, sys

EP = "https://graphql.mainnet.sui.io/graphql"

def gql(q, v):
    body = json.dumps({"query": q, "variables": v}).encode()
    req = urllib.request.Request(EP, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

Q = """query($a:SuiAddress!){ object(address:$a){ address version
  asMovePackage{ address version modules(first:50){ nodes{ name disassembly } } } } }"""

def fetch(addr):
    j = gql(Q, {"a": addr})
    p = (j.get("data") or {}).get("object") or {}
    mp = p.get("asMovePackage")
    if not mp:
        return None
    return mp

def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(outdir, exist_ok=True)
    chains = json.load(open(sys.argv[2]))  # {label: [addr,...]}
    for label, addrs in chains.items():
        for i, a in enumerate(addrs):
            mp = fetch(a)
            if mp is None:
                print(f"{label} {a}: NOT A PACKAGE")
                continue
            fn = os.path.join(outdir, f"{label}_v{mp['version']}_{a}.json")
            json.dump(mp, open(fn, "w"), indent=1)
            mods = mp["modules"]["nodes"]
            print(f"{label} v{mp['version']} {a[:12]}.. mods={[m['name'] for m in mods]}")

if __name__ == "__main__":
    main()
