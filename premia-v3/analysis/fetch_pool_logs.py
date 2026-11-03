#!/usr/bin/env python3
"""Independently enumerate Premia V3 PoolDeployed logs (Arbitrum) via Etherscan V2.

Read-only. No secrets are written to disk: the API key is read from the
environment (ETHERSCANV2_API_KEY) or /home/heisenberg/CA/.env at runtime.
Checkpoints each 10M-block window to pooldeployed_raw.jsonl so it can resume.
Outputs: pools.json {head, n_logs, pools{addr: {...}}}
"""
import json
import os
import re
import sys
import time
import urllib.request

FACTORY = "0xAE4fB6622F25f397587F11638dA8CE88C27b5645"
TOPIC0 = "0xd9277e7d7e4b6de43cfbc694bf1e8729a47665e65fe33fc88b39956e35fc9b8b"
START = 119_998_935
CHUNK = 10_000_000
OUTDIR = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(OUTDIR, "pooldeployed_raw.jsonl")
CKPT = os.path.join(OUTDIR, "pooldeployed_chunks.json")


def api_key():
    k = os.environ.get("ETHERSCANV2_API_KEY", "")
    if k:
        return k
    try:
        env = open("/home/heisenberg/CA/.env").read()
        m = re.search(r"^ETHERSCANV2_API_KEY=(.*)$", env, re.M)
        if m:
            return m.group(1).strip().strip('"').strip("'")
    except OSError:
        pass
    return ""


KEY = api_key()
if not KEY:
    sys.exit("no ETHERSCANV2_API_KEY")

BASE = (
    "https://api.etherscan.io/v2/api?chainid=42161&module=logs&action=getLogs"
    f"&address={FACTORY}&topic0={TOPIC0}&offset=1000&apikey={KEY}"
)


def get(url, tries=5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read())
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(str(last)[:200])


def head_block():
    req = urllib.request.Request(
        "https://arb1.arbitrum.io/rpc",
        data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
        headers={"content-type": "application/json", "User-Agent": "Mozilla/5.0"},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return int(json.loads(r.read())["result"], 16)


def fetch_chunk(lo, hi):
    logs = []
    page = 1
    while True:
        d = get(f"{BASE}&fromBlock={lo}&toBlock={hi}&page={page}")
        if d.get("status") != "1":
            msg = str(d.get("message"))
            if "No records" in msg or "No logs" in msg:
                break
            raise RuntimeError(f"{lo}-{hi} p{page}: {msg} {str(d.get('result'))[:120]}")
        res = d["result"]
        logs.extend(res)
        if len(res) < 1000:
            break
        page += 1
        time.sleep(0.11)
    return logs


def main():
    head = head_block()
    print(f"head={head}", flush=True)
    done = {}
    if os.path.exists(CKPT):
        done = json.load(open(CKPT)).get("chunks", {})
    fh = open(RAW, "a")
    for lo in range(START, head + 1, CHUNK):
        hi = min(lo + CHUNK - 1, head)
        key = f"{lo}-{hi}"
        if key in done:
            continue
        logs = fetch_chunk(lo, hi)
        for l in logs:
            fh.write(json.dumps(l) + "\n")
        fh.flush()
        done[key] = len(logs)
        json.dump({"head": head, "chunks": done}, open(CKPT, "w"))
        print(f"{lo}-{hi}: {len(logs)} (cum {sum(done.values())})", flush=True)
        time.sleep(0.11)
    fh.close()

    uniq = {}
    for line in open(RAW):
        l = json.loads(line)
        uniq[(l["transactionHash"], l["logIndex"])] = l
    pools = {}
    for l in uniq.values():
        w = [l["data"][2 + i * 64 : 2 + (i + 1) * 64] for i in range((len(l["data"]) - 2) // 64)]
        pool = "0x" + w[4][-40:]
        pools[pool.lower()] = {
            "pool": pool,
            "base": "0x" + l["topics"][1][-40:],
            "quote": "0x" + l["topics"][2][-40:],
            "oracle": "0x" + w[0][-40:],
            "strike": int(w[1], 16),
            "maturity": int(w[2], 16),
            "isCall": int(w[3], 16) != 0,
            "block": int(l["blockNumber"], 16),
            "tx": l["transactionHash"],
        }
    json.dump(
        {"head": head, "n_logs": len(uniq), "pools": pools},
        open(os.path.join(OUTDIR, "pools.json"), "w"),
    )
    print(f"logs={len(uniq)} unique_pools={len(pools)}", flush=True)


if __name__ == "__main__":
    main()
