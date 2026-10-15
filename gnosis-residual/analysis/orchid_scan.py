#!/usr/bin/env python3
"""Fetch all Update(bytes32,uint256) logs for OrchidLottery1 on Gnosis, keep last cache per key.
Read-only. Writes JSON summary to /tmp/opencode/orchid_state.json (no secrets)."""
import json, urllib.request, sys

RPC = "https://rpc.gnosischain.com"
ADDR = "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"
TOPIC = "0x05241a2ddcbea46fa2f8b84beea5d0d8c0fd21414503d644982a75ccf1d986aa"
START = 15089781
END = None

def rpc(method, params):
    req = urllib.request.Request(RPC, data=json.dumps({"jsonrpc":"2.0","id":1,"method":method,"params":params}).encode(),
                                 headers={"Content-Type":"application/json","User-Agent":"Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=180) as r:
        d = json.loads(r.read())
    if "error" in d:
        raise RuntimeError(d["error"])
    return d["result"]

def main():
    global END
    latest = int(rpc("eth_blockNumber", []), 16)
    END = latest
    last = {}  # key -> cache int
    first_blk = {}
    last_blk = {}
    chunk = 2_000_000
    n_logs = 0
    b = START
    while b <= END:
        e = min(b + chunk - 1, END)
        logs = rpc("eth_getLogs", [{"fromBlock": hex(b), "toBlock": hex(e), "address": ADDR, "topics": [TOPIC]}])
        n_logs += len(logs)
        for l in logs:
            key = l["topics"][1]
            cache = int(l["data"], 16)
            last[key] = cache
            last_blk[key] = int(l["blockNumber"], 16)
            if key not in first_blk:
                first_blk[key] = int(l["blockNumber"], 16)
        print(f"chunk {b}-{e}: {len(logs)} logs, total {n_logs}, keys {len(last)}", flush=True)
        b = e + 1

    # sum
    total_escrow = 0
    total_amount = 0
    n_keys = len(last)
    for key, cache in last.items():
        escrow = cache >> 128
        amount = cache & ((1 << 128) - 1)
        total_escrow += escrow
        total_amount += amount
    out = {
        "latest_block": latest,
        "n_update_logs": n_logs,
        "n_keys_with_update": n_keys,
        "total_escrow_wei": str(total_escrow),
        "total_amount_wei": str(total_amount),
        "total_accounted_wei": str(total_escrow + total_amount),
        "total_escrow_xdai": total_escrow / 1e18,
        "total_amount_xdai": total_amount / 1e18,
    }
    json.dump(out, open("/tmp/opencode/orchid_state.json", "w"), indent=1)
    print(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
