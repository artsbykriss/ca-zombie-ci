#!/usr/bin/env python3
"""Light RPC helper for Exceed Finance recon. Public endpoints only, with retry."""
import json, sys, base64, urllib.request, time

ENDPOINTS = [
    "https://api.mainnet-beta.solana.com",
    "https://solana-rpc.publicnode.com",
]

def call(method, params, rpc=None):
    last = None
    for attempt in range(6):
        ep = rpc or ENDPOINTS[attempt % len(ENDPOINTS)]
        try:
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
            req = urllib.request.Request(ep, data=body, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=45) as r:
                out = json.loads(r.read())
            if "error" in out:
                last = out
                time.sleep(1.5 * (attempt + 1))
                continue
            return out
        except Exception as e:
            last = e
            time.sleep(2.0 * (attempt + 1))
    raise RuntimeError(f"rpc failed after retries: {last}")

def get_account(pubkey, encoding="base64"):
    r = call("getAccountInfo", [pubkey, {"encoding": encoding}])
    return r.get("result", {}).get("value")

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "acct":
        print(json.dumps(get_account(sys.argv[2]), indent=2))
    elif cmd == "slot":
        print(call("getSlot", [])["result"])
    elif cmd == "raw":
        print(json.dumps(call(sys.argv[2], json.loads(sys.argv[3])), indent=2))
