#!/usr/bin/env python3
"""Crawl zkSync explorer txlist for ReactorFusion cTokens to enumerate borrowers
(missing block ranges). Read-only; keyless explorer API. Writes analysis/era-crawl/*.jsonl
No secrets. Resumable: skips pages already in the jsonl.
"""
import json, os, sys, time, urllib.request, glob

EXPL = "https://block-explorer-api.mainnet.zksync.io/api"
BORROW_SEL = "0xc5ebeaec"      # borrow(uint256)
REPAY_SEL = "0x0e752702"       # repayBorrow(uint256)
LIQ_SEL = "0xf5e3c0a4"         # liquidateBorrow(address,uint256,address) (guess; verified below)
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH": "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC": "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT": "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK": "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDCz": "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
START = 1800000
OUTDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "era-crawl")
os.makedirs(OUTDIR, exist_ok=True)


def fetch(url, tries=6):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research-read-only"})
            with urllib.request.urlopen(req, timeout=90) as r:
                body = r.read()
            return json.loads(body)
        except Exception as e:
            last = e
            time.sleep(2 + 2 * i)
    raise last


def crawl_market(name, addr, startblock=START):
    fn = os.path.join(OUTDIR, f"{name}.jsonl")
    sb = startblock
    if os.path.exists(fn):
        with open(fn) as f:
            for line in f:
                try:
                    j = json.loads(line)
                    sb = max(sb, j.get("endblock", 0) + 1)
                except Exception:
                    pass
    while True:
        url = (f"{EXPL}?module=account&action=txlist&address={addr}&startblock={sb}&endblock=latest"
               f"&sort=asc&page=1&offset=1000")
        try:
            d = fetch(url)
        except Exception as e:
            print(f"[{name}] start {sb} fetch fail: {e}", flush=True)
            time.sleep(10)
            continue
        res = d.get("result")
        if not isinstance(res, list):
            print(f"[{name}] start {sb} non-list: {str(d)[:150]}", flush=True)
            time.sleep(10)
            continue
        txs = []
        for t in res:
            inp = (t.get("input") or "")
            sel = inp[:10]
            if sel in (BORROW_SEL, REPAY_SEL):
                txs.append({"b": int(t["blockNumber"]), "h": t["hash"], "f": t["from"].lower(),
                            "sel": sel, "in": inp[:74]})
        last = int(res[-1]["blockNumber"]) if res else sb
        with open(fn, "a") as f:
            f.write(json.dumps({"startblock": sb, "endblock": last, "n": len(res), "txs": txs}) + "\n")
        print(f"[{name}] blocks {sb}-{last} n={len(res)} borrow/repay={len(txs)}", flush=True)
        if len(res) < 1000:
            break
        sb = last + 1


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "rfETH"
    sb = int(sys.argv[2]) if len(sys.argv) > 2 else START
    crawl_market(which, MARKETS[which], sb)
