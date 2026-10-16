#!/usr/bin/env python3
"""Minimal Solana JSON-RPC helper (read-only). Uses SOLANA_RPC_URL env var if set,
else a keyless public endpoint. NEVER hardcode keyed URLs here (public repo)."""
import json, os, sys, urllib.request, urllib.error, time

PUBLIC = "https://solana-rpc.publicnode.com"
FALLBACKS = ["https://api.mainnet-beta.solana.com", "https://solana-rpc.publicnode.com"]

def rpc(method, params, rpc_url=None, retries=6):
    url = rpc_url or os.environ.get("SOLANA_RPC_URL") or PUBLIC
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json", "User-Agent": "zombie-research/1.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                out = json.loads(r.read())
            if "error" in out:
                e = out["error"]
                # rate limit / transient -> retry
                if e.get("code") in (429, -32005) or "rate" in str(e).lower():
                    time.sleep(1.5 * (attempt + 1)); last = e; continue
                return out
            return out
        except Exception as ex:  # noqa
            last = str(ex); time.sleep(1.0 * (attempt + 1))
    return {"error": {"code": -1, "message": f"rpc failed: {last}"}}

def main():
    method = sys.argv[1]
    params = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []
    out = rpc(method, params)
    json.dump(out, sys.stdout, indent=1)
    print()

if __name__ == "__main__":
    main()
