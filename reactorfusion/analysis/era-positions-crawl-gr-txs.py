#!/usr/bin/env python3
"""Crawl GoldRush transactions_v2 for each ReactorFusion Era cToken.

Saves compact records: {b, tx, from, to, logs: [cToken logs only]}.
The tx list is complete+current (unlike GoldRush events/address), so this gives:
  - account universe (from_address of every tx touching a cToken)
  - the cToken event stream (logs inside those txs)
Usage: python3 era-positions-crawl-gr-txs.py [label ...]
"""
import json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KEY = os.environ.get("GOLD_RUSH_API_KEY")
if not KEY:
    sys.exit("GOLD_RUSH_API_KEY not set")
CHAIN = "zksync-mainnet"
PAGE = 1000
SLEEP = 0.6
MAX_PAGES = 500
MIN_BLOCK = 1_950_000

MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
ALL_ADDRS = {v.lower() for v in MARKETS.values()}
TOPICS = {
    "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
    "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
    "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
    "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
    "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer",
}


def fetch(url, tries=5):
    last = None
    for a in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.loads(r.read())
        except Exception as e:
            last = e
            time.sleep(1.5 * (a + 1))
    raise last


def crawl(label, addr):
    out_path = os.path.join(HERE, f"era-positions-grtxs-{label}.jsonl")
    st_path = os.path.join(HERE, f"era-positions-grtxstate-{label}.json")
    st = json.load(open(st_path)) if os.path.exists(st_path) else {"page": 0, "n_txs": 0, "min_block": None, "done": False}
    if st.get("done"):
        print(f"[{label}] already done: {st['n_txs']} txs, min_block {st['min_block']}", flush=True)
        return
    f = open(out_path, "a")
    page = st["page"]
    while page < MAX_PAGES:
        url = (f"https://api.covalenthq.com/v1/{CHAIN}/address/{addr}/transactions_v2/"
               f"?key={KEY}&page-size={PAGE}&page-number={page}")
        j = fetch(url)
        if j.get("error"):
            raise RuntimeError(str(j.get("error_message"))[:200])
        items = (j.get("data") or {}).get("items") or []
        if not items:
            break
        for x in items:
            logs = []
            for e in (x.get("log_events") or []):
                sender = (e.get("sender_address") or "").lower()
                if sender in ALL_ADDRS:
                    logs.append({"s": sender, "t": e.get("raw_log_topics"), "d": e.get("raw_log_data")})
            rec = {"b": x["block_height"], "tx": x["tx_hash"],
                   "from": (x.get("from_address") or "").lower(), "to": (x.get("to_address") or "").lower(),
                   "v": x.get("value"), "err": x.get("successful"), "logs": logs}
            f.write(json.dumps(rec, separators=(",", ":")) + "\n")
        st["n_txs"] += len(items)
        st["page"] = page + 1
        mb = min(x["block_height"] for x in items)
        st["min_block"] = min(st["min_block"], mb) if st["min_block"] else mb
        f.flush()
        json.dump(st, open(st_path, "w"))
        p = (j.get("data") or {}).get("pagination") or {}
        print(f"[{label}] page {page}: {len(items)} txs total {st['n_txs']} min_blk {st['min_block']} has_more {p.get('has_more')}", flush=True)
        page += 1
        if not p.get("has_more") or mb <= MIN_BLOCK:
            break
        time.sleep(SLEEP)
    f.close()
    st["done"] = True
    json.dump(st, open(st_path, "w"), indent=1)
    print(f"[{label}] DONE {st['n_txs']} txs, min_block {st['min_block']}", flush=True)


def main():
    labels = sys.argv[1:] or list(MARKETS.keys())
    for label in labels:
        try:
            crawl(label, MARKETS[label])
        except Exception as e:
            print(f"[{label}] FAILED {str(e)[:200]}", flush=True)


if __name__ == "__main__":
    main()
