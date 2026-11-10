#!/usr/bin/env python3
"""Minimal keyless JSON-RPC helper for read-only state dumps.

No keys, no auth, public endpoints only.  Usage:
  python3 rpc.py <chain> <to> <data> [block]
chain: eth | pls
"""
import json, sys, urllib.request

RPCS = {
    "eth": ["https://ethereum-rpc.publicnode.com", "https://eth.drpc.org", "https://1rpc.io/eth"],
    "pls": ["https://pulsechain-rpc.publicnode.com", "https://rpc.pulsechain.com"],
}


def call(chain, method, params):
    last = None
    for url in RPCS[chain]:
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"content-type": "application/json", "user-agent": "Mozilla/5.0 research"},
            )
            with urllib.request.urlopen(req, timeout=25) as r:
                out = json.loads(r.read())
            if "result" in out:
                return out["result"]
            last = out
        except Exception as e:  # noqa: BLE001
            last = e
    raise RuntimeError(f"all rpc failed: {last}")


def main():
    chain, to, data = sys.argv[1], sys.argv[2], sys.argv[3]
    block = sys.argv[4] if len(sys.argv) > 4 else "latest"
    b = block if block == "latest" else hex(int(block))
    print(call(chain, "eth_call", [{"to": to, "data": data}, b]))


if __name__ == "__main__":
    main()
