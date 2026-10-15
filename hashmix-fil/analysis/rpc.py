#!/usr/bin/env python3
"""Read-only RPC helper for Filecoin FEVM via Blockscout eth-rpc proxy. No keys, no signing."""
import json, sys, urllib.request

RPC = "https://filecoin.blockscout.com/api/eth-rpc"
HDRS = {"User-Agent": "Mozilla/5.0", "Content-Type": "application/json"}

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, data=body, headers=HDRS)
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read().decode())
    if "error" in out:
        return {"error": out["error"]}
    return out.get("result")

if __name__ == "__main__":
    method = sys.argv[1]
    params = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
    print(json.dumps(rpc(method, params), indent=1))
