#!/usr/bin/env python3
"""Scan full-chain logs for factory + beacon in 10M-block chunks via public RPC."""
import json, time, sys, urllib.request

RPC = "https://rpc.mainnet.chain.robinhood.com"
CHUNK = 10_000_000

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json",
                 "User-Agent": "Mozilla/5.0 arcus-analysis/1.0"})
    with urllib.request.urlopen(req, timeout=120) as r:
        d = json.load(r)
    if "error" in d: raise RuntimeError(d["error"])
    return d["result"]

latest = int(rpc("eth_blockNumber", []), 16)
targets = {
    "factory": "0x9c3663FA9ab976E67B42939486EC4966Cb41a0BB",
    "beacon": "0x33846348210A0Cc0345F354d9DE52b89AD473A76",
}
out = {}
for name, addr in targets.items():
    logs = []
    frm = 0
    while frm <= latest:
        to = min(frm + CHUNK - 1, latest)
        try:
            res = rpc("eth_getLogs", [{"address": addr, "fromBlock": hex(frm), "toBlock": hex(to)}])
        except Exception as e:
            time.sleep(2)
            res = rpc("eth_getLogs", [{"address": addr, "fromBlock": hex(frm), "toBlock": hex(to)}])
        logs.extend(res)
        frm = to + 1
        time.sleep(0.3)
    out[name] = logs
    print(f"{name}: {len(logs)} logs (latest={latest})", file=sys.stderr)
json.dump(out, open("/home/heisenberg/CA/arcus/analysis/factory_beacon_logs.json", "w"), indent=1)
print("saved", file=sys.stderr)
