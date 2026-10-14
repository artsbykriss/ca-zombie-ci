#!/usr/bin/env python3
"""Find the creation block (and creator tx) of a MinMax pool via binary search on eth_getCode."""
import json, sys, time, urllib.request

RPC = "https://babel-api.mainnet.iotex.io"

def rpc(method, params, retries=2):
    for _ in range(retries + 1):
        try:
            req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=25) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(0.5)
    return {}

def has_code(addr, block):
    d = rpc("eth_getCode", [addr, hex(block)])
    return len(d.get("result", "0x")) > 3

if __name__ == "__main__":
    addr = sys.argv[1]
    latest = int(rpc("eth_blockNumber", [])["result"], 16)
    lo, hi = 1, latest
    if not has_code(addr, latest):
        print("no code at latest"); sys.exit(1)
    while lo < hi:
        mid = (lo + hi) // 2
        if has_code(addr, mid):
            hi = mid
        else:
            lo = mid + 1
    print("creation block:", lo)
    blk = rpc("eth_getBlockByNumber", [hex(lo), True]).get("result", {})
    txs = blk.get("transactions", [])
    print("txs in block:", len(txs))
    for tx in txs:
        if tx.get("to") is None or tx["to"] == "":
            rc = rpc("eth_getTransactionReceipt", [tx["hash"]]).get("result") or {}
            if (rc.get("contractAddress") or "").lower() == addr.lower():
                print("CREATOR TX:", tx["hash"])
                print("  from (factory):", tx["from"])
                print("  input:", tx["input"][:80])
                json.dump({"pool": addr, "creation_block": lo, "creator": tx["from"], "tx": tx["hash"], "input": tx["input"]}, open("factory_find.json", "w"), indent=1)
                break
