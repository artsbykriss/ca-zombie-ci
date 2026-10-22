#!/usr/bin/env python3
"""Read-only Berachain state reader for the Burve SimplexDiamond. Keyless RPC."""
import json, urllib.request, sys

RPCS = ["https://rpc.berachain.com", "https://berachain-rpc.publicnode.com", "https://berachain.drpc.org"]
D = "0xa1beD164c12CD9479A1049f97BDe5b3D6EC21089"
_rpc_i = 0

def rpc(method, params, rpc_url=None):
    global _rpc_i
    urls = [rpc_url] if rpc_url else RPCS[_rpc_i:] + RPCS[:_rpc_i]
    last = None
    for u in urls:
        try:
            req = urllib.request.Request(u, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"]
            last = j
        except Exception as e:
            last = e
    raise RuntimeError(f"{method} failed: {last}")

def call(to, data, block="latest"):
    return rpc("eth_call", [{"to": to, "data": data}, block])

def words(hexstr):
    h = hexstr[2:] if hexstr.startswith("0x") else hexstr
    return [h[i:i+64] for i in range(0, len(h), 64)]

def addr(w):
    return "0x" + w[24:]

if __name__ == "__main__":
    blk = int(rpc("eth_blockNumber", []), 16)
    print("block", blk, hex(blk))
    fac = call(D, "0x7a0ed627")
    w = words(fac)
    n = int(w[1], 16)
    print("n facets", n)
    for i in range(n):
        off = 2 + int(w[2+i], 16) // 32
        fa = addr(w[off])
        cnt = int(w[off+2], 16)
        sels = ["0x" + w[off+3+j][:8] for j in range(cnt)]
        print(f"  facet {fa} ({cnt}) {sels}")
