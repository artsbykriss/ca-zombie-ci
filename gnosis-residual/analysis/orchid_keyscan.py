#!/usr/bin/env python3
"""Re-scan Orchid Update logs, dump per-key final cache (escrow, amount) to JSON.
Read-only, public RPC only. Output: /tmp/opencode/orchid_keys.json"""
import json, urllib.request

RPC = "https://rpc.gnosischain.com"
ADDR = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"
TOPIC = "0x05241a2ddcbea46fa2f8b84beea5d0d8c0fd21414503d644982a75ccf1d986aa"
START = 15089781

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=180) as r:
        d = json.loads(r.read())
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]

latest = int(rpc("eth_blockNumber", []), 16)
last = {}
b = START
chunk = 2_000_000
while b <= latest:
    e = min(b + chunk - 1, latest)
    logs = rpc("eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(e), "address": ADDR, "topics": [TOPIC]}])
    for l in logs:
        last[l["topics"][1]] = int(l["data"], 16)
    b = e + 1
out = {k: {"cache": str(v), "escrow": str(v >> 128), "amount": str(v & ((1 << 128) - 1))} for k, v in last.items()}
json.dump({"latest_block": latest, "n_keys": len(last), "keys": out}, open("/tmp/opencode/orchid_keys.json", "w"))
print("done", len(last))
