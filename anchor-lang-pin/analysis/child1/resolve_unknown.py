#!/usr/bin/env python3
"""Resolve programdata accounts -> program ids, and diff against known sets.
Read-only RPC."""
import base64, json, os, sys, time, urllib.request

ENDPOINTS = [u for u in [os.environ.get("SOLANA_RPC_URL")] if u] + [
    "https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]

def rpc_any(method, params):
    last = None
    for u in ENDPOINTS:
        for _ in range(3):
            try:
                body = json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode()
                req = urllib.request.Request(u, data=body, headers={"Content-Type":"application/json"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    j = json.loads(r.read())
                if "error" in j: last = j["error"]; break
                return j
            except Exception as e:
                last = e; time.sleep(1.5)
    raise RuntimeError(f"{method}: {last}")

def pd_to_program(pd):
    j = rpc_any("getProgramAccounts", ["BPFLoaderUpgradeab1e11111111111111111111111", {
        "encoding":"base64","dataSlice":{"offset":0,"length":0},
        "filters":[{"memcmp":{"offset":4,"bytes":pd}},{"dataSize":36}]}])
    res = j.get("result")
    if res is None: return None
    return [x["pubkey"] for x in res]

if __name__ == "__main__":
    auth = json.load(open(sys.argv[1]))   # {authority: [pd,...]}
    known = json.load(open(sys.argv[2]))  # set of known programdata
    out = {}
    for a, pds in auth.items():
        unknown = [p for p in pds if p not in known]
        out[a] = {"n_total": len(pds), "unknown_pd": unknown, "resolved": {}}
        for pd in unknown:
            try:
                out[a]["resolved"][pd] = pd_to_program(pd)
            except Exception as e:
                out[a]["resolved"][pd] = f"ERR {e}"
            print(a, pd, out[a]["resolved"][pd], flush=True)
    json.dump(out, open("unknown_programs.json","w"), indent=2)
    print("WROTE unknown_programs.json")
