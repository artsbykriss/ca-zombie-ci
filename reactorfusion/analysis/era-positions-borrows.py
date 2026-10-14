#!/usr/bin/env python3
"""Read borrowBalanceStored for every (account, market) pair that touched the
borrow side of a market (borrow/repay/repayBehalf/liquidate txs) — finds all
accounts with debt. Resume-safe. Writes era-positions-borrows.json.

Usage: python3 era-positions-borrows.py [--all-pairs]
"""
import glob, json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
MADDR2LBL = {v.lower(): k for k, v in MARKETS.items()}
import os as _os
RPC_URLS = []
if _os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + _os.environ["ALCHEMY_API_KEY_2"])
if _os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + _os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")
SEL_BORROW_BAL = "0x95dd9193"
BORROW_SIDE = {"0xc5ebeaec", "0x0e752702", "0x4e4d9fea", "0x2608f818", "0xf5e3c462"}


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def post(url, payload, timeout=22):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch_calls(items, max_batch=100, tries=5):
    out = [None] * len(items); errs = [None] * len(items)
    pending = list(range(len(items)))
    size = max_batch
    attempt = 0
    while pending and attempt < tries:
        attempt += 1
        still = []
        for i in range(0, len(pending), size):
            g = pending[i:i + size]
            payload = [{"jsonrpc": "2.0", "id": x, "method": "eth_call",
                        "params": [{"to": items[x][0], "data": items[x][1]}, "latest"]} for x in g]
            ok = False
            for url in RPC_URLS:
                try:
                    resp = post(url, payload)
                    if isinstance(resp, list):
                        byid = {r.get("id"): r for r in resp}
                        for x in g:
                            r = byid.get(x, {})
                            if "result" in r:
                                out[x] = r["result"]
                            else:
                                errs[x] = str(r.get("error"))[:120]
                        ok = True
                        break
                except Exception as e:
                    errs[g[0]] = f"transport {str(e)[:70]}"
            if not ok:
                still.extend(g)
        pending = still
        if pending:
            size = max(5, size // 2)
            time.sleep(0.6 * attempt)
    return out, errs


def load_pairs():
    pairs = {}
    def touch(m, a, amt=None):
        k = (m, a)
        if k not in pairs:
            pairs[k] = amt or 0
        elif amt and amt > pairs[k]:
            pairs[k] = amt
    for fp in glob.glob(os.path.join(HERE, "era-positions-txs-*.jsonl")):
        base = os.path.basename(fp)
        m = base.replace("era-positions-txs-", "").split("-")[0].replace(".jsonl", "")
        if m not in MARKETS:
            continue
        for line in open(fp):
            line = line.strip()
            if not line:
                continue
            x = json.loads(line)
            mid = (x.get("mid") or "").lower()
            if mid in BORROW_SIDE:
                inp = x.get("in") or ""
                amt = None
                if len(inp) >= 74:
                    try:
                        amt = int(inp[10:74], 16)
                    except Exception:
                        amt = None
                if x.get("from"):
                    touch(m, x["from"], amt)
                if mid in ("0x2608f818", "0xf5e3c462") and len(inp) >= 74:
                    touch(m, "0x" + inp[34:74].lower(), amt)
    # priority: largest borrow amounts first
    return sorted(pairs.keys(), key=lambda k: -pairs[k])


def main():
    part, nparts = 0, 1
    if "--part" in sys.argv:
        i = sys.argv.index("--part")
        part, nparts = int(sys.argv[i + 1]), int(sys.argv[i + 2])
    pairs = load_pairs()
    if nparts > 1:
        pairs = [p for k, p in enumerate(pairs) if k % nparts == part]
    print(f"borrow-side pairs: {len(pairs)} (part {part}/{nparts})", flush=True)
    prog_path = os.path.join(HERE, f"era-positions-borrows-part{part}.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {"block": None, "pairs": {}}
    prog.setdefault("pairs", {})
    # fresh latest block
    block = None
    for attempt in range(8):
        try:
            j = post(RPC_URLS[0], {"jsonrpc": "2.0", "id": 1, "method": "eth_blockNumber", "params": []}, timeout=40)
            block = int(j["result"], 16); break
        except Exception:
            time.sleep(1.5 * (attempt + 1))
    print("block", block, flush=True)
    prog["block"] = block
    todo = [p for p in pairs if f"{p[0]}|{p[1]}" not in prog["pairs"]]
    print(f"todo {len(todo)} (done {len(prog['pairs'])})", flush=True)
    t0 = time.time()
    CH = 120
    for i in range(0, len(todo), CH):
        chunk = todo[i:i + CH]
        items = [(MARKETS[m], SEL_BORROW_BAL + pad(a)) for m, a in chunk]
        raws, errs = batch_calls(items)
        for (m, a), raw, e in zip(chunk, raws, errs):
            key = f"{m}|{a}"
            if raw is None:
                prog["pairs"][key] = {"err": e or "no result"}
            else:
                prog["pairs"][key] = int(raw, 16) if raw != "0x" else 0
        json.dump(prog, open(prog_path, "w"))
        el = time.time() - t0
        print(f"progress {len(prog['pairs'])}/{len(pairs)} ({(i+len(chunk))/el:.1f} pair/s)", flush=True)
    pos = {k: v for k, v in prog["pairs"].items() if isinstance(v, int) and v > 0}
    print(f"pairs with debt>0: {len(pos)}", flush=True)
    for k, v in sorted(pos.items(), key=lambda kv: -kv[1])[:40]:
        print(f"  {k}: {v}")
    print("DONE", flush=True)


if __name__ == "__main__":
    main()
