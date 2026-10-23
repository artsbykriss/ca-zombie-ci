#!/usr/bin/env python3
"""Resolve unknown programdata -> program ids, emit candidates3.json."""
import json, os, sys, time, urllib.request

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
                last = e; time.sleep(2)
    raise RuntimeError(f"{method}: {last}")

todo = json.load(open(sys.argv[1]))
cands = []
for label, v in todo.items():
    for pd in v["unknown_pd"]:
        try:
            j = rpc_any("getProgramAccounts", ["BPFLoaderUpgradeab1e11111111111111111111111", {
                "encoding":"base64","dataSlice":{"offset":0,"length":0},
                "filters":[{"memcmp":{"offset":4,"bytes":pd}},{"dataSize":36}]}])
            progs = [x["pubkey"] for x in j.get("result") or []]
        except Exception as e:
            progs = [f"ERR {e}"]
        for pid in progs:
            cands.append({"repo": label, "name": f"{label}:{pid[:6]}", "id": pid})
        print(label, pd, progs, flush=True)
json.dump(cands, open(sys.argv[2], "w"), indent=2)
print("WROTE", sys.argv[2], len(cands))
