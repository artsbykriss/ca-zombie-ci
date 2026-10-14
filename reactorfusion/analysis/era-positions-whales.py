#!/usr/bin/env python3
"""Whale sweep: rank accounts by largest single inflow per market (from event logs),
then read full state (6 snapshots + liquidity) for the top accounts.

Reads are authoritative (on-chain), so this finds current large holders regardless
of scan completeness. Output: era-positions-whales.json.
"""
import glob, json, os, sys, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
C = "0x23848c28Af1C3AA7B999fA57e6b6E8599C17F3f2"
MARKETS = {
    "rfUSDCe": "0x04e9db37d8ea0760072e1ace3f2a219988fdac29",
    "rfETH":   "0xc5db68f30d21cbe0c9eac7be5ea83468d69297e6",
    "rfWBTC":  "0x0a976e1e7d3052beb46085acbe1e0daccf4a19cf",
    "rfUSDT":  "0x894cccb9908a0319381c305f947ad0ef44838591",
    "rfZK":    "0x0e392b6b05c112677096920ad938a0752d1451f3",
    "rfUSDC":  "0x930da5e58f7f0d6dc417ab07e07558c78cff1445",
}
RPC_URLS = []
if os.environ.get("ALCHEMY_API_KEY_2"):
    RPC_URLS.append("https://zksync-mainnet.g.alchemy.com/v2/" + os.environ["ALCHEMY_API_KEY_2"])
if os.environ.get("INFURA_API_KEY"):
    RPC_URLS.append("https://zksync-mainnet.infura.io/v3/" + os.environ["INFURA_API_KEY"])
RPC_URLS.append("https://mainnet.era.zksync.io/")
ZERO = "0x" + "00" * 20


def pad(a):
    return a.lower()[2:].rjust(64, "0")


def post(url, payload, timeout=22):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json", "User-Agent": "research-read-only"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())


def batch_calls(items, max_batch=50, tries=5):
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
            size = max(10, size // 2)
            time.sleep(0.6 * attempt)
    return out, errs


def rank_inflows():
    """max single inflow per (market, account) from Mint + Transfer-in events."""
    T_MINT = "0x4c209b5fc8ad50758f13e2e1088ba56a560dff690a1c6fef26394f4c03821c4f"
    T_XFER = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
    best = {}
    for fp in glob.glob(os.path.join(HERE, "era-positions-rpclogs-*.jsonl")):
        base = os.path.basename(fp)
        m = base.replace("era-positions-rpclogs-", "").split("-")[0].replace(".jsonl", "")
        if m not in MARKETS:
            continue
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
                        if a != ZERO and amt > best.get((m, a), 0):
                            best[(m, a)] = amt
                elif t0 == T_XFER and len(ev["t"]) >= 3:
                    to = "0x" + ev["t"][2][-40:]
                    amt = int(d[:64], 16) if len(d) >= 64 else 0
                    if to != ZERO and amt > best.get((m, to), 0):
                        best[(m, to)] = amt
            except Exception:
                continue
    return best


def main():
    topn = 2500
    if "--top" in sys.argv:
        topn = int(sys.argv[sys.argv.index("--top") + 1])
    best = rank_inflows()
    print(f"(market, account) inflow records: {len(best)}", flush=True)
    per_market = {}
    for (m, a), amt in best.items():
        per_market.setdefault(m, []).append((amt, a))
    accounts = set()
    for m, lst in per_market.items():
        lst.sort(reverse=True)
        keep = [a for _, a in lst[:topn]]
        accounts.update(keep)
        print(f"{m}: {len(lst)} accounts with inflow, keeping top {len(keep)}", flush=True)
    accounts = sorted(accounts)
    print(f"total accounts to read: {len(accounts)}", flush=True)

    prog_path = os.path.join(HERE, "era-positions-whales.json")
    prog = json.load(open(prog_path)) if os.path.exists(prog_path) else {}
    prog.setdefault("accounts", {})
    todo = [a for a in accounts if a not in prog["accounts"]]
    print(f"todo {len(todo)}", flush=True)
    t0 = time.time()
    CH = 40
    for i in range(0, len(todo), CH):
        chunk = todo[i:i + CH]
        items = []
        for a in chunk:
            for m, addr in MARKETS.items():
                items.append((addr, "0xc37f68e2" + pad(a)))
            items.append((C, "0x5ec88c79" + pad(a)))
        raws, errs = batch_calls(items)
        k = 0
        for a in chunk:
            snaps = {}
            for m in MARKETS:
                raw, e = raws[k], errs[k]; k += 1
                if raw and raw != "0x":
                    b = raw[2:]
                    try:
                        snaps[m] = [int(b[0:64], 16), int(b[64:128], 16), int(b[128:192], 16), int(b[192:256], 16)]
                    except Exception:
                        snaps[m] = {"err": "decode"}
                else:
                    snaps[m] = {"err": e or "empty"}
            raw, e = raws[k], errs[k]; k += 1
            liq = None
            if raw and raw != "0x":
                b = raw[2:]
                liq = {"err": int(b[0:64], 16), "liquidity": int(b[64:128], 16), "shortfall": int(b[128:192], 16)}
            else:
                liq = {"err_str": e or "empty"}
            prog["accounts"][a] = {"snapshots": snaps, "liquidity": liq}
        json.dump(prog, open(prog_path, "w"))
        el = time.time() - t0
        print(f"progress {len(prog['accounts'])}/{len(accounts)} ({(i+len(chunk))/el:.1f} acct/s)", flush=True)
    print("WHALE SWEEP DONE", flush=True)


if __name__ == "__main__":
    main()
