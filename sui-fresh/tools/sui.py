#!/usr/bin/env python3
"""Read-only Sui GraphQL helper (public endpoint, no secrets).

Sui JSON-RPC is DEPRECATED on public fullnodes (2026); this uses the GraphQL API,
which exposes full Move module disassembly + live object state + simulation.

Usage:
  sui.py pkg  <addr> [outdir]        # package: all modules, disassembly, bytecode self-addrs
  sui.py ver  <addr>                 # package version chain (original->latest + history)
  sui.py obj  <addr>                 # object type + JSON contents (live state)
  sui.py type <structType> [n]       # objects of a struct type (first n)
  sui.py events <MoveEventType> [n]  # recent events of a type
  sui.py txfn <pkg>::<mod>::<fn> [n] # recent txs that called a function
  sui.py sim  <txjson-file>          # simulateTransaction (read-only, no signing)
  sui.py multiobj <addr,addr,...>    # batch object reads

Env: SUI_GRAPHQL (default https://graphql.mainnet.sui.io/graphql)
No private keys. Nothing here signs or sends a transaction.
"""
import sys, json, urllib.request, os

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")

def gql(query, variables=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urllib.request.Request(ENDPOINT, data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

def fetch_pkg_modules(addr):
    mods, cursor, meta = [], None, None
    while True:
        q = """query($a:SuiAddress!,$c:String){ package(address:$a){
          address version digest previousTransaction{digest}
          linkage{originalId upgradedId version}
          modules(first:50, after:$c){ pageInfo{hasNextPage endCursor}
            nodes{ name disassembly } } } }"""
        r = gql(q, {"a": addr, "c": cursor})
        if r.get("errors"):
            return {"errors": r["errors"]}
        p = r["data"]["package"]
        if p is None:
            return {"address": None}
        meta = {k: p[k] for k in ("address", "version", "digest", "previousTransaction", "linkage")}
        mods += p["modules"]["nodes"]
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]:
            cursor = pi["endCursor"]
        else:
            break
    meta["modules"] = mods
    return meta

def module_self_addr(dis):
    for line in (dis or "").splitlines():
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
    json.dump(res, open(os.path.join(outdir, f"pkg_{addr}.json"), "w"), indent=1)
    print(f"package({addr}) -> latest={res['address']} objver={res['version']} nmodules={len(res['modules'])}")
    for m in res["modules"]:
        print(f"  {m['name']:28s} self={module_self_addr(m.get('disassembly'))}")
    print("  bytecode self-addresses:", {module_self_addr(m.get('disassembly')) for m in res['modules']})

def cmd_ver(addr):
    q = """query($a:SuiAddress!){ package(address:$a){ address version
      linkage{originalId upgradedId version}
      packageVersionsBefore(last:30){ nodes{ address version } } } }"""
    r = gql(q, {"a": addr})
    p = (r.get("data") or {}).get("package")
    if not p: print(json.dumps(r)[:400]); return
    print(f"latest={p['address']} objver={p['version']}")
    hist = list(reversed(p["packageVersionsBefore"]["nodes"]))
    print("version history (oldest->newest):")
    for h in hist: print(f"  v{h['version']:>3}  {h['address']}")
    print(f"  v{p['version']:>3}  {p['address']}  (latest)")
    print("linkage (dependency versions pinned by latest):")
    for l in p["linkage"]: print(f"  {l['originalId']} -> {l['upgradedId']} v{l['version']}")

def cmd_pkgat(addr, outdir="."):
    """Fetch the EXACT package version object at addr (not resolved to latest)."""
    mods, cursor, meta = [], None, None
    while True:
        q = """query($a:SuiAddress!,$c:String){ object(address:$a){ address version
          asMovePackage{ address version
            modules(first:50, after:$c){ pageInfo{hasNextPage endCursor} nodes{ name disassembly } } } } }"""
        r = gql(q, {"a": addr, "c": cursor})
        if r.get("errors"):
            print("ERRORS:", json.dumps(r["errors"])[:400]); return
        o = r["data"]["object"]
        if not o or not o.get("asMovePackage"):
            print(f"{addr}: not a package object"); return
        p = o["asMovePackage"]
        meta = {"address": p["address"], "version": p["version"], "objversion": o["version"]}
        mods += p["modules"]["nodes"]
        pi = p["modules"]["pageInfo"]
        if pi["hasNextPage"]: cursor = pi["endCursor"]
        else: break
    meta["modules"] = mods
    os.makedirs(outdir, exist_ok=True)
    json.dump(meta, open(os.path.join(outdir, f"pkgat_{addr}.json"), "w"), indent=1)
    print(f"object({addr}) -> package {meta['address']} objversion={meta['objversion']} nmodules={len(mods)}")
    for m in mods:
        fns = []
        cur = None
        while True:
            q2 = """query($a:SuiAddress!,$mn:String,$c:String){ package(address:$a){ module(name:$mn){
              functions(first:50, after:$c){ pageInfo{hasNextPage endCursor}
                nodes{ name visibility isEntry } } } } }"""
            rr = gql(q2, {"a": addr, "mn": m["name"], "c": cur})
            try:
                node = rr["data"]["package"]["module"]
            except Exception:
                break
            if not node: break
            for f in node["functions"]["nodes"]:
                fns.append(f"{f['visibility'][:3]}{'/entry' if f['isEntry'] else ''}:{f['name']}")
            if node["functions"]["pageInfo"]["hasNextPage"]: cur = node["functions"]["pageInfo"]["endCursor"]
            else: break
        print(f"  {m['name']:22s} {', '.join(fns)}")

def cmd_obj(addr):
    q = """query($a:SuiAddress!){ object(address:$a){ address version owner{__typename}
      asMoveObject{ contents{ type{repr} json } } asMovePackage{ address version } } }"""
    print(json.dumps(gql(q, {"a": addr}).get("data", {}), indent=1)[:6000])

def cmd_multiobj(addrs):
    q = """query($a:[SuiAddress!]!){ multiGetObjects(keys:$a){ address version
      asMoveObject{ contents{ type{repr} json } } } }"""
    r = gql(q, {"a": addrs})
    print(json.dumps(r.get("data", r), indent=1)[:9000])

def cmd_type(t, limit=50):
    q = """query($t:String!,$n:Int){ objects(first:$n, filter:{type:$t}){
      nodes{ address version asMoveObject{ contents{ type{repr} json } } } } }"""
    print(json.dumps(gql(q, {"t": t, "n": limit}).get("data", {}), indent=1)[:9000])

def cmd_events(t, limit=50):
    q = """query($t:String!,$n:Int){ events(first:$n, filter:{type:$t}){
      nodes{ sender timestamp contents{ type{repr} json } transaction{ digest } } } }"""
    print(json.dumps(gql(q, {"t": t, "n": limit}).get("data", {}), indent=1)[:9000])

def cmd_txfn(f, limit=20):
    q = """query($f:String!,$n:Int){ transactions(first:$n, filter:{function:$f}){
      nodes{ digest effects{ status } } } }"""
    r = gql(q, {"f": f, "n": limit})
    print(json.dumps(r.get("data", r), indent=1)[:6000])

def cmd_sim(fn):
    tx = json.load(open(fn))
    q = """query($t:JSON!){ simulateTransaction(transaction:$t, checksEnabled:true, doGasSelection:true){
      effects{ status } } }"""
    print(json.dumps(gql(q, {"t": tx}), indent=1)[:6000])

if __name__ == "__main__":
    if len(sys.argv) < 2: print(__doc__); sys.exit(1)
    c = sys.argv[1]
    if c == "pkg": cmd_pkg(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ".")
    elif c == "ver": cmd_ver(sys.argv[2])
    elif c == "obj": cmd_obj(sys.argv[2])
    elif c == "pkgat": cmd_pkgat(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ".")
    elif c == "multiobj": cmd_multiobj(sys.argv[2].split(","))
    elif c == "type": cmd_type(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 50)
    elif c == "events": cmd_events(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 50)
    elif c == "txfn": cmd_txfn(sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 20)
    elif c == "sim": cmd_sim(sys.argv[2])
    else: print(__doc__)
