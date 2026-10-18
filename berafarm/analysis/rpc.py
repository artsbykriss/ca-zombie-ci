#!/usr/bin/env python3
"""Minimal keyless JSON-RPC helper for BeraFarm (Berachain, chainId 80094).

Read-only. Public endpoints only; no secrets. Usage as a module:
    from rpc import rpc, eth_call, get_code, storage
"""
import json
import sys
import time
import urllib.request

RPCS = [
    "https://rpc.berachain.com",
    "https://berachain.drpc.org",
    "https://berachain-rpc.publicnode.com",
]

_id = [0]


def rpc(method, params, rpc_url=None, retries=3):
    urls = [rpc_url] if rpc_url else RPCS
    last = None
    for url in urls:
        for attempt in range(retries):
            _id[0] += 1
            body = json.dumps({"jsonrpc": "2.0", "id": _id[0], "method": method, "params": params}).encode()
            req = urllib.request.Request(
                url, data=body, headers={"Content-Type": "application/json", "User-Agent": "zh4-research/1.0"}
            )
            try:
                with urllib.request.urlopen(req, timeout=45) as r:
                    out = json.loads(r.read())
                if "error" in out:
                    last = RuntimeError(f"{url} {method} error: {out['error']}")
                    break
                return out["result"]
            except Exception as e:  # noqa: BLE001
                last = e
                time.sleep(1 + attempt)
    raise last


def block_number():
    return int(rpc("eth_blockNumber", []), 16)


def get_code(addr, blk="latest"):
    return rpc("eth_getCode", [addr, hex(blk) if isinstance(blk, int) else blk])


def storage(addr, slot, blk="latest"):
    return rpc("eth_getStorageAt", [addr, slot, hex(blk) if isinstance(blk, int) else blk])


def eth_call(to, data, blk="latest", frm=None):
    tx = {"to": to, "data": data}
    if frm:
        tx["from"] = frm
    return rpc("eth_call", [tx, hex(blk) if isinstance(blk, int) else blk])


def impl_slot(addr, blk="latest"):
    s = storage(addr, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc", blk)
    return "0x" + s[-40:]


def sel(sig):
    import hashlib

    return "0x" + hashlib.sha3_256(sig.encode()).hexdigest()[:8]


if __name__ == "__main__":
    b = block_number()
    print("latest block", b)
    for a in sys.argv[1:]:
        c = get_code(a, b)
        print(a, "codebytes", (len(c) - 2) // 2, "impl", impl_slot(a, b) if (len(c) - 2) // 2 > 100 else "-")
