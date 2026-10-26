#!/usr/bin/env python3
"""Differential callability probe (READ-ONLY) for the Sui version/import primitive.

For each package family it takes a function name that is present in an OLD version and
absent from the LATEST version (from ci-out/version_matrix.json), then simulates that
MoveCall against (a) the OLD version id and (b) the LATEST version id, using a bogus arg
list. The runtime message discriminates:
  - OLD id  -> "Function Not Found"      => the runtime loaded the OLD version's module set
  - LATEST  -> "Move Bytecode Verification Error" / different => function exists there
A control probe against a non-existent package returns "Object ... not found".

No signing, no sending. Public GraphQL only.
"""
import json, os, sys, urllib.request

ENDPOINT = os.environ.get("SUI_GRAPHQL", "https://graphql.mainnet.sui.io/graphql")
SENDER = "0x0000000000000000000000000000000000000000000000000000000000000005"
HERE = os.path.dirname(__file__)
OUT = os.environ.get("OUTDIR", os.path.join(HERE, "..", "ci-out"))

def gql(q, v):
    req = urllib.request.Request(ENDPOINT, data=json.dumps({"query": q, "variables": v}).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())

Q = """query($t:JSON!){ simulateTransaction(transaction:$t, checksEnabled:true, doGasSelection:true){
  effects{ status executionError{ message identifier } } } }"""

def sim_call(pkg, mod, fn):
    cmd = {"moveCall": {"package": pkg, "module": mod, "function": fn,
                        "typeArguments": [], "arguments": []}}
    tx = {"sender": SENDER, "kind": {"programmableTransaction": {"inputs": [], "commands": [cmd]}}}
    r = gql(Q, {"t": tx})
    if r.get("errors"):
        return {"gql_error": r["errors"][0].get("message", "")[:120]}
    e = r["data"]["simulateTransaction"]["effects"]
    return {"status": e["status"],
            "msg": (e.get("executionError") or {}).get("message"),
            "ident": (e.get("executionError") or {}).get("identifier")}

def main():
    mpath = os.path.join(OUT, "version_matrix.json")
    if not os.path.exists(mpath):
        print("missing", mpath, "-> run version_matrix.py first"); sys.exit(1)
    m = json.load(open(mpath))
    out = {"generated": m.get("generated"), "endpoint": ENDPOINT, "probes": []}
    # control
    out["control_nonexistent_package"] = sim_call(
        "0x9999999999999999999999999999999999999999999999999999999999999999", "bank", "set_relayer")
    for fam, d in m["families"].items():
        if "versions" not in d: continue
        latest = d["latest_version"]
        # choose the earliest old version that has a function absent from latest
        pick = None
        for v, diff in sorted(d.get("old_version_diffs", {}).items(), key=lambda kv: int(kv[0])):
            for sig in diff.get("fns_not_in_latest", []):
                if "::" in sig and not sig.split("::")[1].startswith("err") and not sig.split("::")[1].startswith("error"):
                    pick = (int(v), sig); break
            if pick: break
        if not pick: continue
        vnum, sig = pick
        mod, fn = sig.split("::")
        old_addr = next(x["addr"] for x in d["versions"] if x["v"] == vnum)
        lat_addr = next(x["addr"] for x in d["versions"] if x["v"] == latest)
        rec = {"family": fam, "probe": sig, "old_version": vnum, "old_addr": old_addr,
               "latest_version": latest, "latest_addr": lat_addr,
               "call_on_old": sim_call(old_addr, mod, fn),
               "call_on_latest": sim_call(lat_addr, mod, fn)}
        out["probes"].append(rec)
        print(f"[{fam}] {sig}: old(v{vnum})={rec['call_on_old']}  latest(v{latest})={rec['call_on_latest']}")
    path = os.path.join(OUT, "import_probes.json")
    json.dump(out, open(path, "w"), indent=1)
    print("wrote", path)

if __name__ == "__main__":
    main()
