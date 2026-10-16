#!/usr/bin/env python3
"""Local-only keyed-RPC helper. Reads ALCHEMY_API_KEY from /home/heisenberg/CA/.env at runtime.
NEVER writes the key or keyed URL anywhere. Do not run this from CI artifacts or save output containing URLs."""
import json, os, sys, urllib.request, time

ENV_FILE = "/home/heisenberg/CA/.env"

def _env(name):
    try:
        with open(ENV_FILE) as f:
            for line in f:
                if line.startswith(name + "="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return os.environ.get(name)

def get_url():
    k = _env("ALCHEMY_API_KEY")
    if k:
        return f"https://solana-mainnet.g.alchemy.com/v2/{k}"
    return "https://solana-rpc.publicnode.com"

def rpc(method, params, retries=5, url=None):
    url = url or get_url()
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zombie-research/1.0"})
            with urllib.request.urlopen(req, timeout=90) as r:
                out = json.loads(r.read())
            if "error" in out:
                e = out["error"]
                if e.get("code") in (429, -32005) or "rate" in str(e).lower():
                    time.sleep(1.5 * (attempt + 1)); last = e; continue
            return out
        except Exception as ex:
            last = str(ex); time.sleep(1.0 * (attempt + 1))
    return {"error": {"code": -1, "message": f"rpc failed: {last}"}}

if __name__ == "__main__":
    method = sys.argv[1]
    params = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
    print(json.dumps(rpc(method, params), indent=1))
