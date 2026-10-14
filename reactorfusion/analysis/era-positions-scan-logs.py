#!/usr/bin/env python3
"""Chunked eth_getLogs scanner for ReactorFusion Era cTokens (read-only).

Source: zkSync Era public RPC (mainnet.era.zksync.io, NOTE trailing slash avoids
the 301 that breaks JSON-RPC). Recursive splitting on the node's 10k-result cap
and on transport timeouts. Saves compact JSONL per market + segment record.
Resume-safe.

Usage: python3 era-positions-scan-logs.py [market_label ...]
"""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
START = 1_900_000            # first cToken event ~1,955,259
INIT_CHUNK = 1_000_000
MIN_CHUNK = 25_000
REQ_TIMEOUT = 30
RETRIES_SMALL = 4

import os as _os
ENDPOINTS = ["https://mainnet.era.zksync.io/"]
if _os.environ.get("ALCHEMY_API_KEY_2"):
    ENDPOINTS.append("https://zksync-mainnet.g.alchemy.com/v2/" + _os.environ["ALCHEMY_API_KEY_2"])
if _os.environ.get("INFURA_API_KEY"):
    ENDPOINTS.append("https://zksync-mainnet.infura.io/v3/" + _os.environ["INFURA_API_KEY"])

TOPICS = [
    "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80",  # Borrow
    "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f",  # Mint
    "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1",  # RepayBorrow
    "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929",  # Redeem
    "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52",  # LiquidateBorrow
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",  # Transfer
]

MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}


def rpc_getlogs(url, addr, lo, hi, timeout=REQ_TIMEOUT):
    payload = {"jsonrpc": "2.0", "id": 1, "method": "eth_getLogs",
               "params": [{"address": addr, "fromBlock": hex(lo), "toBlock": hex(hi), "topics": [TOPICS]}]}
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            j = json.loads(r.read())
    except Exception as e:
        return None, f"transport: {str(e)[:110]}", time.time() - t0
    if "result" in j:
        return j["result"], None, time.time() - t0
    return None, f"rpc: {str(j.get('error'))[:200]}", time.time() - t0


def scan_market(label, addr, latest, lo_arg=None, hi_arg=None, tag=""):
    suf = f"-{tag}" if tag else ""
    log_path = os.path.join(HERE, f"era-positions-rpclogs-{label}{suf}.jsonl")
    seg_path = os.path.join(HERE, f"era-positions-rpcsegments-{label}{suf}.json")
    if os.path.exists(seg_path):
        state = json.load(open(seg_path))
    else:
        lo0 = lo_arg if lo_arg is not None else START
        hi0 = hi_arg if hi_arg is not None else latest
        q = [[lo, min(lo + INIT_CHUNK - 1, hi0)] for lo in range(lo0, hi0 + 1, INIT_CHUNK)]
        state = {"done": [], "failed": [], "queue": q, "n_logs": 0, "topic_counts": {}, "range": [lo0, hi0]}
    f = open(log_path, "a")
    t0 = time.time()
    while state["queue"]:
        lo, hi = state["queue"].pop(0)
        outcome = None  # ("ok", res) | ("split",) | ("failed", err)
        for attempt in range(RETRIES_SMALL):
            for ep in ENDPOINTS:
                res, err, dt = rpc_getlogs(ep, addr, lo, hi)
                if res is not None:
                    outcome = ("ok", res)
                    break
                if "more than 10000" in (err or ""):
                    outcome = ("split",)
                    break
            if outcome:
                break
            # transport failure: big chunks split immediately, small ones retry
            if hi - lo > MIN_CHUNK:
                outcome = ("split",)
                break
            time.sleep(0.5 + attempt * 1.0)
        if outcome is None:
            outcome = ("split",) if hi - lo > MIN_CHUNK else ("failed", err)
        if outcome[0] == "split":
            mid = (lo + hi) // 2
            if hi - lo <= MIN_CHUNK:
                state["failed"].append([lo, hi, "10k cap or transport at min chunk"])
                print(f"[{label}] FAILED min-chunk {lo}-{hi}", flush=True)
            else:
                state["queue"] = [[lo, mid], [mid + 1, hi]] + state["queue"]
                print(f"[{label}] split {lo}-{hi}", flush=True)
            json.dump(state, open(seg_path, "w"))
            continue
        if outcome[0] == "failed":
            state["failed"].append([lo, hi, outcome[1]])
            print(f"[{label}] FAILED {lo}-{hi}: {outcome[1]}", flush=True)
            json.dump(state, open(seg_path, "w"))
            continue
        res = outcome[1]
        for x in res:
            t = x["topics"][0]
            state["topic_counts"][t] = state["topic_counts"].get(t, 0) + 1
            rec = {"b": int(x["blockNumber"], 16), "i": int(x["logIndex"], 16),
                   "tx": x["transactionHash"], "t": x["topics"], "d": x["data"]}
            f.write(json.dumps(rec, separators=(",", ":")) + "\n")
        state["n_logs"] += len(res)
        state["done"].append([lo, hi, len(res)])
        f.flush()
        json.dump(state, open(seg_path, "w"))
        print(f"[{label}] {lo}-{hi}: {len(res)} logs (total {state['n_logs']})", flush=True)
    f.close()
    state["finished"] = True
    state["elapsed_s"] = round(time.time() - t0, 1)
    json.dump(state, open(seg_path, "w"), indent=1)
    print(f"[{label}] SCAN DONE total={state['n_logs']} failed={len(state['failed'])}", flush=True)


def main():
    args = sys.argv[1:]
    lo_arg = hi_arg = None
    tag = ""
    label_args = []
    i = 0
    while i < len(args):
        if args[i] == "--lo":
            lo_arg = int(args[i + 1]); i += 2
        elif args[i] == "--hi":
            hi_arg = int(args[i + 1]); i += 2
        elif args[i] == "--tag":
            tag = args[i + 1]; i += 2
        else:
            label_args.append(args[i]); i += 1
    labels = label_args or list(MARKETS.keys())
    latest = None
    for ep in ["https://zksync.drpc.org/", "https://mainnet.era.zksync.io/"]:
        try:
            req = urllib.request.Request(ep, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
                                         headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=30) as r:
                latest = int(json.loads(r.read())["result"], 16)
            break
        except Exception:
            continue
    if latest is None:
        sys.exit("no rpc for latest block")
    print(f"latest block {latest}", flush=True)
    for label in labels:
        scan_market(label, MARKETS[label], latest, lo_arg, hi_arg, tag)


if __name__ == "__main__":
    main()
