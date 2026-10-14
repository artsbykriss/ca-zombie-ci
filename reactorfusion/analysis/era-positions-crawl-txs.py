#!/usr/bin/env python3
"""Crawl all transactions to each ReactorFusion Era cToken via zkSync explorer
Etherscan-style txlist API, sliced into block windows (API caps at 1000 rows).

Read-only. Stores compact per-tx records (methodId + input) for account
enumeration: borrow/repay/liquidate/mint/redeem callers.

Usage: python3 era-positions-crawl-txs.py [market_label ...]
"""
import json, os, sys, time, urllib.request, urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://block-explorer-api.mainnet.zksync.io/api"
MIN_WINDOW = 2_000
SLEEP = 0.25

MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}


def fetch_txlist(addr, lo, hi, timeout=45):
    q = urllib.parse.urlencode({
        "module": "account", "action": "txlist", "address": addr,
        "startblock": lo, "endblock": hi, "page": 1, "offset": 1000, "sort": "asc",
    })
    req = urllib.request.Request(f"{API}?{q}", headers={"User-Agent": "research-read-only"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            j = json.loads(r.read())
    except Exception as e:
        return None, f"transport: {str(e)[:110]}", time.time() - t0
    if isinstance(j.get("result"), list):
        return j["result"], None, time.time() - t0
    msg = str(j.get("message"))
    if "No transactions found" in msg:
        return [], None, time.time() - t0
    return None, f"api: {msg[:140]} / {str(j.get('result'))[:80]}", time.time() - t0


def crawl(label, addr, latest, tag=""):
    suf = f"-{tag}" if tag else ""
    tx_path = os.path.join(HERE, f"era-positions-txs-{label}{suf}.jsonl")
    st_path = os.path.join(HERE, f"era-positions-txstate-{label}{suf}.json")
    if os.path.exists(st_path):
        st = json.load(open(st_path))
        if st.get("finished"):
            print(f"[{label}] already finished: {st.get('n_txs')} txs", flush=True)
            return
    else:
        st = {"queue": [[1_900_000, latest]], "done": [], "failed": [], "n_txs": 0, "partial_windows": []}
    f = open(tx_path, "a")
    while st["queue"]:
        lo, hi = st["queue"].pop(0)
        res, err, dt = fetch_txlist(addr, lo, hi)
        if res is None:
            # transient transport issues: retry the same window, do NOT split
            for attempt in range(4):
                time.sleep(1.5 * (attempt + 1))
                res, err, dt = fetch_txlist(addr, lo, hi)
                if res is not None:
                    break
        if res is None:
            st["failed"].append([lo, hi, err])
            print(f"[{label}] FAILED {lo}-{hi}: {err}", flush=True)
            json.dump(st, open(st_path, "w"))
            continue
        if len(res) >= 1000 and hi > lo:
            mid = (lo + hi) // 2
            st["queue"] = [[lo, mid], [mid + 1, hi]] + st["queue"]
            print(f"[{label}] split(1000) {lo}-{hi}", flush=True)
            json.dump(st, open(st_path, "w"))
            continue
        if len(res) >= 1000 and hi == lo:
            st["partial_windows"].append([lo, hi])
            print(f"[{label}] PARTIAL single-block window {lo}", flush=True)
        for x in res:
            rec = {"b": int(x["blockNumber"]), "tx": x["hash"], "from": (x.get("from") or "").lower(),
                   "to": (x.get("to") or "").lower(), "mid": (x.get("methodId") or "").lower(),
                   "fn": x.get("functionName") or "", "in": (x.get("input") or "")[:1200],
                   "err": x.get("isError")}
            f.write(json.dumps(rec, separators=(",", ":")) + "\n")
        st["n_txs"] += len(res)
        st["done"].append([lo, hi, len(res)])
        f.flush()
        json.dump(st, open(st_path, "w"))
        print(f"[{label}] {lo}-{hi}: {len(res)} txs (total {st['n_txs']})", flush=True)
        time.sleep(SLEEP)
    f.close()
    st["finished"] = True
    json.dump(st, open(st_path, "w"), indent=1)
    print(f"[{label}] TXCRAWL DONE total={st['n_txs']} failed={len(st['failed'])} partial={len(st['partial_windows'])}", flush=True)


def main():
    args = sys.argv[1:]
    tag = ""
    if "--tag" in args:
        i = args.index("--tag")
        tag = args[i + 1]
        args = args[:i] + args[i + 2:]
    args = args or list(MARKETS.keys())
    latest = None
    for attempt in range(12):
        for ep in ["https://zksync.drpc.org/", "https://mainnet.era.zksync.io/"]:
            try:
                req = urllib.request.Request(ep, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}).encode(),
                                             headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
                with urllib.request.urlopen(req, timeout=30) as r:
                    latest = int(json.loads(r.read())["result"], 16)
                break
            except Exception:
                continue
        if latest:
            break
        time.sleep(2.0 * (attempt + 1))
    if latest is None:
        sys.exit("could not fetch latest block")
    print(f"latest block {latest}", flush=True)
    for label in args:
        crawl(label, MARKETS[label], latest, tag)


if __name__ == "__main__":
    main()
