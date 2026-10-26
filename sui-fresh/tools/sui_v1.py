#!/usr/bin/env python3
"""Read-only Sui GraphQL fetcher (no secrets; public endpoint).
Usage:
  sui.py pkg <address> [outdir]      -> fetch package (all modules, disassembly), print module header addrs
  sui.py obj <address>               -> print object type + json contents
  sui.py type <structType> [limit]   -> list objects of a type
  sui.py events <MoveEventType> [limit] -> recent events of a type
  sui.py tx <digest>                 -> transaction block summary
"""
import sys, json, urllib.request, os

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")

def gql(query, variables=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(ENDPOINT, data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode())

def fetch_pkg_modules(addr):
    mods = []
    cursor = None
    pkg_meta = None
    while True:
        q = """query($a:SuiAddress!,$c:String){
          package(address:$a){
            address version digest
            modules(first:50, after:$c){ pageInfo{hasNextPage endCursor}
              nodes{ name disassembly } } } }"""
        r = gql(q, {"a": addr, "c": cursor})
        if "errors" in r and r["errors"]:
            return {"errors": r["errors"]}
        p = r["data"]["package"]
        if p is None:
            return {"address": None}
        pkg_meta = {"address": p["address"], "version": p["version"], "digest": p["digest"]}
        for n in p["modules"]["nodes"]:
            mods.append(n)
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]:
            cursor = pi["endCursor"]
        else:
            break
    pkg_meta["modules"] = mods
    return pkg_meta

def module_self_addr(dis):
    for line in dis.splitlines():
        if line.startswith("module "):
            return line.split()[1].split(".")[0]
    return None

def cmd_pkg(addr, outdir="."):
    res = fetch_pkg_modules(addr)
    if "errors" in res:
        print("ERRORS:", json.dumps(res["errors"])[:500]); return
    if res.get("address") is None:
        print(f"{addr}: package NULL"); return
    os.makedirs(outdir, exist_ok=True)
    f = os.path.join(outdir, f"pkg_{addr}.json")
    json.dump(res, open(f, "w"), indent=1)
    self_addrs = set()
    print(f"package query({addr}) -> address={res['address']} objversion={res['version']} nmodules={len(res['modules'])}")
    for m in res["modules"]:
        sa = module_self_addr(m.get("disassembly") or "")
        self_addrs.add(sa)
        print(f"  {m['name']:28s} self={sa}")
    print("  bytecode self-addresses:", self_addrs)

def cmd_obj(addr):
    q = """query($a:SuiAddress!){ object(address:$a){
      address version asMoveObject{ contents{ type{repr} json } }
      asMovePackage{ address version } } }"""
    r = gql(q, {"a": addr})
    print(json.dumps(r.get("data", r), indent=1)[:4000])

def cmd_type(t, limit=50):
    q = """query($t:String!,$n:Int){ objects(first:$n, filter:{type:$t}){
      pageInfo{hasNextPage endCursor} nodes{ address version asMoveObject{ contents{ type{repr} json } } } } }"""
    r = gql(q, {"t": t, "n": limit})
    print(json.dumps(r.get("data", r), indent=1)[:6000])

def cmd_events(t, limit=50):
    q = """query($t:String!,$n:Int){ events(first:$n, filter:{type:$t}){
      pageInfo{hasNextPage endCursor} nodes{ sender timestamp contents{ type{repr} json } transaction{ digest } } } }"""
    r = gql(q, {"t": t, "n": limit})
    print(json.dumps(r.get("data", r), indent=1)[:6000])

def cmd_tx(digest):
    q = """query($d:String!){ transactionBlock(digest:$d){
      digest effects{status} } }"""
    r = gql(q, {"d": digest})
    print(json.dumps(r.get("data", r), indent=1)[:4000])

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "pkg": cmd_pkg(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ".")
    elif cmd == "obj": cmd_obj(sys.argv[2])
    elif cmd == "type": cmd_type(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 50)
    elif cmd == "events": cmd_events(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 50)
    elif cmd == "tx": cmd_tx(sys.argv[2])
    else: print(__doc__)
