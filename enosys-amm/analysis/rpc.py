#!/usr/bin/env python3
"""Read-only JSON-RPC helper for Enosys AMM V3 (Flare 14 / Songbird 19).
No keys. Public endpoints only. Every write records chain + block.
"""
import json, sys, time, urllib.request, urllib.error

RPCS = {
    14: [
        "https://flare-api.flare.network/ext/C/rpc",
        "https://flare.drpc.org",
        "https://14.rpc.thirdweb.com",
    ],
    19: [
        "https://songbird-api.flare.network/ext/C/rpc",
        "https://songbird.drpc.org",
        "https://19.rpc.thirdweb.com",
    ],
}

_id = 0
def _post(url, payload, timeout=30):
    req = urllib.request.Request(
        url, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0 research"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def rpc(chain, method, params, tries=3):
    global _id
    last = None
    for url in RPCS[chain]:
        for _ in range(tries):
            _id += 1
            try:
                out = _post(url, {"jsonrpc": "2.0", "id": _id, "method": method, "params": params})
                if "result" in out:
                    return out["result"]
                last = out
            except Exception as e:
                last = e
            time.sleep(0.15)
    raise RuntimeError(f"{chain} {method} failed: {last}")

def block(chain):
    return int(rpc(chain, "eth_blockNumber", []), 16)

def code(chain, addr):
    return rpc(chain, "eth_getCode", [addr, "latest"])

def call(chain, to, data, blk="latest"):
    return rpc(chain, "eth_call", [{"to": to, "data": data}, blk])

def storage(chain, addr, slot, blk="latest"):
    return rpc(chain, "eth_getStorageAt", [addr, hex(slot), blk])

def bal(chain, addr, blk="latest"):
    return int(rpc(chain, "eth_getBalance", [addr, blk]), 16)

def logs(chain, params):
    return rpc(chain, "eth_getLogs", [params])
