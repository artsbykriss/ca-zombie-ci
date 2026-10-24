#!/usr/bin/env python3
"""Read-only: scan a THORChain height window for CosmWasm (MsgExecuteContract) txs.
Looks for the 2026-09-26 FIN CCL range-transfer incident footprint.
No secrets, no transactions."""
import json, urllib.request, urllib.parse, sys, collections
from concurrent.futures import ThreadPoolExecutor

BASE = "https://gateway.liquify.com/chain/thorchain_api"

def txs_at(h):
    u = BASE + "/cosmos/tx/v1beta1/txs?" + urllib.parse.urlencode(
        {"query": f"tx.height={h}", "pagination.limit": 200})
    for _ in range(3):
        try:
            d = json.load(urllib.request.urlopen(u, timeout=40))
            return list(zip(d.get("tx_responses", []), d.get("txs", [])))
        except Exception:
            pass
    return None

def scan(h):
    out = []
    pairs = txs_at(h)
    if pairs is None:
        return [("ERR", h)]
    for resp, tx in pairs:
        for m in tx.get("body", {}).get("messages", []):
            if "MsgExecuteContract" in m.get("@type", ""):
                out.append((h, resp.get("txhash", "?"), m, tx.get("memo", ""),
                            resp.get("code"), resp.get("logs")))
    return out

def main():
    lo, hi = int(sys.argv[1]), int(sys.argv[2])
    res = []
    with ThreadPoolExecutor(max_workers=10) as ex:
        for r in ex.map(scan, range(lo, hi)):
            for item in r:
                if item[0] == "ERR":
                    print("err at", item[1], flush=True)
                else:
                    res.append(item)
                    print("WASM", item[0], item[1], json.dumps(item[2])[:400],
                          "memo=", item[3][:80], "code=", item[4], flush=True)
    print("done: wasm txs =", len(res), flush=True)

if __name__ == "__main__":
    main()
