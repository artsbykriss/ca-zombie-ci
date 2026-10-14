#!/usr/bin/env python3
"""Compare locally compiled (verify/out) runtime bytecode against deployed Emerald code.

Usage: python3 ci/verify_bytecode.py [--dir verify] [--out ci-out/bytecode-verify.json]
Public RPC only; no secrets.
"""
import json, os, sys, glob, urllib.request, argparse

RPC = os.environ.get("OASIS_RPC", "https://emerald.oasis.dev")

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"fountain-verify/1.0"})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())

def code(addr):
    r = rpc("eth_getCode", [addr, "latest"])
    return (r.get("result") or "0x").lower()

# contract name -> deployed address
TARGETS = {
    "Unitroller":                  ["0xA7684aE7e07Dac91113900342b3ef25B9Fd1D841",
                                    "0x1C0C30795802Bf2B3232a824f41629BbBCF63127",
                                    "0x7c4d0c834701C6E7F57b8c1424d30aDC46eA0840"],
    "OracleAnchoredView":          ["0x3789ae7132f2cad96553d378d13c58eb8508258f",
                                    "0x512efb22d9aa6024c332e0a2faf6895786cd95aa"],
    "LPOracleAnchoredView":        ["0x13322c2911f73db4d4893cce068e2c6841207914"],
    "WhitePaperInterestRateModel": ["0x374d7abc6d8fadce97a0fbf62a0a6d6c17a8482b"],
    "JumpRateModelV2":             ["0xa0af64406406e147df066bc7b782d682c84e5aab",
                                    "0xba3cbebede0c4e17510664d3f3fb6d7305f72022"],
    "Timelock":                    ["0x5d4ae9ecbeea7038324582d8b4b745a715ddfb72"],
    "CErc20Immutable":             ["0x275b88547185d955f66e5dd1066e040af468fc66",
                                    "0x352cc3320debffa3046cf66a4e0a80d528f00285",
                                    "0x61d90f6ab2b2b1baffa39bebb5d8ad57028da258",
                                    "0x2552707d66c102c12b0f8284824f80e1299cb6b7",
                                    "0xbe5a2c8da347311c46b1f0868aa52b8eb59938b3",
                                    "0x54cc15a99e40cc4a6d8a2ddc1b8ee65a2d7414e1",
                                    "0x27d51cd65070d28463a42ee644a22353c2bbddf3",
                                    "0xf377b8bcdd8e154ab8c846eebdf758f37be93381",
                                    "0xb317c67b105f7e216f483618a91eaea3814b9b3c",
                                    "0x3acaddeb99c714103683a1a061b793d53563f17c",
                                    "0xb473e13cbb875c8f9598513cd4eb2c52b1b88173",
                                    "0x6e298782e7bbc097442ed579d620d1b5a8e7dfd3",
                                    "0x4be7e0ec31797d4d61fc07dbf0f843ae04a58f05"],
    "CEther":                      ["0xd7d588babfb99e82cd6dd0ca7677a5599aa678b5",
                                    "0x63f1fe2e1da490611fc16e4a5d92b7ec7d0911a9"],
    "Comptroller":                 [],   # impls checked below
    "USDComptroller":              [],
}
# comptroller implementations (behind Unitroller proxies)
IMPLS = {
    "0x1d3deb0ac637a85969a81be567a8627f57961856": "classic-impl",
    "0xd8f26369e00b2a00ef58122ebf13ea1f718cb9f2": "usd-impl",
    "0xcf7aa043748c904a1c63eff40b08200d3daa9d4b": "lpt-impl",
}

def strip_metadata(bc):
    # metadata: last 2 bytes = length; strip that many bytes (CBOR) + 2
    if len(bc) < 4: return bc
    ln = int(bc[-4:], 16)
    if 0 < ln <= 100 and len(bc) - 2*ln - 4 >= 0:
        return bc[:len(bc) - 2*ln - 4]
    return bc

def find_artifact(verify_dir, name):
    hits = glob.glob(os.path.join(verify_dir, "out", "**", f"{name}.json"), recursive=True)
    return hits[0] if hits else None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default="verify")
    ap.add_argument("--out", default="ci-out/bytecode-verify.json")
    a = ap.parse_args()
    results = []
    for name, addrs in TARGETS.items():
        art = find_artifact(a.dir, name)
        if not art:
            results.append({"contract": name, "error": "artifact not found"})
            continue
        obj = json.load(open(art))
        local = (obj.get("deployedBytecode", {}).get("object") or "").lower()
        if local.startswith("0x"): local = local[2:]
        for addr in addrs:
            chain = code(addr)[2:]
            results.append({
                "contract": name, "address": addr,
                "local_bytes": len(local)//2, "chain_bytes": len(chain)//2,
                "exact_match": local == chain,
                "match_no_metadata": strip_metadata(local) == strip_metadata(chain),
            })
    # comptroller impls: try each artifact
    for addr, label in IMPLS.items():
        chain = code(addr)[2:]
        best = None
        for name in ["Comptroller", "USDComptroller", "ComptrollerG7"]:
            art = find_artifact(a.dir, name)
            if not art: continue
            obj = json.load(open(art))
            local = (obj.get("deployedBytecode", {}).get("object") or "").lower()
            if local.startswith("0x"): local = local[2:]
            m = (local == chain, strip_metadata(local) == strip_metadata(chain))
            if m[1]:
                best = (name, len(local)//2, len(chain)//2, m[0], m[1]); break
            if best is None:
                best = (name, len(local)//2, len(chain)//2, m[0], m[1])
        if best:
            results.append({"contract": f"{best[0]} ({label})", "address": addr,
                            "local_bytes": best[1], "chain_bytes": best[2],
                            "exact_match": best[3], "match_no_metadata": best[4]})
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump({"rpc": RPC, "results": results}, open(a.out, "w"), indent=1)
    n_ok = sum(1 for r in results if r.get("match_no_metadata"))
    print(f"bytecode verify: {n_ok}/{len(results)} match (metadata-stripped)")
    for r in results:
        flag = "OK " if r.get("match_no_metadata") else ("EXACT" if r.get("exact_match") else "MISMATCH")
        print(f"  [{flag}] {r.get('contract'):40s} {r.get('address','')[:42]:44s} local={r.get('local_bytes')} chain={r.get('chain_bytes')}")

if __name__ == "__main__":
    main()
