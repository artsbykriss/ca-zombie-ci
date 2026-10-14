#!/usr/bin/env python3
"""Targeted debt scan: read borrowBalanceStored for the top inflow accounts of a market.

Usage: python3 era-positions-debtscan.py <market> <topN> <workers>
"""
import glob, json, os, sys, time, urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
URLS = []
if os.environ.get("ALCHEMY_API_KEY_2"):
    URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + os.environ["ALCHEMY_API_KEY_2"])
if os.environ.get("INFURA_API_KEY"):
    URLS.append("https://zksync-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
URLS.append("https://mainnet.era.zksync.io/")
ZERO = "0x" + "00" * 20


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def one_call(url, to, data, timeout=20, tries=4):
    for a in range(tries):
        try:
            req = urllib.request.Request(url, data=json.dumps(
                {"jsonrpc": "2.0", "id": 1, "method": "eth_call", "params": [{"to": to, "data": data}, "latest"]}).encode(),
                headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                j = json.loads(r.read())
            if "result" in j:
                return j["result"], None
            return None, str(j.get("error"))[:80]
        except Exception as e:
            err = str(e)[:60]
            time.sleep(0.5 * (a + 1))
    return None, err


def inflow_accounts(market, topn):
    T_MINT = "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f"
    T_XFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    best = {}
    for fp in glob.glob(os.path.join(HERE, f"era-positions-rpclogs-{market}*.jsonl")):
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            ev = json.loads(line)
            t0 = ev["t"][0]
            d = (ev["d"] or "")[2:]
            try:
                if t0 == T_MINT:
                    w = [d[i:i + 64] for i in range(0, len(d), 64)]
                    if len(w) >= 3:
                        a = "0x" + w[0][-40:]
                        amt = int(w[2], 16)
                        if a != ZERO and amt > best.get(a, 0):
                            best[a] = amt
                elif t0 == T_XFER and len(ev["t"]) >= 3:
                    to = "0x" + ev["t"][2][-40:]
                    amt = int(d[:64], 16) if len(d) >= 64 else 0
                    if to != ZERO and amt > best.get(to, 0):
                        best[to] = amt
            except Exception:
                continue
    # also include tx from-accounts
    for fp in glob.glob(os.path.join(HERE, f"era-positions-txs-{market}*.jsonl")):
        for line in open(fp):
            x = json.loads(line)
            frm = (x.get("from") or "").lower()
            if frm and frm not in best:
                best[frm] = 0
    ranked = sorted(best.items(), key=lambda kv: -kv[1])[:topn]
    return [a for a, _ in ranked]


def main():
    market = sys.argv[1]
    topn = int(sys.argv[2]) if len(sys.argv) > 2 else 900
    workers = int(sys.argv[3]) if len(sys.argv) > 3 else 16
    addr = MARKETS[market]
    accounts = inflow_accounts(market, topn)
    print(f"{market}: {len(accounts)} accounts to check", flush=True)
    out_path = os.path.join(HERE, f"era-positions-debtscan-{market}.json")
    prog = json.load(open(out_path)) if os.path.exists(out_path) else {}
    todo = [a for a in accounts if a not in prog]
    print(f"todo {len(todo)}", flush=True)

    def work(a):
        i = work.counter
        work.counter += 1
        raw, err = one_call(URLS[i % len(URLS)], addr, "0x95dd9193" + pad(a))
        return a, raw, err

    work.counter = 0
    t0 = time.time()
    done = 0
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(work, a) for a in todo]
        for f in as_completed(futs):
            a, raw, err = f.result()
            prog[a] = int(raw, 16) if (raw and raw != "0x") else ({"err": err} if raw is None else 0)
            done += 1
            if done % 200 == 0:
                json.dump(prog, open(out_path, "w"))
                print(f"  {done}/{len(todo)} ({done/(time.time()-t0):.1f} calls/s)", flush=True)
    json.dump(prog, open(out_path, "w"))
    pos = {a: v for a, v in prog.items() if isinstance(v, int) and v > 0}
    print(f"{market}: {len(pos)} with debt>0 of {len(prog)}; top:", flush=True)
    for a, v in sorted(pos.items(), key=lambda kv: -kv[1])[:20]:
        print(f"  {v} {a}", flush=True)


if __name__ == "__main__":
    main()
