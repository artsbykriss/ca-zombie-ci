#!/usr/bin/env python3
"""Crawl GoldRush events/address for the 6 ReactorFusion zkSync Era cTokens.

Read-only. Key comes from env GOLD_RUSH_API_KEY (never persisted / never logged).
Writes compact per-log JSONL + meta into analysis/.

Usage: python3 era-positions-crawl.py
"""
import json, os, sys, time, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
CHAIN = "zksync-mainnet"
START_BLOCK = 1500000  # before first cToken event (~1,955,259); '1'/'earliest' are broken on this API
PAGE_SIZE = 1000
SLEEP = 0.7
MAX_PAGES = 400

MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}

TOPICS = {
    "0x13ed6866d4e1ee6da46f845c46d7e54120883d75c5ea9a2dacc1c4ca8984ab80": "Borrow",
    "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f": "Mint",
    "0x1a2a22cb034d26d1854bdc6666a5b91fe25efbbb5dcad3b0355478d6f5c362a1": "RepayBorrow",
    "0xe5b754fb1abb7f01b499791d0b820ae3b6af3424ac1c59768edb53f4ec31a929": "Redeem",
    "0x298637f684da70674f26509b10f07ec2fbc77a335ab1e7d6215a4b2484d8bb52": "LiquidateBorrow",
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef": "Transfer",
    "0x4dec04e750ca11537cabcd8a9eab06494de08da3735bc8871cd41250e190bc04": "AccrueInterest",
}

KEY = os.environ.get("GOLD_RUSH_API_KEY")
if not KEY:
    sys.exit("GOLD_RUSH_API_KEY not set (source /home/heisenberg/CA/.env)")


def fetch(url, tries=5):
    last = None
    for a in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read())
        except Exception as e:  # noqa
            last = e
            time.sleep(1.5 * (a + 1))
    raise last


def crawl(label, addr):
    out_path = os.path.join(HERE, f"era-positions-logs-{label}.jsonl")
    meta_path = os.path.join(HERE, f"era-positions-logmeta-{label}.json")
    if os.path.exists(meta_path):
        m = json.load(open(meta_path))
        if m.get("done"):
            print(f"[{label}] already done: {m['n_logs']} logs", flush=True)
            return m
    topic_counts = {}
    n = 0
    page = 0
    seen_first = None
    last_block_seen = None
    t0 = time.time()
    # resume support: append-only, find count of lines already downloaded
    done_pages = 0
    if os.path.exists(out_path) and os.path.exists(meta_path + ".partial"):
        pp = json.load(open(meta_path + ".partial"))
        done_pages = pp.get("pages_done", 0)
        n = pp.get("n_logs", 0)
        topic_counts = pp.get("topic_counts", {})
        page = done_pages
        print(f"[{label}] resuming at page {page} with {n} logs", flush=True)
        f = open(out_path, "a")
    else:
        f = open(out_path, "w")
    while page < MAX_PAGES:
        url = (f"https://api.covalenthq.com/v1/{CHAIN}/events/address/{addr}/"
               f"?key={KEY}&starting-block={START_BLOCK}&page-size={PAGE_SIZE}&page-number={page}")
        j = fetch(url)
        if j.get("error"):
            print(f"[{label}] page {page} API error: {j.get('error_message')}", flush=True)
            if "No events" in str(j.get("error_message")):
                break
            raise RuntimeError(j.get("error_message"))
        items = (j.get("data") or {}).get("items") or []
        for x in items:
            t = (x.get("raw_log_topics") or [None])[0]
            topic_counts[t] = topic_counts.get(t, 0) + 1
            rec = {
                "b": x["block_height"], "o": x["log_offset"], "tx": x["tx_hash"],
                "t": x["raw_log_topics"], "d": x.get("raw_log_data"),
            }
            f.write(json.dumps(rec, separators=(",", ":")) + "\n")
            if seen_first is None:
                seen_first = (x["block_height"], x["log_offset"])
            last_block_seen = (x["block_height"], x["log_offset"])
        n += len(items)
        p = (j.get("data") or {}).get("pagination") or {}
        page += 1
        done_pages = page
        f.flush()
        json.dump({"pages_done": done_pages, "n_logs": n, "topic_counts": topic_counts},
                  open(meta_path + ".partial", "w"))
        print(f"[{label}] page {page} items {len(items)} total {n} has_more={p.get('has_more')} "
              f"last_block={last_block_seen}", flush=True)
        if not p.get("has_more") or len(items) == 0:
            break
        time.sleep(SLEEP)
    f.close()
    names = {TOPICS.get(k, k): v for k, v in topic_counts.items()}
    meta = {"market": label, "address": addr, "chain": CHAIN, "source": "goldrush-events-api (keyed-env)",
            "starting_block": START_BLOCK, "done": True, "n_logs": n, "pages": done_pages,
            "first_log": seen_first, "last_log": last_block_seen,
            "topic_counts_raw": topic_counts, "topic_counts_named": names,
            "elapsed_s": round(time.time() - t0, 1)}
    json.dump(meta, open(meta_path, "w"), indent=1)
    print(f"[{label}] DONE {n} logs -> {out_path}", flush=True)
    return meta


def main():
    summaries = {}
    for label, addr in MARKETS.items():
        try:
            summaries[label] = crawl(label, addr)
        except Exception as e:
            print(f"[{label}] FAILED: {str(e)[:300]}", flush=True)
            summaries[label] = {"market": label, "address": addr, "error": str(e)[:300]}
    json.dump(summaries, open(os.path.join(HERE, "era-positions-crawl-summary.json"), "w"), indent=1)
    print("ALL DONE", flush=True)


if __name__ == "__main__":
    main()
