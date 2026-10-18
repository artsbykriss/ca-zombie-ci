#!/usr/bin/env python3
"""Minimal Solana JSON-RPC helper. Read-only. Public RPC with retries."""
import json, sys, time, urllib.request, os

RPCS = [os.environ.get("SOLANA_RPC", "https://api.mainnet-beta.solana.com")]
RPCS = [u for u in RPCS if u]

def rpc(method, params, tries=6):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for i in range(tries):
        for url in RPCS:
            try:
                req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
                with urllib.request.urlopen(req, timeout=45) as r:
                    j = json.loads(r.read())
                if "error" in j:
                    last = j["error"]
                    if j["error"].get("code") == -32602:
                        raise RuntimeError(json.dumps(j["error"]))
                    time.sleep(1.0 + i)
                    continue
                return j["result"]
            except Exception as e:
                last = str(e)
                time.sleep(1.0 + i)
    raise RuntimeError(f"rpc failed {method}: {last}")

def slot():
    return rpc("getSlot", [{"commitment": "finalized"}])

def acct(pubkey, enc="base64"):
    r = rpc("getAccountInfo", [pubkey, {"encoding": enc, "commitment": "finalized"}])
    return r.get("value") if r else None

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "slot":
        print(slot())
    elif cmd == "acct":
        a = acct(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "base64")
        print(json.dumps(a, indent=2))
    elif cmd == "raw":
        print(json.dumps(rpc(sys.argv[2], json.loads(sys.argv[3])), indent=2))
