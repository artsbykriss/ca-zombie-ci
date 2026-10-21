#!/usr/bin/env python3
"""ERC-20 / ERC-721 / ERC-1155 inbound-transfer scan for every factory account.

Source of truth: Etherscan V2 (chainid 42161) per-address transfer lists.
Any non-zero ERC-20 balance requires an inbound Transfer event, so an empty
`tokentx` list is a proof of zero token balance for that address.
Key never printed/written; read from env.
"""
import json, os, sys, time, urllib.request, threading

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ["ETHERSCANV2_API_KEY"]
BASE = "https://api.etherscan.io/v2/api?chainid=42161"
OUT = os.path.join(HERE, "token-hits.json")
lock = threading.Lock()
_done = [0]


def fetch(action, addr, page=1, offset=100):
    url = f"{BASE}&module=account&action={action}&address={addr}&page={page}&offset={offset}&sort=asc&apikey={KEY}"
    for attempt in range(8):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                d = json.load(r)
            if d.get("status") == "1":
                return d["result"]
            if "No transactions found" in str(d.get("message")) or "No token transfers" in str(d.get("message")):
                return []
            if "rate limit" in str(d.get("result", "")).lower() or "Max calls" in str(d.get("result", "")):
                time.sleep(1.5 * (attempt + 1)); continue
            return {"__error__": d}
        except Exception as e:
            time.sleep(1.0 * (attempt + 1))
    return {"__error__": "retries exhausted"}


def worker(addrs, action, out):
    for a in addrs:
        res = fetch(action, a)
        with lock:
            out[a] = res
            _done[0] += 1
            if _done[0] % 150 == 0:
                print(f"{action} {_done[0]}", file=sys.stderr)
                json.dump(out, open(OUT + f".{action}.part", "w"))
        time.sleep(0.18)


def main():
    d = json.load(open(os.path.join(HERE, "census.json")))
    addrs = sorted(d["contracts"])
    results = {}
    for action in ("tokentx", "tokennfttx", "token1155tx"):
        part = OUT + f".{action}"
        if os.path.exists(part):
            out = json.load(open(part))
        else:
            out = {}
            n = 6
            th = [threading.Thread(target=worker, args=(addrs[i::n], action, out)) for i in range(n)]
            [t.start() for t in th]; [t.join() for t in th]
            json.dump(out, open(part, "w"))
        results[action] = out
    hits = {}
    for a in addrs:
        lst = []
        for action in results:
            r = results[action].get(a)
            if isinstance(r, list) and r:
                lst.append((action, len(r)))
        if lst:
            hits[a] = lst
    json.dump({"scanned": len(addrs), "hits": hits,
               "errors": {a: v for a in addrs for v in [results["tokentx"].get(a)] if isinstance(v, dict)}},
              open(OUT, "w"), indent=1)
    print("scanned", len(addrs), "addresses with any token transfer:", len(hits))


if __name__ == "__main__":
    main()
